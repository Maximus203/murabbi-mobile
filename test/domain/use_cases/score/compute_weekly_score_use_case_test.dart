import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/daily_score.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_weekly_score_use_case.dart';

/// Score hebdomadaire = somme des points sur la fenêtre de 7 jours se
/// terminant à `referenceDate` (incluse) — issue #6, Phase 5.
void main() {
  const useCase = ComputeWeeklyScoreUseCase();
  final monday = DateTime(2026, 5, 11); // lundi
  final sunday = DateTime(2026, 5, 17); // dimanche (référence)

  group('ComputeWeeklyScoreUseCase', () {
    test('historique vide → score 0', () {
      expect(useCase(history: const [], referenceDate: sunday), 0);
    });

    test('somme les points des 7 jours de la fenêtre', () {
      final history = [
        DailyScore(date: monday, points: 10),
        DailyScore(date: DateTime(2026, 5, 14), points: 20),
        DailyScore(date: sunday, points: 30),
      ];
      expect(useCase(history: history, referenceDate: sunday), 60);
    });

    test('ignore les jours hors de la fenêtre de 7 jours', () {
      final history = [
        DailyScore(date: DateTime(2026, 5, 10), points: 100), // hors fenêtre
        DailyScore(date: monday, points: 5),
        DailyScore(date: sunday, points: 7),
      ];
      expect(useCase(history: history, referenceDate: sunday), 12);
    });

    test('ignore les jours futurs (après la référence)', () {
      final history = [
        DailyScore(date: sunday, points: 8),
        DailyScore(date: DateTime(2026, 5, 18), points: 99), // futur
      ];
      expect(useCase(history: history, referenceDate: sunday), 8);
    });

    test('normalise les dates avec composante horaire', () {
      final history = [
        DailyScore(date: DateTime(2026, 5, 17, 23, 59), points: 4),
      ];
      expect(
        useCase(history: history, referenceDate: DateTime(2026, 5, 17, 6)),
        4,
      );
    });
  });
}
