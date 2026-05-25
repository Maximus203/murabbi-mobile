import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/router/auth_redirect.dart';
import '../../helpers/test_uuids.dart';

/// Régression #134 / #138 — un deep-link vers une route du shell d'onglets
/// (`/habits`, `/habits/create`) ne doit PAS rediriger un utilisateur
/// authentifié vers `/home`. La destination demandée est préservée.
void main() {
  final user = User(
    id: UserId(kUserIdAlpha),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('c@b.co'),
    createdAt: DateTime(2026),
    level: Level.aspirant,
  );

  group('authRedirect — deep-link shell routes (issues #134 / #138)', () {
    test('#134 — /habits authentifié+onboarded → pas de redirect', () {
      final r = authRedirect(
        auth: AsyncValue.data(user),
        onboarded: const AsyncValue.data(true),
        currentPath: '/habits',
      );
      expect(r, isNull);
    });

    test('#138 — /habits/create authentifié+onboarded → pas de redirect', () {
      final r = authRedirect(
        auth: AsyncValue.data(user),
        onboarded: const AsyncValue.data(true),
        currentPath: '/habits/create',
      );
      expect(r, isNull);
    });

    test(
      '#134 — /habits authentifié sans flag onboarding → pas de redirect',
      () {
        // Q3-A : pas de second flag d'onboarding post-auth ; une session
        // active suffit à autoriser toute route du shell.
        final r = authRedirect(
          auth: AsyncValue.data(user),
          onboarded: const AsyncValue.data(false),
          currentPath: '/habits',
        );
        expect(r, isNull);
      },
    );

    test('/habits non-authentifié → /auth/login (garde inchangée)', () {
      final r = authRedirect(
        auth: const AsyncValue<User?>.loading(),
        onboarded: const AsyncValue.data(true),
        currentPath: '/habits',
      );
      // loading → splash, jamais /home : la destination n'est pas écrasée
      // par une route arbitraire.
      expect(r, '/splash');
    });
  });
}
