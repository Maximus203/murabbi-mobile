import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/delete_account_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/get_current_user_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/send_password_reset_email_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/sign_in_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/sign_in_with_google_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/sign_out_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/sign_up_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/watch_auth_state_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  final testUser = User(
    id: UserId('user-uuid-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime(2026, 1, 1),
    level: Level.aspirant,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('SignInUseCase', () {
    late SignInUseCase useCase;

    setUp(() => useCase = SignInUseCase(mockRepo));

    test('normalizes email + delegates to repository on valid input', () async {
      when(
        () =>
            mockRepo.signIn(email: 'cherif@example.com', password: 'pass1234'),
      ).thenAnswer((_) async => testUser);

      final result = await useCase(
        email: 'Cherif@Example.COM',
        password: 'pass1234',
      );

      expect(result, testUser);
      verify(
        () =>
            mockRepo.signIn(email: 'cherif@example.com', password: 'pass1234'),
      ).called(1);
    });

    test('rejects malformed email before hitting the repository', () async {
      expect(
        () => useCase(email: 'not-an-email', password: 'pass1234'),
        throwsArgumentError,
      );
      verifyNever(
        () => mockRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('rejects too-short password before hitting the repository', () async {
      expect(
        () => useCase(email: 'a@b.co', password: 'short'),
        throwsArgumentError,
      );
      verifyNever(
        () => mockRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('propagates repository exception', () async {
      when(
        () => mockRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('invalid credentials'));

      expect(
        () => useCase(email: 'bad@email.com', password: 'wrong-pass'),
        throwsException,
      );
    });
  });

  group('SignUpUseCase (#131 — displayName devient le pseudo)', () {
    late SignUpUseCase useCase;

    setUp(() => useCase = SignUpUseCase(mockRepo));

    test('normalizes email + delegates on valid input', () async {
      when(
        () => mockRepo.signUp(
          email: 'cherif@example.com',
          password: 'pass1234',
          displayName: 'Cherif',
        ),
      ).thenAnswer((_) async => testUser);

      final result = await useCase(
        email: 'Cherif@Example.COM',
        password: 'pass1234',
        displayName: 'Cherif',
      );

      expect(result, testUser);
      verify(
        () => mockRepo.signUp(
          email: 'cherif@example.com',
          password: 'pass1234',
          displayName: 'Cherif',
        ),
      ).called(1);
    });

    test('rejects malformed email', () async {
      expect(
        () => useCase(
          email: 'invalid',
          password: 'pass1234',
          displayName: 'Cherif',
        ),
        throwsArgumentError,
      );
    });

    test('rejects too-short password', () async {
      expect(
        () =>
            useCase(email: 'a@b.co', password: 'short', displayName: 'Cherif'),
        throwsArgumentError,
      );
    });

    test('rejects empty displayName', () async {
      expect(
        () =>
            useCase(email: 'a@b.co', password: 'pass1234', displayName: '   '),
        throwsArgumentError,
      );
    });
  });

  group('SignInWithGoogleUseCase', () {
    late SignInWithGoogleUseCase useCase;

    setUp(() => useCase = SignInWithGoogleUseCase(mockRepo));

    test('delegates to repository.signInWithGoogle', () async {
      when(() => mockRepo.signInWithGoogle()).thenAnswer((_) async => testUser);

      final result = await useCase();

      expect(result, testUser);
      verify(() => mockRepo.signInWithGoogle()).called(1);
    });
  });

  group('SendPasswordResetEmailUseCase', () {
    late SendPasswordResetEmailUseCase useCase;

    setUp(() => useCase = SendPasswordResetEmailUseCase(mockRepo));

    test('normalizes email and delegates', () async {
      when(
        () => mockRepo.sendPasswordResetEmail(email: 'cherif@example.com'),
      ).thenAnswer((_) async {});

      await useCase(email: 'Cherif@Example.COM');

      verify(
        () => mockRepo.sendPasswordResetEmail(email: 'cherif@example.com'),
      ).called(1);
    });

    test('rejects malformed email before hitting the repository', () async {
      expect(() => useCase(email: 'invalid'), throwsArgumentError);
      verifyNever(
        () => mockRepo.sendPasswordResetEmail(email: any(named: 'email')),
      );
    });
  });

  group('SignOutUseCase', () {
    late SignOutUseCase useCase;

    setUp(() => useCase = SignOutUseCase(mockRepo));

    test('calls repository.signOut', () async {
      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      await useCase();

      verify(() => mockRepo.signOut()).called(1);
    });
  });

  group('DeleteAccountUseCase', () {
    late DeleteAccountUseCase useCase;
    final userId = UserId('user-uuid-001');

    setUp(() => useCase = DeleteAccountUseCase(mockRepo));

    test('calls repository.deleteAccount with userId', () async {
      when(() => mockRepo.deleteAccount(userId)).thenAnswer((_) async {});

      await useCase(userId);

      verify(() => mockRepo.deleteAccount(userId)).called(1);
    });
  });

  group('GetCurrentUserUseCase', () {
    late GetCurrentUserUseCase useCase;

    setUp(() => useCase = GetCurrentUserUseCase(mockRepo));

    test('returns the current user when one exists', () async {
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => testUser);

      final result = await useCase();

      expect(result, testUser);
    });

    test('returns null when nobody is signed in', () async {
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => null);

      final result = await useCase();

      expect(result, isNull);
    });
  });

  group('WatchAuthStateUseCase', () {
    late WatchAuthStateUseCase useCase;

    setUp(() => useCase = WatchAuthStateUseCase(mockRepo));

    test('forwards the repository auth-state stream', () async {
      final controller = StreamController<User?>();
      when(
        () => mockRepo.authStateChanges,
      ).thenAnswer((_) => controller.stream);

      final emissions = <User?>[];
      final sub = useCase().listen(emissions.add);

      controller
        ..add(null)
        ..add(testUser)
        ..add(null);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [null, testUser, null]);
      await sub.cancel();
      await controller.close();
    });
  });
}
