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
      'pseudo, pseudo_full, email, level, current_streak, '
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
    required String displayName,
  }) async {
    // #131 : le nom choisi par l'utilisateur est transmis dans les metadata
    // Supabase (`data: {display_name}`). Le trigger SECURITY DEFINER
    // `on_auth_user_created` lit `raw_user_meta_data->>'display_name'` pour
    // renseigner `users.pseudo` — fini le placeholder « Anonyme #xxxx ».
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    final user = res.user!;
    // La création de la ligne `public.users` est désormais autoritairement
    // gérée côté backend par le trigger SECURITY DEFINER
    // `on_auth_user_created` (cf. murabbi-admin migration
    // 20260513000000_users_rls_hardening). Indispensable dès que la
    // confirmation email est activée : à ce moment, `auth.uid()` est null
    // au signUp côté client, donc tout INSERT RLS serait rejeté.
    //
    // On conserve `buildSignUpInsertPayload` comme pure function : ses
    // valeurs miroitent exactement celles du trigger SQL (pseudo, level,
    // streak, completion_rate, email) — ce qui permet de fournir un
    // `profileOverride` cohérent au mapper, et reste anti-drift via le
    // contract test (PR #29).
    final payload = buildSignUpInsertPayload(
      userId: user.id,
      email: email,
      displayName: displayName,
    );
    return _toMaps(
      user,
      profileOverride: {
        'pseudo': payload['pseudo'],
        // `pseudo_full` est null tant que le trigger SECURITY DEFINER admin
        // n'a pas projeté la row complète. La prochaine lecture (auth
        // refresh, getCurrentUser) ramènera la valeur générée par Postgres.
        'pseudo_full': null,
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
  /// [displayName] (#131) : si fourni et non vide, devient le `pseudo`.
  /// Sinon on retombe sur le placeholder auto-généré (`Anonyme #xxxx`) —
  /// rétrocompatibilité OAuth Google où aucun nom n'est saisi.
  ///
  /// Volontairement absents :
  ///   - `total_points` (SoT = `user_scores.total_score`),
  ///   - `deletion_requested_at` (NULL par défaut côté SQL).
  static Map<String, dynamic> buildSignUpInsertPayload({
    required String userId,
    required String email,
    String? displayName,
  }) {
    final trimmedName = displayName?.trim() ?? '';
    return {
      'id': userId,
      'pseudo': trimmedName.isNotEmpty ? trimmedName : _autoPseudo(userId),
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
