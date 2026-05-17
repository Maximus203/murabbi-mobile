import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/delete_account_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/update_profile_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/settings/providers/delete_account_notifier.dart';
import 'package:murabbi_mobile/presentation/features/settings/providers/edit_profile_notifier.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_01_settings_screen.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_02_edit_profile_screen.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_03_delete_account_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeUpdateProfileUseCase implements UpdateProfileUseCase {
  bool called = false;
  @override
  Future<User> call({
    required User currentUser,
    required String newPseudo,
  }) async {
    called = true;
    return currentUser.copyWith(pseudo: Pseudonym(newPseudo.trim()));
  }
}

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

  group('ST-01 settings screen', () {
    testWidgets('renders profile card with pseudo, email and level', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          St01SettingsScreen(
            onBack: () {},
            onEditProfile: () {},
            onDeleteAccount: () {},
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Cherif'), findsOneWidget);
      expect(find.text('cherif@example.com'), findsOneWidget);
      expect(find.textContaining('Murīd'), findsOneWidget);
      expect(find.text('Supprimer le compte'), findsOneWidget);
    });

    testWidgets('tapping "Supprimer le compte" triggers onDeleteAccount', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          St01SettingsScreen(
            onBack: () {},
            onEditProfile: () {},
            onDeleteAccount: () => tapped = true,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Supprimer le compte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer le compte'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('ST-02 edit profile screen', () {
    testWidgets('prefills the pseudo field with the current pseudo', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(St02EditProfileScreen(onBack: () {}, onSaved: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cherif'), findsOneWidget);
      expect(find.text('cherif@example.com'), findsOneWidget);
    });

    testWidgets('saving delegates to the use case and calls onSaved', (
      tester,
    ) async {
      final useCase = _FakeUpdateProfileUseCase();
      var saved = false;
      await tester.pumpWidget(
        wrap(
          St02EditProfileScreen(onBack: () {}, onSaved: () => saved = true),
          overrides: [updateProfileUseCaseProvider.overrideWithValue(useCase)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'NouveauNom');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(useCase.called, isTrue);
      expect(saved, isTrue);
    });
  });

  group('ST-03 delete account screen', () {
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

      // Casse incorrecte → toujours désactivé (sensible à la casse).
      await tester.enterText(find.byType(TextField).first, 'delete');
      await tester.pumpAndSettle();
      expect(deleteBtn().onPressed, isNull);

      // Saisie exacte → activé.
      await tester.enterText(find.byType(TextField).first, 'DELETE');
      await tester.pumpAndSettle();
      expect(deleteBtn().onPressed, isNotNull);
    });

    testWidgets('confirming deletion runs the use case and calls onDeleted', (
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
