import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/data/datasources/auth_data_source.dart';
import 'package:murabbi_mobile/data/mappers/user_mapper.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _ds;

  const AuthRepositoryImpl(this._ds);

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    final maps = await _ds.signInWithPassword(email: email, password: password);
    return UserMapper.fromMaps(authUser: maps.authUser, profile: maps.profile);
  });

  @override
  Future<User> signUp({required String email, required String password}) =>
      _guard(() async {
        final maps = await _ds.signUp(email: email, password: password);
        return UserMapper.fromMaps(
          authUser: maps.authUser,
          profile: maps.profile,
        );
      });

  @override
  Future<User> signInWithGoogle() => _guard(() async {
    final maps = await _ds.signInWithGoogle();
    return UserMapper.fromMaps(authUser: maps.authUser, profile: maps.profile);
  });

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _guard(() => _ds.sendPasswordResetEmail(email: email));

  @override
  Future<void> resendVerificationEmail({required String email}) =>
      _guard(() => _ds.resendVerificationEmail(email: email));

  @override
  Future<void> signOut() => _guard(() => _ds.signOut());

  @override
  Future<void> deleteAccount(UserId userId) =>
      _guard(() => _ds.deleteAccount(userId.value));

  @override
  Future<User?> getCurrentUser() => _guard(() async {
    final maps = await _ds.getCurrentUser();
    if (maps == null) return null;
    return UserMapper.fromMaps(authUser: maps.authUser, profile: maps.profile);
  });

  @override
  Future<User?> refreshSession() => _guard(() async {
    final maps = await _ds.refreshSession();
    if (maps == null) return null;
    return UserMapper.fromMaps(authUser: maps.authUser, profile: maps.profile);
  });

  /// Code PostgREST renvoyé par `.single()` quand 0 ligne — survient après
  /// `signUp` tant que le trigger qui crée la ligne `public.users` n'a pas
  /// encore inséré le profil. Erreur transitoire à ignorer silencieusement.
  static const String _pgrstNoRowsCode = 'PGRST116';

  @override
  Stream<User?> get authStateChanges => _ds.authStateChanges
      // Ne masquer QUE le cas transitoire connu (profil pas encore propagé
      // après signup). Toute autre erreur doit remonter à la couche
      // presentation (et être tracée) — sinon on rendrait l'app silencieuse
      // sur des pannes réseau / RLS / auth qui méritent un fallback UI.
      .handleError(
        (Object error, StackTrace stackTrace) {
          appLog.e(
            'authStateChanges stream error',
            error: error,
            stackTrace: stackTrace,
          );
        },
        test: (error) =>
            error is sb.PostgrestException && error.code == _pgrstNoRowsCode,
      )
      .map(
        (maps) => maps == null
            ? null
            : UserMapper.fromMaps(
                authUser: maps.authUser,
                profile: maps.profile,
              ),
      );

  // Traduit les exceptions natives en AuthFailure typées. Ne jamais laisser
  // remonter une exception Supabase brute jusqu'à la couche presentation.
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw _translate(e);
    }
  }

  AuthFailure _translate(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('already registered') || msg.contains('already in use')) {
      return AuthFailure.emailAlreadyInUse(message: error.toString());
    }
    if (msg.contains('password should be at least') ||
        msg.contains('weak password')) {
      return AuthFailure.weakPassword(message: error.toString());
    }
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return AuthFailure.invalidCredentials(message: error.toString());
    }
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('rate_limit') ||
        msg.contains('rate limit')) {
      return AuthFailure.network(message: error.toString());
    }
    return AuthFailure.unknown(message: error.toString());
  }
}
