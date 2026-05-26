import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/user_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/update_display_name_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class _MockUserRepository extends Mock implements UserRepository {}

/// Q-26 Option A — [UpdateDisplayNameUseCase].
void main() {
  late _MockUserRepository repo;
  late UpdateDisplayNameUseCase useCase;

  final baseUser = User(
    id: UserId('11111111-1111-1111-1111-111111111111'),
    pseudo: Pseudonym('cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.murid,
    pseudoFull: 'cherif#4231',
  );

  setUp(() {
    repo = _MockUserRepository();
    useCase = UpdateDisplayNameUseCase(repo);
  });

  group('UpdateDisplayNameUseCase', () {
    test('calls repository.updateDisplayName with trimmed name', () async {
      final expected = baseUser.copyWith(displayName: 'Cherif Diouf');
      when(
        () => repo.updateDisplayName(baseUser, 'Cherif Diouf'),
      ).thenAnswer((_) async => expected);

      final result = await useCase(
        currentUser: baseUser,
        displayName: 'Cherif Diouf',
      );

      expect(result.displayName, 'Cherif Diouf');
      verify(() => repo.updateDisplayName(baseUser, 'Cherif Diouf')).called(1);
    });

    test('trims whitespace before forwarding to repository', () async {
      final expected = baseUser.copyWith(displayName: 'Cherif Diouf');
      when(
        () => repo.updateDisplayName(baseUser, 'Cherif Diouf'),
      ).thenAnswer((_) async => expected);

      await useCase(currentUser: baseUser, displayName: '  Cherif Diouf  ');

      verify(() => repo.updateDisplayName(baseUser, 'Cherif Diouf')).called(1);
    });

    test('empty string is forwarded as-is after trim', () async {
      when(
        () => repo.updateDisplayName(baseUser, ''),
      ).thenAnswer((_) async => baseUser);

      await useCase(currentUser: baseUser, displayName: '   ');

      verify(() => repo.updateDisplayName(baseUser, '')).called(1);
    });
  });
}
