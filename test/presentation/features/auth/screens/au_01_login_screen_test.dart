import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_01_login_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';
import 'package:murabbi_mobile/presentation/widgets/app_logo.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  final testUser = User(
    id: UserId('uuid-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime(2026),
    level: Level.aspirant,
  );

  setUp(() {
    repo = MockAuthRepository();
    when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => repo.getCurrentUser()).thenAnswer((_) async => null);
  });

  Widget makeApp({
    VoidCallback? onForgot,
    VoidCallback? onSignUp,
    VoidCallback? onAuth,
  }) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Au01LoginScreen(
          onForgotPassword: onForgot ?? () {},
          onSignUp: onSignUp ?? () {},
          onAuthenticated: onAuth ?? () {},
        ),
      ),
    );
  }

  testWidgets('renders email + password fields, submit + Google + links', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
    // AppInput uppercases its label (cf. Phase 1 DS).
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('MOT DE PASSE'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });

  testWidgets('tapping "Se connecter" calls repo.signIn with field values', (
    tester,
  ) async {
    when(
      () => repo.signIn(email: 'cherif@example.com', password: 'pass1234'),
    ).thenAnswer((_) async => testUser);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '').first,
      'cherif@example.com',
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.last, 'pass1234');
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    await tester.pumpAndSettle();

    verify(
      () => repo.signIn(email: 'cherif@example.com', password: 'pass1234'),
    ).called(1);
  });

  testWidgets('displays FR error message on InvalidCredentialsFailure', (
    tester,
  ) async {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthFailure.invalidCredentials());

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'bad@b.co');
    await tester.enterText(fields.last, 'wrongpass');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
  });

  testWidgets('displays FR error on AccountDeletedFailure (ADR-011)', (
    tester,
  ) async {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthFailure.accountDeleted());

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'a@b.co');
    await tester.enterText(fields.last, 'pass1234');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ce compte a été supprimé. Contacte le support pour le restaurer.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('triggers onAuthenticated callback when sign-in succeeds', (
    tester,
  ) async {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => testUser);

    var authCalled = 0;
    await tester.pumpWidget(makeApp(onAuth: () => authCalled++));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'cherif@example.com');
    await tester.enterText(fields.last, 'pass1234');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(authCalled, 1);
  });

  testWidgets('"Continuer avec Google" calls repo.signInWithGoogle', (
    tester,
  ) async {
    when(() => repo.signInWithGoogle()).thenAnswer((_) async => testUser);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuer avec Google'));
    await tester.pumpAndSettle();

    verify(() => repo.signInWithGoogle()).called(1);
  });

  testWidgets('AU-01 affiche le Logo Wordmark', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.byType(AppWordmark), findsOneWidget);
  });

  testWidgets('forgot/signup links call their callbacks', (tester) async {
    var forgotCalled = 0;
    var signUpCalled = 0;
    await tester.pumpWidget(
      makeApp(onForgot: () => forgotCalled++, onSignUp: () => signUpCalled++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pump();
    expect(forgotCalled, 1);

    // Le bouton peut être hors écran (le logo wordmark ajoute de la hauteur).
    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un compte'));
    await tester.pump();
    expect(signUpCalled, 1);
  });
}
