import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/router/auth_redirect.dart';

void main() {
  final user = User(
    id: UserId('u-1'),
    pseudo: NonEmptyString('Cherif'),
    email: NonEmptyString('c@b.co'),
    createdAt: DateTime(2026),
    level: Level.aspirant,
  );

  group('authRedirect — loading states', () {
    test('auth loading → /splash from any non-splash route', () {
      final r = authRedirect(
        auth: const AsyncValue<User?>.loading(),
        onboarded: const AsyncValue.data(false),
        currentPath: '/home',
      );
      expect(r, '/splash');
    });

    test('auth loading + already on splash → no redirect', () {
      final r = authRedirect(
        auth: const AsyncValue<User?>.loading(),
        onboarded: const AsyncValue.data(false),
        currentPath: '/splash',
      );
      expect(r, isNull);
    });

    test('onboarding loading → /splash', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue<bool>.loading(),
        currentPath: '/home',
      );
      expect(r, '/splash');
    });
  });

  group('authRedirect — unauthenticated, onboarding pas vu (Q3-A)', () {
    test('non-auth route → /onboarding (pre-auth pedagogique)', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(false),
        currentPath: '/home',
      );
      expect(r, '/onboarding');
    });

    test('/onboarding → no redirect', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(false),
        currentPath: '/onboarding',
      );
      expect(r, isNull);
    });

    test('/auth/login → no redirect (utilisateur peut sauter)', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(false),
        currentPath: '/auth/login',
      );
      expect(r, isNull);
    });

    test('/auth/signup → no redirect', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(false),
        currentPath: '/auth/signup',
      );
      expect(r, isNull);
    });

    test('/splash from data(null) + onboarding pas vu → /onboarding', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(false),
        currentPath: '/splash',
      );
      expect(r, '/onboarding');
    });
  });

  group('authRedirect — unauthenticated, onboarding deja vu', () {
    test('non-auth route → /auth/login', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(true),
        currentPath: '/home',
      );
      expect(r, '/auth/login');
    });

    test('/auth/login → no redirect', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(true),
        currentPath: '/auth/login',
      );
      expect(r, isNull);
    });

    test('/auth/signup → no redirect', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(true),
        currentPath: '/auth/signup',
      );
      expect(r, isNull);
    });

    test('/auth/forgot → no redirect', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(true),
        currentPath: '/auth/forgot',
      );
      expect(r, isNull);
    });

    test('/splash from data(null) + onboarding vu → /auth/login', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(true),
        currentPath: '/splash',
      );
      expect(r, '/auth/login');
    });

    test('/onboarding → reste autorise (utilisateur peut le revoir)', () {
      final r = authRedirect(
        auth: const AsyncValue.data(null),
        onboarded: const AsyncValue.data(true),
        currentPath: '/onboarding',
      );
      expect(r, isNull);
    });
  });

  group('authRedirect — authenticated (Q3-A : pas de second flag)', () {
    test(
      '/auth/verify-email → no redirect (sas transient toujours autorise)',
      () {
        final r = authRedirect(
          auth: AsyncValue.data(user),
          onboarded: const AsyncValue.data(false),
          currentPath: '/auth/verify-email',
        );
        expect(r, isNull);
      },
    );

    test('/auth/login while authed → /home (peu importe onboarded)', () {
      final r = authRedirect(
        auth: AsyncValue.data(user),
        onboarded: const AsyncValue.data(false),
        currentPath: '/auth/login',
      );
      expect(r, '/home');
    });
  });

  group('authRedirect — authenticated + onboarded', () {
    test('/home → no redirect', () {
      final r = authRedirect(
        auth: AsyncValue.data(user),
        onboarded: const AsyncValue.data(true),
        currentPath: '/home',
      );
      expect(r, isNull);
    });

    test('/auth/login while authed+onboarded → /home', () {
      final r = authRedirect(
        auth: AsyncValue.data(user),
        onboarded: const AsyncValue.data(true),
        currentPath: '/auth/login',
      );
      expect(r, '/home');
    });

    test('/splash while authed+onboarded → /home', () {
      final r = authRedirect(
        auth: AsyncValue.data(user),
        onboarded: const AsyncValue.data(true),
        currentPath: '/splash',
      );
      expect(r, '/home');
    });

    test('/onboarding while already onboarded → /home', () {
      final r = authRedirect(
        auth: AsyncValue.data(user),
        onboarded: const AsyncValue.data(true),
        currentPath: '/onboarding',
      );
      expect(r, '/home');
    });
  });
}
