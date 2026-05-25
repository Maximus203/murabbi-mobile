import 'dart:async';

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
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/remembered_accounts_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../helpers/test_uuids.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  final testUser = User(
    id: UserId(kUserIdAlpha),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime(2026, 1, 1),
    level: Level.aspirant,
  );

  ProviderContainer makeContainer({
    Stream<User?>? authStream,
    bool stubGetCurrentUser = true,
  }) {
    when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => authStream ?? const Stream<User?>.empty());
    if (stubGetCurrentUser) {
      when(() => repo.getCurrentUser()).thenAnswer((_) async => null);
    }
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repo = MockAuthRepository();
  });

  group('AuthNotifier — bootstrap', () {
    test('build() returns null when no session exists', () async {
      final container = makeContainer();
      final state = await container.read(authNotifierProvider.future);
      expect(state, isNull);
    });

    test('build() returns the current user when a session exists', () async {
      final container = makeContainer(stubGetCurrentUser: false);
      when(() => repo.getCurrentUser()).thenAnswer((_) async => testUser);
      final state = await container.read(authNotifierProvider.future);
      expect(state, testUser);
    });

    test('build() exposes AccountDeletedFailure as state error', () async {
      final container = makeContainer(stubGetCurrentUser: false);
      when(
        () => repo.getCurrentUser(),
      ).thenThrow(const AuthFailure.accountDeleted());
      await expectLater(
        container.read(authNotifierProvider.future),
        throwsA(isA<AccountDeletedFailure>()),
      );
    });
  });

  group('AuthNotifier — signIn', () {
    test('emits loading then data on success', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.signIn(email: 'a@b.co', password: 'pass1234'),
      ).thenAnswer((_) async => testUser);

      final notifier = container.read(authNotifierProvider.notifier);
      final future = notifier.signIn(email: 'a@b.co', password: 'pass1234');

      // Loading state observable juste après l'appel (avant await).
      expect(container.read(authNotifierProvider).isLoading, isTrue);

      await future;

      expect(container.read(authNotifierProvider).value, testUser);
    });

    test('emits error AuthFailure on InvalidCredentialsFailure', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure.invalidCredentials());

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'bad@b.co', password: 'wrongpass');

      final state = container.read(authNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<InvalidCredentialsFailure>());
    });
  });

  group('AuthNotifier — signUp (Q-18 — email + password only)', () {
    test('emits loading then data on success', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.signUp(
          email: 'a@b.co',
          password: 'pass1234',
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => testUser);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signUp(
        email: 'a@b.co',
        password: 'pass1234',
        displayName: 'Tester',
      );

      expect(container.read(authNotifierProvider).value, testUser);
    });

    test('emits EmailAlreadyInUseFailure on duplicate email', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenThrow(const AuthFailure.emailAlreadyInUse());

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signUp(
        email: 'a@b.co',
        password: 'pass1234',
        displayName: 'Tester',
      );

      expect(
        container.read(authNotifierProvider).error,
        isA<EmailAlreadyInUseFailure>(),
      );
    });
  });

  group('AuthNotifier — clearError (#116)', () {
    test('clearError réinitialise un état AsyncError en AsyncData', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure.invalidCredentials());

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'bad@b.co', password: 'wrongpass');
      expect(container.read(authNotifierProvider).hasError, isTrue);

      notifier.clearError();

      final state = container.read(authNotifierProvider);
      expect(state.hasError, isFalse);
      expect(state.value, isNull);
    });

    test('clearError est un no-op si l\'état n\'est pas une erreur', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      final notifier = container.read(authNotifierProvider.notifier);
      final before = container.read(authNotifierProvider);
      notifier.clearError();
      final after = container.read(authNotifierProvider);

      expect(after.hasError, isFalse);
      expect(after.value, before.value);
    });
  });

  group('AuthNotifier — defensive initialization', () {
    test('signUp works even if build() has not been started yet', () async {
      final container = makeContainer();

      when(
        () => repo.signUp(
          email: 'a@b.co',
          password: 'pass1234',
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => testUser);

      final notifier = container.read(authNotifierProvider.notifier);

      await expectLater(
        notifier.signUp(
          email: 'a@b.co',
          password: 'pass1234',
          displayName: 'Tester',
        ),
        completes,
      );
      verify(
        () => repo.signUp(
          email: 'a@b.co',
          password: 'pass1234',
          displayName: any(named: 'displayName'),
        ),
      ).called(1);
    });

    test(
      'signInWithGoogle works even if build() has not been started yet',
      () async {
        final container = makeContainer();

        when(() => repo.signInWithGoogle()).thenAnswer((_) async => testUser);

        final notifier = container.read(authNotifierProvider.notifier);

        await expectLater(notifier.signInWithGoogle(), completes);
        verify(() => repo.signInWithGoogle()).called(1);
      },
    );

    test(
      'does not crash with LateInitializationError if build() previously failed',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWith((ref) {
              throw StateError('repo unavailable');
            }),
          ],
        );
        addTearDown(container.dispose);

        await expectLater(
          container.read(authNotifierProvider.future),
          throwsA(isA<StateError>()),
        );

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signUp(
          email: 'a@b.co',
          password: 'pass1234',
          displayName: 'Tester',
        );

        final state = container.read(authNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<StateError>());
      },
    );
  });

  group('AuthNotifier — signInWithGoogle', () {
    test('emits user on success', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(() => repo.signInWithGoogle()).thenAnswer((_) async => testUser);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();

      expect(container.read(authNotifierProvider).value, testUser);
    });

    test('emits NetworkFailure when offline', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.signInWithGoogle(),
      ).thenThrow(const AuthFailure.network());

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();

      expect(container.read(authNotifierProvider).error, isA<NetworkFailure>());
    });
  });

  group('AuthNotifier — sendPasswordReset', () {
    test('returns true on success without changing main state', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.sendPasswordResetEmail(email: 'a@b.co'),
      ).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      final ok = await notifier.sendPasswordReset(email: 'a@b.co');

      expect(ok, isTrue);
      expect(container.read(authNotifierProvider).value, isNull);
      verify(() => repo.sendPasswordResetEmail(email: 'a@b.co')).called(1);
    });

    test(
      'returns false on network failure (UI shows generic success)',
      () async {
        final container = makeContainer();
        await container.read(authNotifierProvider.future);

        when(
          () => repo.sendPasswordResetEmail(email: any(named: 'email')),
        ).thenThrow(const AuthFailure.network());

        final notifier = container.read(authNotifierProvider.notifier);
        final ok = await notifier.sendPasswordReset(email: 'a@b.co');

        expect(ok, isFalse);
      },
    );
  });

  group('AuthNotifier — resendVerificationEmail', () {
    test('returns true on success without changing main state', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.resendVerificationEmail(email: 'cherif@example.com'),
      ).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      final ok = await notifier.resendVerificationEmail(
        email: 'cherif@example.com',
      );

      expect(ok, isTrue);
      expect(container.read(authNotifierProvider).value, isNull);
      verify(
        () => repo.resendVerificationEmail(email: 'cherif@example.com'),
      ).called(1);
    });

    test('returns false on AuthFailure (rate-limit / network)', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.resendVerificationEmail(email: any(named: 'email')),
      ).thenThrow(const AuthFailure.network());

      final notifier = container.read(authNotifierProvider.notifier);
      final ok = await notifier.resendVerificationEmail(email: 'a@b.co');

      expect(ok, isFalse);
    });
  });

  group('AuthNotifier — signOut', () {
    test('clears user state on success', () async {
      final container = makeContainer(stubGetCurrentUser: false);
      when(() => repo.getCurrentUser()).thenAnswer((_) async => testUser);
      await container.read(authNotifierProvider.future);

      when(() => repo.signOut()).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signOut();

      expect(container.read(authNotifierProvider).value, isNull);
    });
  });

  group('AuthNotifier — _rememberEmail hook (PR #41 regression)', () {
    test('signIn success → email mémorisé (lowercase + trim)', () async {
      SharedPreferences.setMockInitialValues({});
      when(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testUser);
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      await container
          .read(authNotifierProvider.notifier)
          .signIn(email: '  CHERIF@Example.COM  ', password: 'pass1234');
      // Laisse le fire-and-forget propager (multi-microtâches : guard
      // catch → remember() async → setStringList → state update).
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final remembered = await container.read(
        rememberedAccountsNotifierProvider.future,
      );
      expect(remembered, contains('cherif@example.com'));
    });

    test('signIn failure → email PAS mémorisé', () async {
      SharedPreferences.setMockInitialValues({});
      when(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure.invalidCredentials());
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      await container
          .read(authNotifierProvider.notifier)
          .signIn(email: 'wrong@example.com', password: 'badpass');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final remembered = await container.read(
        rememberedAccountsNotifierProvider.future,
      );
      expect(remembered, isEmpty);
    });

    test('signUp success → email mémorisé', () async {
      SharedPreferences.setMockInitialValues({});
      when(
        () => repo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => testUser);
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      await container
          .read(authNotifierProvider.notifier)
          .signUp(
            email: 'new@example.com',
            password: 'pass1234',
            displayName: 'Tester',
          );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final remembered = await container.read(
        rememberedAccountsNotifierProvider.future,
      );
      expect(remembered, contains('new@example.com'));
    });
  });

  group('AuthNotifier — authStateChanges stream', () {
    test('updates state when stream emits a new user', () async {
      final controller = StreamController<User?>();
      final container = makeContainer(authStream: controller.stream);
      await container.read(authNotifierProvider.future);

      controller.add(testUser);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authNotifierProvider).value, testUser);

      controller.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authNotifierProvider).value, isNull);

      await controller.close();
    });
  });

  // ── Bug S-2/S-3 : stream error ne déconnecte pas une session valide ──
  group('AuthNotifier — stream error préserve session active (Bug S-2/S-3)', () {
    test(
      'stream error ne remplace PAS state si une session est déjà active',
      () async {
        // Simule : getCurrentUser() retourne un user (session valide),
        // puis le stream émet une erreur (ex. TOKEN_REFRESHED + DB offline).
        // Résultat attendu : state reste le user, pas AsyncError.
        final errorController = StreamController<User?>();
        final container = makeContainer(
          authStream: errorController.stream,
          stubGetCurrentUser: false,
        );
        when(() => repo.getCurrentUser()).thenAnswer((_) async => testUser);

        await container.read(authNotifierProvider.future);
        expect(container.read(authNotifierProvider).value, testUser);

        errorController.addError(
          Exception('DB unreachable — TOKEN_REFRESHED'),
          StackTrace.empty,
        );
        await Future<void>.delayed(Duration.zero);

        // Session doit être préservée — pas de redirect vers login.
        final state = container.read(authNotifierProvider);
        expect(
          state.value,
          testUser,
          reason:
              'Une erreur réseau transitoire du stream ne doit pas '
              'déconnecter un utilisateur dont la session est valide.',
        );
        expect(state.hasError, isFalse);

        await errorController.close();
      },
    );

    test(
      'stream error définit AsyncError si aucune session active (état null)',
      () async {
        // Sans session, une erreur stream doit remonter normalement
        // (ex. une config Supabase incorrecte doit être visible).
        final errorController = StreamController<User?>();
        final container = makeContainer(authStream: errorController.stream);
        await container.read(authNotifierProvider.future);
        expect(container.read(authNotifierProvider).value, isNull);

        errorController.addError(
          Exception('Config error'),
          StackTrace.empty,
        );
        await Future<void>.delayed(Duration.zero);

        expect(container.read(authNotifierProvider).hasError, isTrue);

        await errorController.close();
      },
    );
  });
}
