import 'package:murabbi_mobile/domain/value_objects/email_address.dart';
import 'package:murabbi_mobile/domain/value_objects/password.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';

/// Résultat de validation d'un champ de formulaire auth.
///
/// `null` côté [AuthFormErrors] = champ valide. Un message FR non-null =
/// erreur inline à afficher sous le champ correspondant.
class AuthFormErrors {
  /// Erreur sur le champ email (`null` si valide).
  final String? email;

  /// Erreur sur le champ mot de passe (`null` si valide).
  final String? password;

  /// Erreur sur le champ nom / pseudo (`null` si valide ou non requis).
  final String? displayName;

  const AuthFormErrors({this.email, this.password, this.displayName});

  /// `true` si au moins un champ porte une erreur — aucun appel réseau
  /// ne doit être déclenché tant que ce getter renvoie `true`.
  bool get hasErrors =>
      email != null || password != null || displayName != null;

  @override
  bool operator ==(Object other) =>
      other is AuthFormErrors &&
      other.email == email &&
      other.password == password &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(email, password, displayName);
}

/// Validation synchrone, pure et testable des formulaires d'authentification
/// (#117). À appeler AVANT tout appel Supabase : un formulaire vide ou un
/// email malformé ne doit jamais générer d'appel réseau.
///
/// Les règles de format délèguent aux value objects domaine
/// ([EmailAddress], [Password], [Pseudonym]) pour rester l'unique source de
/// vérité — la validation UI ne peut pas diverger de la validation métier.
class AuthFormValidator {
  const AuthFormValidator();

  /// Valide un email saisi. Renvoie `null` si valide, sinon un message FR.
  static String? validateEmail(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return "L'email est requis";
    try {
      EmailAddress(value);
      return null;
    } on ArgumentError {
      return "Format d'email invalide";
    }
  }

  /// Valide un mot de passe à la connexion : non vide uniquement.
  /// La règle de longueur ne s'applique qu'à l'inscription
  /// (un compte existant peut avoir un mot de passe legacy plus court).
  static String? validateLoginPassword(String raw) {
    if (raw.isEmpty) return 'Le mot de passe est requis';
    return null;
  }

  /// Valide un mot de passe à l'inscription : non vide + longueur minimale.
  static String? validateSignupPassword(String raw) {
    if (raw.isEmpty) return 'Le mot de passe est requis';
    try {
      Password(raw);
      return null;
    } on ArgumentError {
      return '${Password.minLength} caractères minimum';
    }
  }

  /// Valide le nom affiché à l'inscription (#131) : non vide + format
  /// [Pseudonym] valide (longueur, caractères autorisés).
  static String? validateDisplayName(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Le nom est requis';
    try {
      Pseudonym(value);
      return null;
    } on ArgumentError {
      return '${Pseudonym.maxLength} caractères maximum';
    }
  }

  /// Valide le formulaire de connexion (email + mot de passe).
  AuthFormErrors validateLogin({
    required String email,
    required String password,
  }) {
    return AuthFormErrors(
      email: validateEmail(email),
      password: validateLoginPassword(password),
    );
  }

  /// Valide le formulaire d'inscription (nom + email + mot de passe).
  AuthFormErrors validateSignup({
    required String displayName,
    required String email,
    required String password,
  }) {
    return AuthFormErrors(
      email: validateEmail(email),
      password: validateSignupPassword(password),
      displayName: validateDisplayName(displayName),
    );
  }

  /// Valide le formulaire mot de passe oublié (email seul).
  AuthFormErrors validateForgotPassword({required String email}) {
    return AuthFormErrors(email: validateEmail(email));
  }
}
