import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class AuthRepository {
  Future<User> signIn({required String email, required String password});

  /// Signup email + password + nom choisi par l'utilisateur (#131).
  /// [displayName] est transmis dans les metadata Supabase et devient le
  /// `pseudo` du profil — fini le placeholder « Anonyme #xxxx ».
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

  /// Renvoie l'email de confirmation d'inscription (Supabase
  /// `auth.resend(type: signup)`). Idempotent côté Supabase mais soumis à
  /// rate-limit (≈ 1 envoi / 60s) — l'implémentation traduit la limite en
  /// [AuthFailure.network] pour que l'UI puisse réessayer plus tard.
  Future<void> resendVerificationEmail({required String email});

  Future<void> signOut();

  Future<void> deleteAccount(UserId userId);

  /// Snapshot synchrone de l'utilisateur courant, ou null si non authentifié.
  /// Utilisé au bootstrap de l'app pour décider du splash → home / login.
  Future<User?> getCurrentUser();

  /// Rafraîchit la session Supabase (réémet `access_token` + recharge le
  /// `auth.users` pour refléter une éventuelle confirmation d'email côté
  /// serveur). Renvoie `null` si plus de session active.
  ///
  /// Utilisé par AU-04 pour auto-détecter `email_confirmed_at` sans que
  /// l'utilisateur ait à appuyer sur "J'ai vérifié mon email".
  Future<User?> refreshSession();

  Stream<User?> get authStateChanges;
}
