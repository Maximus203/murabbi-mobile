import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../helpers/test_uuids.dart';

void main() {
  final userId = UserId(kUserIdAlpha);
  final today = DateTime(2026, 5, 25);

  group('DailySummary entity', () {
    test('creates with valid fields', () {
      final summary = DailySummary(
        userId: userId,
        day: today,
        completionRate: 70.0,
        streakValid: false,
        habitPointsToday: 12,
      );
      expect(summary.userId, userId);
      expect(summary.day, today);
      expect(summary.completionRate, 70.0);
      expect(summary.streakValid, isFalse);
      expect(summary.habitPointsToday, 12);
    });

    test('completionRate 0.0 is valid (empty day)', () {
      expect(
        () => DailySummary(
          userId: userId,
          day: today,
          completionRate: 0.0,
          streakValid: false,
          habitPointsToday: 0,
        ),
        returnsNormally,
      );
    });

    test('completionRate 100.0 is valid (perfect day)', () {
      expect(
        () => DailySummary(
          userId: userId,
          day: today,
          completionRate: 100.0,
          streakValid: true,
          habitPointsToday: 30,
        ),
        returnsNormally,
      );
    });

    test('completionRate < 0 throws ArgumentError', () {
      expect(
        () => DailySummary(
          userId: userId,
          day: today,
          completionRate: -0.01,
          streakValid: false,
          habitPointsToday: 0,
        ),
        throwsArgumentError,
      );
    });

    test('completionRate > 100 throws ArgumentError', () {
      expect(
        () => DailySummary(
          userId: userId,
          day: today,
          completionRate: 100.01,
          streakValid: true,
          habitPointsToday: 0,
        ),
        throwsArgumentError,
      );
    });

    test('habitPointsToday < 0 throws ArgumentError', () {
      expect(
        () => DailySummary(
          userId: userId,
          day: today,
          completionRate: 50.0,
          streakValid: false,
          habitPointsToday: -1,
        ),
        throwsArgumentError,
      );
    });

    test('habitPointsToday 0 is valid', () {
      expect(
        () => DailySummary(
          userId: userId,
          day: today,
          completionRate: 50.0,
          streakValid: false,
          habitPointsToday: 0,
        ),
        returnsNormally,
      );
    });

    test('two summaries with same fields are equal', () {
      final a = DailySummary(
        userId: userId,
        day: today,
        completionRate: 70.0,
        streakValid: false,
        habitPointsToday: 12,
      );
      final b = DailySummary(
        userId: userId,
        day: today,
        completionRate: 70.0,
        streakValid: false,
        habitPointsToday: 12,
      );
      expect(a, equals(b));
    });

    test('different habitPointsToday → not equal', () {
      final a = DailySummary(
        userId: userId,
        day: today,
        completionRate: 70.0,
        streakValid: false,
        habitPointsToday: 10,
      );
      final b = DailySummary(
        userId: userId,
        day: today,
        completionRate: 70.0,
        streakValid: false,
        habitPointsToday: 20,
      );
      expect(a, isNot(equals(b)));
    });

    test('different days → not equal', () {
      final a = DailySummary(
        userId: userId,
        day: DateTime(2026, 5, 25),
        completionRate: 70.0,
        streakValid: false,
        habitPointsToday: 0,
      );
      final b = DailySummary(
        userId: userId,
        day: DateTime(2026, 5, 24),
        completionRate: 70.0,
        streakValid: false,
        habitPointsToday: 0,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
