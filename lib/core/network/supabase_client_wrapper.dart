import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Source d'information sur l'expiration de la session courante.
///
/// Découplé de `supabase_flutter` pour rester testable sans démarrer un
/// `SupabaseClient` réel. L'implémentation prod lit
/// `Supabase.instance.client.auth.currentSession?.expiresAt`.
abstract class SessionTokenSource {
  /// Date d'expiration UTC du JWT courant, ou `null` si aucune session.
  DateTime? get expiresAt;
}

/// Action de rafraîchissement du JWT (`auth.refreshSession()` côté Supabase).
abstract class SessionRefresher {
  /// Tente de rafraîchir la session. Lève une exception en cas d'échec :
  /// - `SocketException` → réseau indisponible (ne pas signOut).
  /// - `AuthException` / `AuthFailure` → refresh token invalide / révoqué
  ///   → l'utilisateur doit se reconnecter.
  Future<void> refresh();
}

/// Émetteur du signal SignedOut consommé par `AuthNotifier` (qui écoute
/// `authStateChanges`). En prod : `client.auth.signOut()`.
abstract class SignedOutSink {
  Future<void> signOut();
}

/// Wrapper transverse appliqué AVANT chaque appel Supabase pour garantir la
/// fraîcheur du JWT (BUG-001, cf. issue #181).
///
/// Règles métier :
/// - Si l'expiration courante est `<= now + refreshBuffer` (5 min par défaut)
///   ⇒ tente un refresh.
/// - Si le token est frais ⇒ no-op (pas d'appel réseau inutile).
/// - Si aucune session active (`expiresAt == null`) ⇒ no-op (l'appelant
///   recevra de toute façon une erreur "not authenticated" en aval).
/// - Si plusieurs callers déclenchent simultanément un refresh ⇒ une seule
///   requête réseau effective, tous attendent le même `Future` (dedup).
/// - Si le refresh échoue sur `SocketException` ⇒ relance `AuthFailure.network`
///   pour laisser l'offline queue (futur) ré-essayer ; la session est
///   conservée localement.
/// - Si le refresh échoue pour toute autre raison (refresh_token expiré,
///   compte révoqué, …) ⇒ appelle `signOutSink.signOut()` puis relance
///   l'exception. `AuthNotifier.authStateChanges` propagera SignedOut et
///   go_router redirigera vers `/login`.
class SupabaseClientWrapper {
  final SessionTokenSource _tokens;
  final SessionRefresher _refresher;
  final SignedOutSink _signOutSink;
  final DateTime Function() _now;
  final Duration _refreshBuffer;

  /// Future en cours pour dédupliquer les refresh concurrents. `null` quand
  /// aucun refresh n'est en vol.
  Future<void>? _inFlight;

  SupabaseClientWrapper({
    required SessionTokenSource tokens,
    required SessionRefresher refresher,
    required SignedOutSink signOutSink,
    DateTime Function()? now,
    Duration refreshBuffer = const Duration(minutes: 5),
  }) : _tokens = tokens,
       _refresher = refresher,
       _signOutSink = signOutSink,
       _now = now ?? DateTime.now,
       _refreshBuffer = refreshBuffer;

  /// `true` si le JWT expire dans la fenêtre de buffer (inclusive) ou est
  /// déjà expiré. `false` si `expiresAt` est `null` (pas de session).
  bool isExpiringSoon(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    final threshold = _now().add(_refreshBuffer);
    return !expiresAt.isAfter(threshold);
  }

  /// Garantit que le JWT est utilisable pour les ~5 prochaines minutes.
  /// À appeler avant toute requête Supabase autorisée.
  Future<void> ensureFreshSession() {
    if (!isExpiringSoon(_tokens.expiresAt)) {
      return Future.value();
    }
    // Dedup : un refresh déjà en vol → on s'y greffe.
    final pending = _inFlight;
    if (pending != null) return pending;

    final future = _doRefresh();
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<void> _doRefresh() async {
    try {
      await _refresher.refresh();
    } on SocketException catch (e, st) {
      // Offline : on conserve la session, on remonte une erreur typée.
      appLog.w('JWT refresh offline (will retry)', error: e, stackTrace: st);
      throw const AuthFailure.network(message: 'refresh_offline');
    } catch (e, st) {
      // Toute autre erreur ⇒ session invalide → SignedOut.
      appLog.e(
        'JWT refresh failed — forcing signOut',
        error: e,
        stackTrace: st,
      );
      try {
        await _signOutSink.signOut();
      } catch (signOutErr, signOutSt) {
        // Le signOut local ne doit pas masquer l'erreur originale.
        appLog.w(
          'signOut after failed refresh also threw (ignored)',
          error: signOutErr,
          stackTrace: signOutSt,
        );
      }
      rethrow;
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Adaptateurs Supabase prod — implémentent les abstractions ci-dessus en
// déléguant au `SupabaseClient` réel. Restent dans la couche `data/` au
// sens architectural (ils dépendent du SDK Supabase) mais sont co-localisés
// avec le wrapper pour faciliter la lecture du flux.
// ────────────────────────────────────────────────────────────────────────────

class _SupabaseSessionTokenSource implements SessionTokenSource {
  final sb.SupabaseClient _client;
  _SupabaseSessionTokenSource(this._client);

  @override
  DateTime? get expiresAt {
    final exp = _client.auth.currentSession?.expiresAt;
    if (exp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  }
}

class _SupabaseSessionRefresher implements SessionRefresher {
  final sb.SupabaseClient _client;
  _SupabaseSessionRefresher(this._client);

  @override
  Future<void> refresh() async {
    await _client.auth.refreshSession();
  }
}

class _SupabaseSignedOutSink implements SignedOutSink {
  final sb.SupabaseClient _client;
  _SupabaseSignedOutSink(this._client);

  @override
  Future<void> signOut() => _client.auth.signOut();
}

/// Provider du wrapper prêt à l'emploi (singleton scoped). Les datasources
/// l'appelleront via `ref.read(supabaseClientWrapperProvider).ensureFreshSession()`
/// avant chaque requête authentifiée. Adoption incrémentale — pas dans le
/// périmètre de cette PR.
final supabaseClientWrapperProvider = Provider<SupabaseClientWrapper>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseClientWrapper(
    tokens: _SupabaseSessionTokenSource(client),
    refresher: _SupabaseSessionRefresher(client),
    signOutSink: _SupabaseSignedOutSink(client),
  );
});
