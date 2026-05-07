import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/auth_error_banner.dart';

void main() {
  group('AuthErrorBanner.messageFor — exhaustif AuthFailure → FR', () {
    test('InvalidCredentials', () {
      expect(
        AuthErrorBanner.messageFor(const AuthFailure.invalidCredentials()),
        'Email ou mot de passe incorrect.',
      );
    });

    test('EmailAlreadyInUse', () {
      expect(
        AuthErrorBanner.messageFor(const AuthFailure.emailAlreadyInUse()),
        'Cet email est déjà utilisé.',
      );
    });

    test('WeakPassword', () {
      expect(
        AuthErrorBanner.messageFor(const AuthFailure.weakPassword()),
        'Mot de passe trop faible (8 caractères minimum).',
      );
    });

    test('Network', () {
      expect(
        AuthErrorBanner.messageFor(const AuthFailure.network()),
        'Connexion impossible — vérifie ta connexion.',
      );
    });

    test('AccountDeleted (ADR-011)', () {
      expect(
        AuthErrorBanner.messageFor(const AuthFailure.accountDeleted()),
        'Ce compte a été supprimé. Contacte le support pour le restaurer.',
      );
    });

    test('Unknown', () {
      expect(
        AuthErrorBanner.messageFor(const AuthFailure.unknown()),
        'Erreur inattendue. Réessaie dans un instant.',
      );
    });

    test('non-AuthFailure object → fallback générique', () {
      expect(
        AuthErrorBanner.messageFor(Exception('boom')),
        'Erreur inattendue. Réessaie dans un instant.',
      );
      expect(
        AuthErrorBanner.messageFor(null),
        'Erreur inattendue. Réessaie dans un instant.',
      );
    });
  });

  testWidgets('renders the FR message inside a banner widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthErrorBanner(failure: AuthFailure.invalidCredentials()),
        ),
      ),
    );
    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
  });
}
