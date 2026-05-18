import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/user_data_source.dart';
import 'package:murabbi_mobile/data/repositories/user_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class _MockUserDataSource extends Mock implements UserDataSource {}

void main() {
  late _MockUserDataSource ds;
  late UserRepositoryImpl repo;

  final user = User(
    id: UserId('user-1'),
    pseudo: Pseudonym('Nouveau'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime(2026, 1, 1),
    level: Level.murid,
    currentStreak: 5,
    completionRate: 0.8,
  );

  setUp(() => ds = _MockUserDataSource());

  test(
    'updateUser persists the pseudo and returns the updated entity',
    () async {
      when(
        () => ds.updatePseudo(userId: 'user-1', pseudo: 'Nouveau'),
      ).thenAnswer(
        (_) async => {
          'pseudo': 'Nouveau',
          'email': 'cherif@example.com',
          'level': 'murid',
          'current_streak': 5,
          'completion_rate': 0.8,
          'deletion_requested_at': null,
        },
      );

      repo = UserRepositoryImpl(ds);
      final result = await repo.updateUser(user);

      expect(result.pseudo.value, 'Nouveau');
      expect(result.id, user.id);
      verify(
        () => ds.updatePseudo(userId: 'user-1', pseudo: 'Nouveau'),
      ).called(1);
    },
  );

  test(
    'getUser returns null (read path delegated to AuthRepository)',
    () async {
      repo = UserRepositoryImpl(ds);
      expect(await repo.getUser(UserId('user-1')), isNull);
    },
  );
}
