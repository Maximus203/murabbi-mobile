import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_global_streak_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

void main() {
  const useCase = ComputeGlobalStreakUseCase();
  final ref = DateTime(2026, 5, 17);

  DailySummary day(DateTime date, {required bool valid}) => DailySummary(
        userId: UserId('u'),
        day: date,
        completionRate: valid ? 87.5 : 25.0,
        streakValid: valid,
        habitPointsToday: valid ? 70 : 20,
      );

  group('ComputeGlobalStreakUseCase', () {
    test('historique vide → streak = 0', () {
      expect(useCase(history: const [], referenceDate: ref), 0);
    });

    test('jour de référence non valide → streak = 0 '
        '(aujourd\'hui non terminé, J-1 absent)', () {
      final history = [day(ref, valid: false)];
      expect(useCase(history: history, referenceDate: ref), 0);
    });

    test('1 seul jour valide (aujourd\'hui) → streak = 1', () {
      final history = [day(ref, valid: true)];
      expect(useCase(history: history, referenceDate: ref), 1);
    });

    test('3 jours consécutifs valides → streak = 3', () {
      final history = [
        day(ref, valid: true),
        day(ref.subtract(const Duration(days: 1)), valid: true),
        day(ref.subtract(const Duration(days: 2)), valid: true),
      ];
      expect(useCase(history: history, referenceDate: ref), 3);
    });

    test("trou dans l'historique brise le streak", () {
      // ref → valid, ref-1 → ABSENT, ref-2 → valid → streak = 1 (pas 2)
      final history = [
        day(ref, valid: true),
        day(ref.subtract(const Duration(days: 2)), valid: true),
      ];
      expect(useCase(history: history, referenceDate: ref), 1);
    });

    test('jour invalide brise le streak', () {
      final history = [
        day(ref, valid: true),
        day(ref.subtract(const Duration(days: 1)), valid: false),
        day(ref.subtract(const Duration(days: 2)), valid: true),
      ];
      expect(useCase(history: history, referenceDate: ref), 1);
    });

    test('aujourd\'hui non terminé ne pénalise pas — compte depuis J-1', () {
      final history = [
        day(ref, valid: false),
        day(ref.subtract(const Duration(days: 1)), valid: true),
        day(ref.subtract(const Duration(days: 2)), valid: true),
      ];
      expect(useCase(history: history, referenceDate: ref), 2);
    });

    test('normalisation date : heure de referenceDate ignorée', () {
      final refWithTime = DateTime(2026, 5, 17, 14, 30);
      final history = [
        day(DateTime(2026, 5, 17), valid: true),
        day(DateTime(2026, 5, 16), valid: true),
      ];
      expect(useCase(history: history, referenceDate: refWithTime), 2);
    });
  });
}
