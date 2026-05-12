import 'dart:async';

import 'package:murabbi_mobile/data/datasources/auth_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

typedef AuthMaps = ({
  Map<String, dynamic> authUser,
  Map<String, dynamic> profile,
});

/// Implémentation Supabase de [AuthDataSource]. Wrapper thin : aucune
/// logique métier, aucune traduction d'erreur — celle-ci est faite dans
/// `AuthRepositoryImpl` (cf. ADR-004).
///
/// Schéma `users` consommé (Q-18, cf. murabbi-admin) :
///   id, pseudo, email, level, current_streak, completion_rate,
///   deletion_requested_at
///
/// Le score cumulé (« total_points ») n'est PAS sur `users` — la SoT est
/// `user_scores.total_score` (table séparée), lue par un futur
/// `UserScoreRepository`. La colonne `deletion_requested_at` est ajoutée
/// par la migration admin RGPD parallèle (ADR-011 — soft-delete 30j).
class SupabaseAuthDataSource implements AuthDataSource {
  /// Liste des colonnes lues sur `public.users` (SELECT). Source de vérité
  /// figée par `supabase_auth_data_source_test.dart` (contract test
  /// anti-drift PR #29). Toute modif ici doit être accompagnée de :
  ///   1. la migration SQL correspondante côté murabbi-admin,
  ///   2. la mise à jour du contract test.
  ///
  /// `id` est volontairement absent — il vient déjà de `authUser.id`.
  /// `total_points` est volontairement absent — SoT = `user_scores.total_score`.
  static const String profileColumns =
      'pseudo, email, level, current_streak, '
      'completion_rate, deletion_requested_at';

  final sb.SupabaseClient _client;

  const SupabaseAuthDataSource(this._client);

  @override
  Future<AuthMaps> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _toMaps(res.user!);
  }

  @override
  Future<AuthMaps> signUp({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final user = res.user!;
    // Création explicite du row `users` — la table est dérivée de auth.users
    // côté admin (cf. murabbi-admin migrations Q-18). Payload extrait en
    // pure function pour être contract-testé (PR #29 regression guard).
    //
    // ⚠️ TODO admin-coord (slice 3.C.3 debug) : cet INSERT explicite n'est
    // viable qu'en local Supabase où email_confirm=OFF (signUp renvoie une
    // session, auth.uid() est défini). En cloud (email_confirm=ON), signUp
    // ne crée pas de session → l'INSERT tombe sur RLS "users_insert_own".
    // Le fix canonique est un trigger `on_auth_user_created` côté admin
    // avec SECURITY DEFINER ; une fois déployé (migration
    // 20260512000000_users_handle_new_user_trigger.sql), ces deux lignes
    // doivent disparaître et `_toMaps` lit la row créée par le trigger.
    final payload = buildSignUpInsertPayload(userId: user.id, email: email);
    await _client.from('users').insert(payload);
    return _toMaps(
      user,
      profileOverride: {
        'pseudo': payload['pseudo'],
        'email': payload['email'],
        'level': payload['level'],
        'current_streak': payload['current_streak'],
        'completion_rate': payload['completion_rate'],
        'deletion_requested_at': null,
      },
    );
  }

  /// Construit le payload INSERT pour `public.users` à l'inscription.
  /// Pure function — testable sans mock Supabase. Contrat figé par
  /// `supabase_auth_data_source_test.dart` (anti-drift colonnes).
  ///
  /// Volontairement absents :
  ///   - `total_points` (SoT = `user_scores.total_score`),
  ///   - `deletion_requested_at` (NULL par défaut côté SQL).
  static Map<String, dynamic> buildSignUpInsertPayload({
    required String userId,
    required String email,
  }) {
    return {
      'id': userId,
      'pseudo': _autoPseudo(userId),
      'email': email,
      'level': 'aspirant',
      'current_streak': 0,
      'completion_rate': 0,
    };
  }

  /// Construit le payload UPDATE pour le soft-delete (ADR-011).
  /// Touche uniquement `deletion_requested_at`. Pure function — testable
  /// sans mock Supabase.
  static Map<String, dynamic> buildDeleteAccountUpdatePayload() {
    return {'deletion_requested_at': DateTime.now().toIso8601String()};
  }

  @override
  Future<AuthMaps> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(sb.OAuthProvider.google);
    // Attend la première AuthState authentifiée. Le redirect deep-link
    // (Phase 2 slice D) déclenche signedIn dans le stream.
    final state = await _client.auth.onAuthStateChange.firstWhere(
      (s) => s.event == sb.AuthChangeEvent.signedIn && s.session?.user != null,
    );
    return _toMaps(state.session!.user);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _client.auth.resetPasswordForEmail(email);

  @override
  Future<void> resendVerificationEmail({required String email}) =>
      _client.auth.resend(type: sb.OtpType.signup, email: email);

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> deleteAccount(String userId) async {
    // Soft-delete (ADR-011) : flag deletion_requested_at + signOut. Le
    // hard-delete cascade RGPD est exécuté par un job batch admin (J+30).
    await _client
        .from('users')
        .update(buildDeleteAccountUpdatePayload())
        .eq('id', userId);
    await _client.auth.signOut();
  }

  @override
  Future<AuthMaps?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _toMaps(user);
  }

  @override
  Future<AuthMaps?> refreshSession() async {
    final res = await _client.auth.refreshSession();
    final user = res.user ?? _client.auth.currentUser;
    if (user == null) return null;
    return _toMaps(user);
  }

  @override
  Stream<AuthMaps?> get authStateChanges =>
      _client.auth.onAuthStateChange.asyncMap<AuthMaps?>((state) async {
        final user = state.session?.user;
        if (user == null) return null;
        return _toMaps(user);
      });

  Future<AuthMaps> _toMaps(
    sb.User user, {
    Map<String, dynamic>? profileOverride,
  }) async {
    final Map<String, dynamic> profile;
    if (profileOverride != null) {
      profile = profileOverride;
    } else {
      final row = await _client
          .from('users')
          .select(profileColumns)
          .eq('id', user.id)
          .single();
      profile = Map<String, dynamic>.from(row);
    }
    return (
      authUser: {
        'id': user.id,
        'email': user.email,
        'created_at': user.createdAt,
        'email_confirmed_at': user.emailConfirmedAt,
      },
      profile: profile,
    );
  }

  /// `'Anonyme #' + 4 derniers chars de l'id`. Déterministe, garantit unicité
  /// "raisonnable" tant que l'utilisateur n'a pas encore choisi son pseudo.
  static String _autoPseudo(String userId) {
    final tail = userId.length >= 4
        ? userId.substring(userId.length - 4)
        : userId;
    return 'Anonyme #$tail';
  }
}
