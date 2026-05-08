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
///   id, pseudo, email, level, total_points, current_streak,
///   completion_rate, deletion_requested_at
class SupabaseAuthDataSource implements AuthDataSource {
  static const _profileColumns =
      'pseudo, email, level, total_points, current_streak, '
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
    // Pseudo auto-généré déterministe (Q-18). Le user le change à SETUP-01.
    final autoPseudo = _autoPseudo(user.id);
    // Création explicite du row `users` — la table est dérivée de auth.users
    // côté admin (cf. murabbi-admin migrations Q-18).
    await _client.from('users').insert({
      'id': user.id,
      'pseudo': autoPseudo,
      'email': email,
      'level': 'aspirant',
      'total_points': 0,
      'current_streak': 0,
      'completion_rate': 0,
    });
    return _toMaps(
      user,
      profileOverride: {
        'pseudo': autoPseudo,
        'email': email,
        'level': 'aspirant',
        'total_points': 0,
        'current_streak': 0,
        'completion_rate': 0,
        'deletion_requested_at': null,
      },
    );
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
        .update({'deletion_requested_at': DateTime.now().toIso8601String()})
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
          .select(_profileColumns)
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
