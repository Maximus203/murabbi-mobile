import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_03_forgot_password_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
    when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => repo.getCurrentUser()).thenAnswer((_) async => null);
  });

  Widget makeApp({VoidCallback? onBack}) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Au03ForgotPasswordScreen(onBack: onBack ?? () {}),
      ),
    );
  }

  testWidgets('initial state — renders email field + envoyer CTA', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.text('Mot de passe oublié'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('Envoyer le lien'), findsOneWidget);
  });

  testWidgets(
    'tapping "Envoyer le lien" calls repo.sendPasswordResetEmail with trimmed email',
    (tester) async {
      when(
        () => repo.sendPasswordResetEmail(email: 'cherif@example.com'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        '  cherif@example.com  ',
      );
      await tester.tap(find.text('Envoyer le lien'));
      await tester.pumpAndSettle();

      verify(
        () => repo.sendPasswordResetEmail(email: 'cherif@example.com'),
      ).called(1);
    },
  );

  testWidgets('shows generic success state on success (Q-7 OWASP)', (
    tester,
  ) async {
    when(
      () => repo.sendPasswordResetEmail(email: any(named: 'email')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'a@b.co');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Si un compte existe'), findsOneWidget);
    expect(find.text('Retour à la connexion'), findsOneWidget);
  });

  testWidgets(
    'shows the SAME generic success state when repo throws (Q-7 anti-enumeration)',
    (tester) async {
      when(
        () => repo.sendPasswordResetEmail(email: any(named: 'email')),
      ).thenThrow(const AuthFailure.unknown());

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'unknown@b.co');
      await tester.tap(find.text('Envoyer le lien'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Si un compte existe'), findsOneWidget);
      expect(find.text('Retour à la connexion'), findsOneWidget);
    },
  );

  testWidgets('"Retour à la connexion" calls onBack callback', (tester) async {
    when(
      () => repo.sendPasswordResetEmail(email: any(named: 'email')),
    ).thenAnswer((_) async {});

    var called = 0;
    await tester.pumpWidget(makeApp(onBack: () => called++));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'a@b.co');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retour à la connexion'));
    await tester.pump();
    expect(called, 1);
  });

  // #117 : un email vide ne déclenche aucun appel réseau.
  testWidgets('empty email shows inline error and does not call repo', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();

    expect(find.text("L'email est requis"), findsOneWidget);
    verifyNever(() => repo.sendPasswordResetEmail(email: any(named: 'email')));
  });

  // #117 : un email malformé est rejeté côté client.
  testWidgets('invalid email shows inline error and does not call repo', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'notanemail');
    await tester.tap(find.text('Envoyer le lien'));
    await tester.pumpAndSettle();

    expect(find.text("Format d'email invalide"), findsOneWidget);
    verifyNever(() => repo.sendPasswordResetEmail(email: any(named: 'email')));
  });

  // #124 : lien "Se connecter" affiché en bas du formulaire.
  testWidgets('#124 — form shows "Se connecter" back link at the bottom', (
    tester,
  ) async {
    var called = 0;
    await tester.pumpWidget(makeApp(onBack: () => called++));
    await tester.pumpAndSettle();

    expect(find.text('Tu te souviens de ton mot de passe ? '), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);

    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(called, 1);
  });

  testWidgets('back arrow in header calls onBack from initial state', (
    tester,
  ) async {
    var called = 0;
    await tester.pumpWidget(makeApp(onBack: () => called++));
    await tester.pumpAndSettle();

    // AppHeader.back uses an IconButton with chevronLeft.
    await tester.tap(find.byType(IconButton).first);
    await tester.pump();
    expect(called, 1);
  });
}
