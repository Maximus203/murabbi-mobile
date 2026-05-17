import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_global_streak_use_case.dart';

void main() {
  const useCase = ComputeGlobalStreakUseCase();
  final ref = DateTime(2026, 5, 17);

  group('ComputeGlobalStreakUseCase', () {
    test("historique vide → streak = 0", () {
      expect(
        useCase(history: const [], referenceDate: ref, level: Level.aspirant),
        0,
      );
    });

    test('jour de référence sous le dailyGoal → streak = 0', () {
      // aspirant dailyGoal = 30, on envoie 29 pts pour le jour ref
      final history = [DailyScore(date: ref, points: 29)];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        0,
      );
    });

    test('1 seul jour au-dessus du goal → streak = 1', () {
      final history = [DailyScore(date: ref, points: 30)];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        1,
      );
    });

    test('3 jours consécutifs au-dessus → streak = 3', () {
      final history = [
        DailyScore(date: ref, points: 40),
        DailyScore(date: ref.subtract(const Duration(days: 1)), points: 35),
        DailyScore(date: ref.subtract(const Duration(days: 2)), points: 30),
      ];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        3,
      );
    });

    test("trou dans l'historique brise le streak", () {
      // ref → OK, ref-1 → ABSENT, ref-2 → OK → streak = 1 (pas 2)
      final history = [
        DailyScore(date: ref, points: 40),
        DailyScore(date: ref.subtract(const Duration(days: 2)), points: 35),
      ];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        1,
      );
    });

    test('jour inférieur au goal brise le streak', () {
      // ref → OK, ref-1 → sous goal → streak = 1
      final history = [
        DailyScore(date: ref, points: 40),
        DailyScore(date: ref.subtract(const Duration(days: 1)), points: 10),
        DailyScore(date: ref.subtract(const Duration(days: 2)), points: 50),
      ];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        1,
      );
    });

    test('changement de niveau évalué avec le nouveau dailyGoal', () {
      // murid dailyGoal = 45. Même historique : 40 pts/jour < 45 → streak 0
      final history = [
        DailyScore(date: ref, points: 40),
        DailyScore(date: ref.subtract(const Duration(days: 1)), points: 40),
      ];
      // Aspirant (goal 30) → streak 2 ; Murid (goal 45) → streak 0
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        2,
      );
      expect(
        useCase(history: history, referenceDate: ref, level: Level.murid),
        0,
      );
    });

    test('normalization date : heure de referenceDate ignorée', () {
      // Date avec heure non minuit
      final refWithTime = DateTime(2026, 5, 17, 14, 30);
      final history = [
        DailyScore(date: DateTime(2026, 5, 17), points: 35),
        DailyScore(date: DateTime(2026, 5, 16), points: 35),
      ];
      expect(
        useCase(
          history: history,
          referenceDate: refWithTime,
          level: Level.aspirant,
        ),
        2,
      );
    });

    test('points exactement égaux au goal → comptés dans le streak', () {
      final goal = Level.salik.dailyGoal; // 60
      final history = [
        DailyScore(date: ref, points: goal),
        DailyScore(date: ref.subtract(const Duration(days: 1)), points: goal),
      ];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.salik),
        2,
      );
    });
  });
}
