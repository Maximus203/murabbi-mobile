import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/validate_auth_form_use_case.dart';

void main() {
  const validator = AuthFormValidator();

  group('validateEmail', () {
    test('renvoie une erreur si vide', () {
      expect(AuthFormValidator.validateEmail(''), "L'email est requis");
      expect(AuthFormValidator.validateEmail('   '), "L'email est requis");
    });

    test('renvoie une erreur si format invalide', () {
      expect(
        AuthFormValidator.validateEmail('notanemail'),
        "Format d'email invalide",
      );
      expect(
        AuthFormValidator.validateEmail('foo@bar'),
        "Format d'email invalide",
      );
    });

    test('renvoie null si email valide', () {
      expect(AuthFormValidator.validateEmail('user@example.com'), isNull);
      expect(AuthFormValidator.validateEmail('  user@example.com '), isNull);
    });
  });

  group('validateLoginPassword', () {
    test('renvoie une erreur si vide', () {
      expect(
        AuthFormValidator.validateLoginPassword(''),
        'Le mot de passe est requis',
      );
    });

    test('renvoie null si non vide (pas de règle de longueur au login)', () {
      expect(AuthFormValidator.validateLoginPassword('short'), isNull);
    });
  });

  group('validateSignupPassword', () {
    test('renvoie une erreur si vide', () {
      expect(
        AuthFormValidator.validateSignupPassword(''),
        'Le mot de passe est requis',
      );
    });

    test('renvoie une erreur si trop court', () {
      expect(
        AuthFormValidator.validateSignupPassword('short'),
        '8 caractères minimum',
      );
    });

    test('renvoie null si >= 8 caractères', () {
      expect(AuthFormValidator.validateSignupPassword('pass1234'), isNull);
    });
  });

  group('validateDisplayName', () {
    test('renvoie une erreur si vide', () {
      expect(AuthFormValidator.validateDisplayName(''), 'Le nom est requis');
      expect(AuthFormValidator.validateDisplayName('   '), 'Le nom est requis');
    });

    test('renvoie une erreur si trop long', () {
      expect(
        AuthFormValidator.validateDisplayName('a' * 31),
        '30 caractères maximum',
      );
    });

    test('renvoie null si nom valide', () {
      expect(AuthFormValidator.validateDisplayName('Aïcha'), isNull);
    });
  });

  group('validateLogin', () {
    test('formulaire vide → hasErrors, deux champs en erreur', () {
      final errors = validator.validateLogin(email: '', password: '');
      expect(errors.hasErrors, isTrue);
      expect(errors.email, "L'email est requis");
      expect(errors.password, 'Le mot de passe est requis');
    });

    test('email invalide → erreur email seule', () {
      final errors = validator.validateLogin(
        email: 'notanemail',
        password: 'whatever',
      );
      expect(errors.hasErrors, isTrue);
      expect(errors.email, "Format d'email invalide");
      expect(errors.password, isNull);
    });

    test('formulaire valide → pas d\'erreur', () {
      final errors = validator.validateLogin(
        email: 'user@example.com',
        password: 'pass1234',
      );
      expect(errors.hasErrors, isFalse);
    });
  });

  group('validateSignup', () {
    test('formulaire vide → trois champs en erreur', () {
      final errors = validator.validateSignup(
        displayName: '',
        email: '',
        password: '',
      );
      expect(errors.hasErrors, isTrue);
      expect(errors.displayName, 'Le nom est requis');
      expect(errors.email, "L'email est requis");
      expect(errors.password, 'Le mot de passe est requis');
    });

    test('mot de passe trop court → erreur longueur', () {
      final errors = validator.validateSignup(
        displayName: 'Yusuf',
        email: 'user@example.com',
        password: 'short',
      );
      expect(errors.password, '8 caractères minimum');
    });

    test('formulaire valide → pas d\'erreur', () {
      final errors = validator.validateSignup(
        displayName: 'Yusuf',
        email: 'user@example.com',
        password: 'pass1234',
      );
      expect(errors.hasErrors, isFalse);
    });
  });

  group('validateForgotPassword', () {
    test('email vide → erreur', () {
      final errors = validator.validateForgotPassword(email: '');
      expect(errors.hasErrors, isTrue);
      expect(errors.email, "L'email est requis");
    });

    test('email valide → pas d\'erreur', () {
      final errors = validator.validateForgotPassword(
        email: 'user@example.com',
      );
      expect(errors.hasErrors, isFalse);
    });
  });
}
