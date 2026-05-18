import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/user_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/update_profile_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockUserRepository repo;
  late UpdateProfileUseCase useCase;

  final baseUser = User(
    id: UserId('user-1'),
    pseudo: Pseudonym('Ancien'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime(2026, 1, 1),
    level: Level.aspirant,
  );

  setUp(() {
    repo = _MockUserRepository();
    useCase = UpdateProfileUseCase(repo);
    registerFallbackValue(baseUser);
  });

  test(
    'trims the pseudo then delegates an updated User to the repository',
    () async {
      final captured = <User>[];
      when(() => repo.updateUser(any())).thenAnswer((invocation) async {
        final u = invocation.positionalArguments.first as User;
        captured.add(u);
        return u;
      });

      final result = await useCase(
        currentUser: baseUser,
        newPseudo: '  Nouveau  ',
      );

      expect(captured.single.pseudo.value, 'Nouveau');
      expect(captured.single.id, baseUser.id);
      expect(result.pseudo.value, 'Nouveau');
      verify(() => repo.updateUser(any())).called(1);
    },
  );

  test('rejects an empty pseudo before hitting the repository', () async {
    expect(
      () => useCase(currentUser: baseUser, newPseudo: '   '),
      throwsArgumentError,
    );
    verifyNever(() => repo.updateUser(any()));
  });

  test('rejects a pseudo longer than 30 characters', () async {
    expect(
      () => useCase(currentUser: baseUser, newPseudo: 'x' * 31),
      throwsArgumentError,
    );
    verifyNever(() => repo.updateUser(any()));
  });

  test('propagates repository failure', () async {
    when(() => repo.updateUser(any())).thenThrow(Exception('network'));
    expect(
      () => useCase(currentUser: baseUser, newPseudo: 'Nouveau'),
      throwsException,
    );
  });
}
