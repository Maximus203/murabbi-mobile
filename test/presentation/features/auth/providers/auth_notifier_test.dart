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
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  final testUser = User(
    id: UserId('user-uuid-001'),
    pseudo: NonEmptyString('Cherif'),
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
        () => repo.signUp(email: 'a@b.co', password: 'pass1234'),
      ).thenAnswer((_) async => testUser);

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signUp(email: 'a@b.co', password: 'pass1234');

      expect(container.read(authNotifierProvider).value, testUser);
    });

    test('emits EmailAlreadyInUseFailure on duplicate email', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      when(
        () => repo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure.emailAlreadyInUse());

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signUp(email: 'a@b.co', password: 'pass1234');

      expect(
        container.read(authNotifierProvider).error,
        isA<EmailAlreadyInUseFailure>(),
      );
    });
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
}
