import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/delete_account_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/sign_in_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/sign_out_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/sign_up_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  final testUser = User(
    id: UserId('user-uuid-001'),
    displayName: NonEmptyString('Cherif'),
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

    test('calls repository.signIn and returns user', () async {
      when(
        () => mockRepo.signIn(email: 'cherif@example.com', password: 'pass123'),
      ).thenAnswer((_) async => testUser);

      final result = await useCase(
        email: 'cherif@example.com',
        password: 'pass123',
      );

      expect(result, testUser);
      verify(
        () => mockRepo.signIn(email: 'cherif@example.com', password: 'pass123'),
      ).called(1);
    });

    test('propagates repository exception', () async {
      when(
        () => mockRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('invalid credentials'));

      expect(
        () => useCase(email: 'bad@email.com', password: 'wrong'),
        throwsException,
      );
    });
  });

  group('SignUpUseCase', () {
    late SignUpUseCase useCase;

    setUp(() => useCase = SignUpUseCase(mockRepo));

    test('calls repository.signUp and returns user', () async {
      when(
        () => mockRepo.signUp(
          email: 'cherif@example.com',
          password: 'pass123',
          displayName: 'Cherif',
        ),
      ).thenAnswer((_) async => testUser);

      final result = await useCase(
        email: 'cherif@example.com',
        password: 'pass123',
        displayName: 'Cherif',
      );

      expect(result, testUser);
      verify(
        () => mockRepo.signUp(
          email: 'cherif@example.com',
          password: 'pass123',
          displayName: 'Cherif',
        ),
      ).called(1);
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
}
