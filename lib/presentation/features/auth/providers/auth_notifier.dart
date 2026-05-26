import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/remembered_accounts_notifier.dart';
// Providers de données utilisateur à invalider au signOut (anti-fuite
// inter-sessions — audit sécurité 2026-05-26). Ces providers ne réagissent
// pas automatiquement au changement d'auth et doivent être purgés
// explicitement pour que l'utilisateur B ne voie pas les données de A
// sur un device partagé.
//
// NOTE : dashboardNotifierProvider est volontairement ABSENT de cette liste.
// Il utilise maintenant ref.watch(currentUserProvider) → il se reconstruit
// automatiquement au signOut. L'invalider ici créerait une CircularDependencyError
// (auth → dashboard → currentUser → auth).
import 'package:murabbi_mobile/presentation/features/habits/providers/occurrence_providers.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/today_habit_statuses_notifier.dart';

/// État global d'authentification de l'utilisateur courant.
///
/// `AsyncValue<User?>` :
/// - `data(null)` → non authentifié
/// - `data(User)` → authentifié
/// - `loading()`  → opération en cours (signIn / signUp / etc.)
/// - `error(AuthFailure)` → échec dernier appel (sealed, switch exhaustif UI)
///
/// La méthode `sendPasswordReset` ne touche pas au state principal et renvoie
/// un `bool` (anti-enumeration OWASP, cf. Q-7) — l'UI affiche le succès
/// générique quel que soit le résultat.
class AuthNotifier extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  StreamSubscription<User?>? _sub;

  @override
  Future<User?> build() async {
    final repo = _repo;
    ref.onDispose(() => _sub?.cancel());
    _sub = repo.authStateChanges.listen(
      (user) => state = AsyncValue.data(user),
      onError: (Object e, StackTrace st) {
        // Ne pas écraser une session valide avec une erreur transitoire du
        // stream (ex. DB offline au démarrage — Bug S-3). Si une session est
        // déjà établie, on loggue et on préserve l'état courant.
        if (state.valueOrNull == null) {
          state = AsyncValue.error(e, st);
        } else {
          appLog.w(
            'authStateChanges stream error (session active préservée)',
            error: e,
            stackTrace: st,
          );
        }
      },
    );
    return repo.getCurrentUser();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signIn(email: email, password: password),
    );
    if (state.valueOrNull != null) _rememberEmail(email);
  }

  /// #131 : le nom choisi à l'inscription devient le `pseudo` du profil.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signUp(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
    if (state.valueOrNull != null) _rememberEmail(email);
  }

  /// #116 : réinitialise un éventuel état d'erreur sans toucher à la session.
  ///
  /// Appelé à l'entrée/sortie des écrans Auth (login ↔ signup ↔ forgot) pour
  /// qu'une erreur affichée sur un écran ne « fuite » pas sur le suivant.
  /// No-op si l'état courant n'est pas une erreur — on ne perturbe ni le
  /// loading en cours ni une session authentifiée.
  void clearError() {
    if (state.hasError) {
      state = AsyncValue.data(state.valueOrNull);
    }
  }

  /// Mémorise l'email après un succès — best-effort, ne propage pas
  /// l'erreur si SharedPreferences indisponible (UX-only).
  ///
  /// Fire-and-forget : ne pas attendre la persistance pour laisser
  /// l'auth state propager vers le router. Toute erreur est loggée via
  /// `appLog` (audit TL PR #41 : ne pas swallow muettement —
  /// pattern aligné sur `auth_repository_impl.dart`).
  void _rememberEmail(String email) {
    ref
        .read(rememberedAccountsNotifierProvider.notifier)
        .remember(email)
        .catchError((Object e, StackTrace st) {
          appLog.w(
            'RememberedAccounts.remember failed (non-fatal)',
            error: e,
            stackTrace: st,
          );
        });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signInWithGoogle());
  }

  /// Renvoie `true` si l'envoi a réussi côté Supabase, `false` sinon.
  /// L'UI affiche TOUJOURS le succès générique (Q-7 OWASP anti-enumeration).
  /// Le `bool` est utilisé uniquement pour télémétrie / retry futur.
  Future<bool> sendPasswordReset({required String email}) async {
    try {
      await _repo.sendPasswordResetEmail(email: email);
      return true;
    } on AuthFailure {
      return false;
    }
  }

  /// Renvoie l'email de confirmation d'inscription (Supabase
  /// `auth.resend(type: signup)`). Pattern identique à [sendPasswordReset] :
  /// ne touche pas au state principal, retourne un `bool` (utile pour
  /// distinguer rate-limit / network côté UI si besoin).
  Future<bool> resendVerificationEmail({required String email}) async {
    try {
      await _repo.resendVerificationEmail(email: email);
      return true;
    } on AuthFailure {
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.signOut();
      return null;
    });
    // Purge tous les caches de données utilisateur après déconnexion.
    // Empêche la fuite inter-sessions sur device partagé (audit sécurité
    // 2026-05-26) : l'utilisateur B ne voit pas les données de A.
    _invalidateUserDataProviders();
  }

  /// Purge les providers qui stockent des données propres à une session
  /// utilisateur et ne réagissent pas automatiquement au changement d'auth.
  ///
  /// - [todayHabitStatusesProvider] : Map UI optimiste des statuts du jour
  ///   (Notifier sans `ref.watch(auth)` dans build() → ne se réinitialise
  ///   pas seul au signOut).
  /// - [todayOccurrencesProvider] : feed habitudes du jour (FutureProvider
  ///   sans dépendance auth explicite — utilise la session Supabase active
  ///   sans la surveiller via Riverpod).
  ///
  /// [dashboardNotifierProvider] est intentionnellement absent : il utilise
  /// `ref.watch(currentUserProvider)` (Fix sécurité 2026-05-26) et se
  /// reconstruit automatiquement. L'invalider ici causerait une
  /// CircularDependencyError (auth → dashboard → currentUser → auth).
  void _invalidateUserDataProviders() {
    ref.invalidate(todayHabitStatusesProvider);
    ref.invalidate(todayOccurrencesProvider);
  }

  /// Rafraîchit silencieusement la session Supabase au retour de background
  /// (S-4 — issue #sprint). Ne touche pas à [state] : l'auth stream mettra
  /// à jour l'état si le token a été renouvelé. En cas d'erreur, on loggue
  /// uniquement — l'utilisateur sera redirigé vers le login par le router
  /// si la session a expiré.
  Future<void> refreshSession() async {
    try {
      await _repo.refreshSession();
    } catch (e, st) {
      appLog.w(
        'AuthNotifier.refreshSession failed (silent)',
        error: e,
        stackTrace: st,
      );
    }
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);
