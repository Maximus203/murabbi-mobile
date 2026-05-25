import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/repositories/daily_summary_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/score/get_daily_summary_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../../helpers/test_uuids.dart';

class MockDailySummaryRepo extends Mock implements DailySummaryRepository {}

void main() {
  late MockDailySummaryRepo repo;
  final userId = UserId(kUserIdAlpha);

  final todaySummary = DailySummary(
    userId: userId,
    day: DateTime(2026, 5, 25),
    completionRate: 70.0,
    streakValid: false,
    habitPointsToday: 12,
  );

  setUp(() => repo = MockDailySummaryRepo());

  group('GetDailySummaryUseCase', () {
    test('retourne le résumé du jour quand il existe', () async {
      when(
        () => repo.getTodaySummary(userId),
      ).thenAnswer((_) async => todaySummary);

      final result = await GetDailySummaryUseCase(repo).call(userId);

      expect(result, todaySummary);
      verify(() => repo.getTodaySummary(userId)).called(1);
    });

    test("retourne null quand aucun résumé pour aujourd'hui", () async {
      when(
        () => repo.getTodaySummary(userId),
      ).thenAnswer((_) async => null);

      final result = await GetDailySummaryUseCase(repo).call(userId);

      expect(result, isNull);
    });
  });
}
