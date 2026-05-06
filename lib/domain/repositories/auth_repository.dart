import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class AuthRepository {
  Future<User> signIn({required String email, required String password});

  Future<User> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// OAuth Google. L'implémentation Supabase ouvre un navigateur externe puis
  /// retourne l'utilisateur authentifié à la fin du redirect.
  Future<User> signInWithGoogle();

  /// Déclenche l'envoi d'un email de réinitialisation. Le repository ne
  /// distingue pas "email inconnu" pour ne pas exposer la liste des comptes.
  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  Future<void> deleteAccount(UserId userId);

  /// Snapshot synchrone de l'utilisateur courant, ou null si non authentifié.
  /// Utilisé au bootstrap de l'app pour décider du splash → home / login.
  Future<User?> getCurrentUser();

  Stream<User?> get authStateChanges;
}
