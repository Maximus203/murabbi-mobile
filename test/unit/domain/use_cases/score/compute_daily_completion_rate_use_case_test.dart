import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/repositories/daily_summary_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_daily_completion_rate_use_case.dart';

class _MockDailySummaryRepository extends Mock
    implements DailySummaryRepository {}

void main() {
  late _MockDailySummaryRepository repo;
  late ComputeDailyCompletionRateUseCase useCase;

  const userId = 'user-123';

  setUp(() {
    repo = _MockDailySummaryRepository();
    useCase = ComputeDailyCompletionRateUseCase(repo);
  });

  DailySummary makeSummary({
    required int totalItems,
    required int doneItems,
    required double completionRate,
    required bool streakValid,
  }) =>
      DailySummary(
        userId: userId,
        day: DateTime(2026, 5, 25),
        totalItems: totalItems,
        doneItems: doneItems,
        completionRate: completionRate,
        streakValid: streakValid,
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
          totalItems: 8,
          doneItems: 7,
          completionRate: 87.50,
          streakValid: true,
        ),
      );

      final result = await useCase(userId);

      expect(result, 87.50);
    });

    test('retourne 0.0 si totalItems == 0', () async {
      when(() => repo.getTodaySummary(userId)).thenAnswer(
        (_) async => makeSummary(
          totalItems: 0,
          doneItems: 0,
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
          totalItems: 10,
          doneItems: 10,
          completionRate: 100.0,
          streakValid: true,
        ),
      );

      final result = await useCase(userId);

      expect(result, 100.0);
    });
  });
}
