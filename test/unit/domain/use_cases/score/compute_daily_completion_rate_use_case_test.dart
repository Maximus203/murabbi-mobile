import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/repositories/daily_summary_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_daily_completion_rate_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class _MockDailySummaryRepository extends Mock
    implements DailySummaryRepository {}

void main() {
  late _MockDailySummaryRepository repo;
  late ComputeDailyCompletionRateUseCase useCase;

  final userId = UserId('user-123');

  setUp(() {
    repo = _MockDailySummaryRepository();
    useCase = ComputeDailyCompletionRateUseCase(repo);
  });

  DailySummary makeSummary({
    required double completionRate,
    required bool streakValid,
    int habitPointsToday = 0,
  }) =>
      DailySummary(
        userId: userId,
        day: DateTime(2026, 5, 25),
        completionRate: completionRate,
        streakValid: streakValid,
        habitPointsToday: habitPointsToday,
      );

  group('ComputeDailyCompletionRateUseCase', () {
    test('retourne 0.0 si aucun résumé pour aujourd\'hui', () async {
      when(() => repo.getTodaySummary(userId)).thenAnswer((_) async => null);

      final result = await useCase(userId);

      expect(result, 0.0);
    });

    test('retourne completionRate depuis le résumé existant', () async {
      when(() => repo.getTodaySummary(userId)).thenAnswer(
        (_) async => makeSummary(
          completionRate: 87.50,
          streakValid: true,
          habitPointsToday: 70,
        ),
      );

      final result = await useCase(userId);

      expect(result, 87.50);
    });

    test('retourne 0.0 si completionRate == 0.0', () async {
      when(() => repo.getTodaySummary(userId)).thenAnswer(
        (_) async => makeSummary(
          completionRate: 0.0,
          streakValid: false,
        ),
      );

      final result = await useCase(userId);

      expect(result, 0.0);
    });

    test('retourne 100.0 si tout est validé', () async {
      when(() => repo.getTodaySummary(userId)).thenAnswer(
        (_) async => makeSummary(
          completionRate: 100.0,
          streakValid: true,
          habitPointsToday: 100,
        ),
      );

      final result = await useCase(userId);

      expect(result, 100.0);
    });
  });
}
