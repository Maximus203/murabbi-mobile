// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/delete_account_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/settings/providers/delete_account_notifier.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_01_settings_screen.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_02_edit_profile_screen.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_03_delete_account_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeDeleteAccountUseCase implements DeleteAccountUseCase {
  bool called = false;
  @override
  Future<void> call(UserId userId) async {
    called = true;
  }
}

final _user = User(
  id: UserId('user-1'),
  pseudo: Pseudonym('Cherif'),
  email: NonEmptyString('cherif@example.com'),
  createdAt: DateTime(2026, 1, 1),
  level: Level.murid,
  pseudoFull: 'Cherif#4231',
);

void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
    when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => repo.getCurrentUser()).thenAnswer((_) async => _user);
  });

  Widget wrap(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo), ...overrides],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
  }

  // ---------------------------------------------------------------------------
  // ST-01 — Paramètres
  // ---------------------------------------------------------------------------
  group('ST-01 settings screen', () {
    Widget buildScreen({
      VoidCallback? onEditProfile,
      VoidCallback? onDeleteAccount,
      VoidCallback? onSignOut,
      VoidCallback? onOpenPrayerSettings,
    }) {
      return wrap(
        St01SettingsScreen(
          onBack: () {},
          onEditProfile: onEditProfile ?? () {},
          onOpenPrayerSettings: onOpenPrayerSettings ?? () {},
          onDeleteAccount: onDeleteAccount ?? () {},
          onSignOut: onSignOut ?? () {},
        ),
      );
    }

    testWidgets('renders screen title and profile card', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Titre de la page
      expect(find.text('Paramètres'), findsOneWidget);
      // Nom d'affichage
      expect(find.text('Cherif#4231'), findsOneWidget);
      // Email
      expect(find.text('cherif@example.com'), findsOneWidget);
      // Badge niveau (Murīd = level 2)
      expect(find.textContaining('Murīd'), findsOneWidget);
    });

    testWidgets('profile card is tappable and triggers onEditProfile', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(buildScreen(onEditProfile: () => called = true));
      await tester.pumpAndSettle();

      // La carte profil est tappable
      await tester.tap(find.text('Cherif#4231'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('COMPTE section contains Modifier le profil, Notifications, Apparence', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('COMPTE'), findsOneWidget);
      expect(find.text('Modifier le profil'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Apparence'), findsOneWidget);
    });

    testWidgets('PRATIQUE section has 4 items including Horaires de prière', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('PRATIQUE'), findsOneWidget);
      expect(find.text('Horaires de prière'), findsOneWidget);
      expect(find.text('Objectif quotidien'), findsOneWidget);
      expect(find.text('Démarrage de semaine'), findsOneWidget);
      expect(find.text('Langue'), findsOneWidget);
    });

    testWidgets('CONFIDENTIALITÉ section contains Politique de confidentialité', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Scroller pour atteindre les sections du bas du ListView
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('CONFIDENTIALITÉ'), findsOneWidget);
      expect(find.text('Politique de confidentialité'), findsOneWidget);
    });

    testWidgets('tapping Modifier le profil triggers onEditProfile', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(buildScreen(onEditProfile: () => called = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier le profil'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('tapping Horaires de prière triggers onOpenPrayerSettings', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildScreen(onOpenPrayerSettings: () => called = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Horaires de prière'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('tapping Supprimer le compte triggers onDeleteAccount', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        buildScreen(onDeleteAccount: () => tapped = true),
      );
      await tester.pumpAndSettle();

      // Scroller pour rendre visible les actions destructives en bas
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Supprimer le compte'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ST-02 — Mon profil (Q-26 en attente : Nom complet = read-only jusqu'à
  // migration `display_name` ; Pseudonyme = read-only per issue #168)
  // ---------------------------------------------------------------------------
  group('ST-02 profile screen', () {
    testWidgets('shows avatar with user initial', (tester) async {
      await tester.pumpWidget(
        wrap(St02EditProfileScreen(onBack: () {}, onSaved: () {})),
      );
      await tester.pumpAndSettle();

      // L'initial du pseudo est "C" (Cherif)
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('shows "Mon profil" title', (tester) async {
      await tester.pumpWidget(
        wrap(St02EditProfileScreen(onBack: () {}, onSaved: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mon profil'), findsOneWidget);
    });

    testWidgets('shows email field (read-only)', (tester) async {
      await tester.pumpWidget(
        wrap(St02EditProfileScreen(onBack: () {}, onSaved: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('cherif@example.com'), findsOneWidget);
    });

    testWidgets('shows Nom complet section label', (tester) async {
      await tester.pumpWidget(
        wrap(St02EditProfileScreen(onBack: () {}, onSaved: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nom complet'), findsOneWidget);
    });

    testWidgets('shows Pseudonyme section and note about leaderboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(St02EditProfileScreen(onBack: () {}, onSaved: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pseudonyme (classement)'), findsOneWidget);
      expect(
        find.textContaining('publiquement'),
        findsOneWidget,
      );
    });

    testWidgets('shows Modifier la photo affordance', (tester) async {
      await tester.pumpWidget(
        wrap(St02EditProfileScreen(onBack: () {}, onSaved: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modifier la photo'), findsOneWidget);
    });

    testWidgets('shows Enregistrer button', (tester) async {
      await tester.pumpWidget(
        wrap(St02EditProfileScreen(onBack: () {}, onSaved: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enregistrer'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // ST-03 — Supprimer le compte
  // ---------------------------------------------------------------------------
  group('ST-03 delete account screen', () {
    testWidgets('shows irréversible warning title', (tester) async {
      await tester.pumpWidget(
        wrap(St03DeleteAccountScreen(onBack: () {}, onDeleted: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('irréversible'), findsOneWidget);
    });

    testWidgets('shows DONNÉES SUPPRIMÉES section with correct items', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(St03DeleteAccountScreen(onBack: () {}, onDeleted: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('DONNÉES SUPPRIMÉES'), findsOneWidget);
      expect(
        find.textContaining('Profil'),
        findsOneWidget,
      );
      expect(
        find.textContaining('prières'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Collections'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Score'),
        findsOneWidget,
      );
    });

    testWidgets('delete button is disabled until "DELETE" is typed exactly', (
      tester,
    ) async {
      final useCase = _FakeDeleteAccountUseCase();
      await tester.pumpWidget(
        wrap(
          St03DeleteAccountScreen(onBack: () {}, onDeleted: () {}),
          overrides: [deleteAccountUseCaseProvider.overrideWithValue(useCase)],
        ),
      );
      await tester.pumpAndSettle();

      AppButton deleteBtn() => tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Supprimer définitivement'),
      );

      // Repos : bouton désactivé.
      expect(deleteBtn().onPressed, isNull);

      // Casse incorrecte → toujours désactivé.
      await tester.enterText(find.byType(TextField).first, 'delete');
      await tester.pumpAndSettle();
      expect(deleteBtn().onPressed, isNull);

      // Saisie exacte → activé.
      await tester.enterText(find.byType(TextField).first, 'DELETE');
      await tester.pumpAndSettle();
      expect(deleteBtn().onPressed, isNotNull);
    });

    testWidgets('confirming deletion runs use case and calls onDeleted', (
      tester,
    ) async {
      final useCase = _FakeDeleteAccountUseCase();
      var deleted = false;
      await tester.pumpWidget(
        wrap(
          St03DeleteAccountScreen(
            onBack: () {},
            onDeleted: () => deleted = true,
          ),
          overrides: [deleteAccountUseCaseProvider.overrideWithValue(useCase)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'DELETE');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Supprimer définitivement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer définitivement'));
      await tester.pumpAndSettle();

      expect(useCase.called, isTrue);
      expect(deleted, isTrue);
    });
  });
}
