import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_02_signup_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  final testUser = User(
    id: UserId('uuid-002'),
    pseudo: Pseudonym('Anonyme #ab12'),
    email: NonEmptyString('new@example.com'),
    createdAt: DateTime(2026, 5, 7),
    level: Level.aspirant,
  );

  setUp(() {
    repo = MockAuthRepository();
    when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => repo.getCurrentUser()).thenAnswer((_) async => null);
  });

  Widget makeApp({VoidCallback? onSignIn, VoidCallback? onSignedUp}) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Au02SignupScreen(
          onSignIn: onSignIn ?? () {},
          onSignedUp: onSignedUp ?? () {},
        ),
      ),
    );
  }

  // Remplit les 3 champs (Nom, Email, Mot de passe) dans l'ordre du Column.
  Future<void> fillForm(
    WidgetTester tester, {
    String name = 'Yusuf',
    String email = 'new@example.com',
    String password = 'pass1234',
  }) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), email);
    await tester.enterText(fields.at(2), password);
  }

  testWidgets('renders name + email + password fields, primary CTA, link', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsOneWidget);
    // #131 : champ Nom requis.
    expect(find.text('NOM'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('MOT DE PASSE'), findsOneWidget);
    // CTA primary distinct from AppHeader title.
    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets(
    'tapping "Créer mon compte" calls repo.signUp with field values',
    (tester) async {
      when(
        () => repo.signUp(
          email: 'new@example.com',
          password: 'pass1234',
          displayName: 'Yusuf',
        ),
      ).thenAnswer((_) async => testUser);

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await fillForm(tester);
      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();

      verify(
        () => repo.signUp(
          email: 'new@example.com',
          password: 'pass1234',
          displayName: 'Yusuf',
        ),
      ).called(1);
    },
  );

  // #117 : un formulaire vide ne déclenche aucun appel réseau.
  testWidgets('empty form shows inline errors and does not call signUp', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom est requis'), findsOneWidget);
    expect(find.text("L'email est requis"), findsOneWidget);
    expect(find.text('Le mot de passe est requis'), findsOneWidget);
    verifyNever(
      () => repo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    );
  });

  // #117 : un email malformé est rejeté côté client, aucun appel réseau.
  testWidgets('invalid email shows inline error and does not call signUp', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await fillForm(tester, email: 'notanemail');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text("Format d'email invalide"), findsOneWidget);
    verifyNever(
      () => repo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    );
  });

  // #117 : un mot de passe trop court est rejeté côté client.
  testWidgets('short password shows inline error and does not call signUp', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await fillForm(tester, password: 'short');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('8 caractères minimum'), findsOneWidget);
    verifyNever(
      () => repo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    );
  });

  testWidgets('displays FR error message on EmailAlreadyInUseFailure', (
    tester,
  ) async {
    when(
      () => repo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenThrow(const AuthFailure.emailAlreadyInUse());

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await fillForm(tester, email: 'taken@example.com');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Cet email est déjà utilisé.'), findsOneWidget);
  });

  testWidgets('displays FR error message on WeakPasswordFailure', (
    tester,
  ) async {
    when(
      () => repo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenThrow(const AuthFailure.weakPassword());

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    // Mot de passe valide côté client (8+ car.) — on teste le rejet serveur.
    await fillForm(tester, password: 'pass1234');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(
      find.text('Mot de passe trop faible (8 caractères minimum).'),
      findsOneWidget,
    );
  });

  testWidgets('triggers onSignedUp callback when signUp succeeds', (
    tester,
  ) async {
    when(
      () => repo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => testUser);

    var called = 0;
    await tester.pumpWidget(makeApp(onSignedUp: () => called++));
    await tester.pumpAndSettle();

    await fillForm(tester);
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(called, 1);
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

  testWidgets('"Se connecter" link calls onSignIn callback', (tester) async {
    var called = 0;
    await tester.pumpWidget(makeApp(onSignIn: () => called++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(called, 1);
  });

  testWidgets('AU-02 affiche un bouton retour (ChevronLeft)', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    // AppHeader.back utilise LucideIcons.chevronLeft
    expect(find.byIcon(lu(LucideIcons.chevronLeft)), findsOneWidget);
  });
}
