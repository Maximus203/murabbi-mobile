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
class SupabaseAuthDataSource implements AuthDataSource {
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
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    final user = res.user!;
    // Création explicite du row profile — la table `profiles` est dérivée
    // de auth.users côté admin (cf. murabbi-admin migrations).
    await _client.from('profiles').insert({
      'id': user.id,
      'display_name': displayName,
      'total_points': 0,
    });
    return _toMaps(user, displayNameOverride: displayName, totalPoints: 0);
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
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> deleteAccount(String userId) async {
    // Le SDK client ne fournit pas auth.admin.deleteUser. On délègue à un
    // RPC Supabase `delete_account` (cf. issue #7 Phase 6 — cascade RGPD).
    await _client.rpc<void>('delete_account', params: {'user_id': userId});
  }

  @override
  Future<AuthMaps?> getCurrentUser() async {
    final user = _client.auth.currentUser;
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
    String? displayNameOverride,
    int? totalPoints,
  }) async {
    Map<String, dynamic> profile;
    if (displayNameOverride != null && totalPoints != null) {
      profile = {
        'display_name': displayNameOverride,
        'total_points': totalPoints,
      };
    } else {
      final row = await _client
          .from('profiles')
          .select('display_name, total_points')
          .eq('id', user.id)
          .single();
      profile = Map<String, dynamic>.from(row);
    }
    return (
      authUser: {
        'id': user.id,
        'email': user.email,
        'created_at': user.createdAt,
      },
      profile: profile,
    );
  }
}
