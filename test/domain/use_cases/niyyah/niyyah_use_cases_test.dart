import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/niyyah/get_today_niyyah_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/niyyah/set_today_niyyah_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../../helpers/test_uuids.dart';

class MockNiyyahRepository extends Mock implements NiyyahRepository {}

void main() {
  late MockNiyyahRepository mockRepo;
  final userId = UserId(kUserIdAlpha);
  final today = DateTime(2026, 4, 28);

  final testNiyyah = DailyNiyyah(
    userId: userId,
    date: today,
    text: NonEmptyString("Aujourd'hui, je m'engage à prier à l'heure."),
  );

  setUp(() {
    mockRepo = MockNiyyahRepository();
  });

  group('GetTodayNiyyahUseCase', () {
    late GetTodayNiyyahUseCase useCase;

    setUp(() => useCase = GetTodayNiyyahUseCase(mockRepo));

    test('returns niyyah when one exists for today', () async {
      when(
        () => mockRepo.getTodayNiyyah(userId),
      ).thenAnswer((_) async => testNiyyah);

      final result = await useCase(userId);

      expect(result, testNiyyah);
      verify(() => mockRepo.getTodayNiyyah(userId)).called(1);
    });

    test('returns null when no niyyah exists for today', () async {
      when(() => mockRepo.getTodayNiyyah(userId)).thenAnswer((_) async => null);

      final result = await useCase(userId);

      expect(result, isNull);
      verify(() => mockRepo.getTodayNiyyah(userId)).called(1);
    });
  });

  group('SetTodayNiyyahUseCase', () {
    late SetTodayNiyyahUseCase useCase;
    final text = NonEmptyString("Aujourd'hui, je m'engage à prier à l'heure.");

    setUp(() => useCase = SetTodayNiyyahUseCase(mockRepo));

    test('calls repository.setTodayNiyyah and returns saved niyyah', () async {
      when(
        () => mockRepo.setTodayNiyyah(userId: userId, text: text),
      ).thenAnswer((_) async => testNiyyah);

      final result = await useCase(userId: userId, text: text);

      expect(result, testNiyyah);
      verify(
        () => mockRepo.setTodayNiyyah(userId: userId, text: text),
      ).called(1);
    });
  });
}
