import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_01_settings_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Issue #168 — ST-01 et ST-02 affichent `displayPseudo` (= `pseudoFull` si
/// disponible, sinon fallback sur `pseudo`). La carte profil de ST-01 n'est
/// plus tappable (plus d'édition) et l'entrée « Modifier le profil » est
/// supprimée des réglages.
void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
    when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
  }

  User userWith({String? pseudoFull}) => User(
    id: UserId('user-1'),
    pseudo: Pseudonym('ibrahim'),
    email: NonEmptyString('ibrahim@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.murid,
    pseudoFull: pseudoFull,
  );

  group('ST-01 — displayPseudo (issue #168)', () {
    testWidgets('renders pseudo_full when available', (tester) async {
      when(
        () => repo.getCurrentUser(),
      ).thenAnswer((_) async => userWith(pseudoFull: 'ibrahim#4231'));
      await tester.pumpWidget(
        wrap(
          St01SettingsScreen(
            onBack: () {},
            onEditProfile: () {},
            onOpenPrayerSettings: () {},
            onDeleteAccount: () {},
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // L'affichage canonique est `pseudo#XXXX`.
      expect(find.text('ibrahim#4231'), findsOneWidget);
    });

    testWidgets('falls back to bare pseudo when pseudo_full is null', (
      tester,
    ) async {
      when(() => repo.getCurrentUser()).thenAnswer((_) async => userWith());
      await tester.pumpWidget(
        wrap(
          St01SettingsScreen(
            onBack: () {},
            onEditProfile: () {},
            onOpenPrayerSettings: () {},
            onDeleteAccount: () {},
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ibrahim'), findsOneWidget);
    });

    testWidgets('does not expose a "Modifier le profil" entry (#168)', (
      tester,
    ) async {
      when(() => repo.getCurrentUser()).thenAnswer((_) async => userWith());
      await tester.pumpWidget(
        wrap(
          St01SettingsScreen(
            onBack: () {},
            onEditProfile: () {},
            onOpenPrayerSettings: () {},
            onDeleteAccount: () {},
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // L'entrée disparaît : le pseudo est désormais immuable côté serveur
      // (admin#125). On ne propose plus aucun chemin d'édition.
      expect(find.text('Modifier le profil'), findsNothing);
    });
  });
}
