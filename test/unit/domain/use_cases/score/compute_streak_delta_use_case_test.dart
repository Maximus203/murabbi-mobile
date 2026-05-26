import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_streak_delta_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Delta de streak hebdomadaire (issue #6, Phase 5 — Q-D Option B).
///
/// Δstreak = streak(today) − streak(today − 7 jours).
/// Positif → progression cette semaine.
/// Négatif → régression.
/// Zéro    → stable.
void main() {
  const useCase = ComputeStreakDeltaUseCase();
  final today = DateTime(2026, 5, 26);

  // Helper : fabrique un DailySummary minimal pour un jour donné.
  DailySummary makeDay(DateTime date, {required bool valid}) {
    return DailySummary(
      userId: UserId('u1'),
      day: date,
      completionRate: valid ? 100.0 : 0.0,
      streakValid: valid,
      habitPointsToday: valid ? 10 : 0,
    );
  }

  group('ComputeStreakDeltaUseCase', () {
    test('historique vide → delta 0', () {
      expect(useCase(history: const [], referenceDate: today), 0);
    });

    test('delta positif — streak a progressé cette semaine', () {
      // Streak today = 3 jours (24/25/26 mai)
      // Streak (today - 7) = 19 mai → streak = 0
      final history = [
        makeDay(DateTime(2026, 5, 24), valid: true),
        makeDay(DateTime(2026, 5, 25), valid: true),
        makeDay(DateTime(2026, 5, 26), valid: true),
      ];
      // streak(today)        = 3
      // streak(today - 7j)   = 0 (aucun jour valide autour du 19 mai)
      expect(useCase(history: history, referenceDate: today), 3);
    });

    test('delta négatif — streak a régressé', () {
      // Il y a 7 jours : streak = 3 (17/18/19 mai)
      // Aujourd'hui : streak = 1 (26 mai seulement)
      final history = [
        makeDay(DateTime(2026, 5, 17), valid: true),
        makeDay(DateTime(2026, 5, 18), valid: true),
        makeDay(DateTime(2026, 5, 19), valid: true),
        makeDay(DateTime(2026, 5, 26), valid: true),
      ];
      // streak(today)      = 1
      // streak(today - 7j) = 3
      expect(useCase(history: history, referenceDate: today), -2);
    });

    test('delta zéro — streak identique entre aujourd\'hui et il y a 7j', () {
      // Streak = 2 dans les deux cas
      final history = [
        makeDay(DateTime(2026, 5, 18), valid: true),
        makeDay(DateTime(2026, 5, 19), valid: true),
        makeDay(DateTime(2026, 5, 25), valid: true),
        makeDay(DateTime(2026, 5, 26), valid: true),
      ];
      // streak(today)      = 2 (25/26 mai)
      // streak(today - 7j) = 2 (18/19 mai)
      expect(useCase(history: history, referenceDate: today), 0);
    });

    test('aujourd\'hui non encore validé — ne pénalise pas (règle J-1)', () {
      // today=26 mai, pas encore validé → on compte depuis J-1 (25 mai)
      final history = [
        makeDay(DateTime(2026, 5, 26), valid: false), // today not done
        makeDay(DateTime(2026, 5, 25), valid: true),
        makeDay(DateTime(2026, 5, 24), valid: true),
      ];
      // streak(today)      = 2 (J-1 = 25, J-2 = 24)
      // streak(today - 7j) = 0
      expect(useCase(history: history, referenceDate: today), 2);
    });

    test('streak J-7 non nul quand historique couvre les deux fenêtres', () {
      // Streak today = 2 (25/26 mai)
      // Streak J-7  = 3 (17/18/19 mai)
      final history = [
        makeDay(DateTime(2026, 5, 17), valid: true),
        makeDay(DateTime(2026, 5, 18), valid: true),
        makeDay(DateTime(2026, 5, 19), valid: true),
        makeDay(DateTime(2026, 5, 25), valid: true),
        makeDay(DateTime(2026, 5, 26), valid: true),
      ];
      // streak(today)      = 2
      // streak(today - 7j) = 3
      expect(useCase(history: history, referenceDate: today), -1);
    });
  });
}
