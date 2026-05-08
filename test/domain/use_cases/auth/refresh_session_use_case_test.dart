import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/refresh_session_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late RefreshSessionUseCase useCase;

  final refreshedUser = User(
    id: UserId('uuid-1'),
    pseudo: NonEmptyString('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime(2026, 5, 7),
    level: Level.aspirant,
  );

  setUp(() {
    repo = MockAuthRepository();
    useCase = RefreshSessionUseCase(repo);
  });

  test('returns the refreshed user when repository succeeds', () async {
    when(() => repo.refreshSession()).thenAnswer((_) async => refreshedUser);

    final result = await useCase();

    expect(result, refreshedUser);
    verify(() => repo.refreshSession()).called(1);
  });

  test(
    'returns null when repository returns null (no active session)',
    () async {
      when(() => repo.refreshSession()).thenAnswer((_) async => null);

      expect(await useCase(), isNull);
    },
  );

  test('propagates AuthFailure on error', () async {
    when(
      () => repo.refreshSession(),
    ).thenThrow(const AuthFailure.network(message: 'offline'));

    expect(() => useCase(), throwsA(isA<NetworkFailure>()));
  });
}
