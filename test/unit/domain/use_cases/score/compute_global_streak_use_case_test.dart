import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_global_streak_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

DailySummary _day(DateTime date, {required bool streakValid}) => DailySummary(
      userId: UserId('u'),
      day: date,
      completionRate: streakValid ? 87.5 : 37.5,
      streakValid: streakValid,
      habitPointsToday: streakValid ? 70 : 30,
    );

void main() {
  late ComputeGlobalStreakUseCase useCase;

  setUp(() => useCase = const ComputeGlobalStreakUseCase());

  final today = DateTime(2026, 5, 25);

  group('ComputeGlobalStreakUseCase (daily_summaries)', () {
    test('liste vide → 0', () {
      expect(useCase(history: [], referenceDate: today), 0);
    });

    test('1 jour valide = aujourd\'hui → 1', () {
      final history = [_day(today, streakValid: true)];
      expect(useCase(history: history, referenceDate: today), 1);
    });

    test('3 jours consécutifs valides → 3', () {
      final history = [
        _day(today, streakValid: true),
        _day(today.subtract(const Duration(days: 1)), streakValid: true),
        _day(today.subtract(const Duration(days: 2)), streakValid: true),
      ];
      expect(useCase(history: history, referenceDate: today), 3);
    });

    test('trou à J-2 : J et J-1 valides, J-2 invalide → 2', () {
      final history = [
        _day(today, streakValid: true),
        _day(today.subtract(const Duration(days: 1)), streakValid: true),
        _day(today.subtract(const Duration(days: 2)), streakValid: false),
        _day(today.subtract(const Duration(days: 3)), streakValid: true),
      ];
      expect(useCase(history: history, referenceDate: today), 2);
    });

    test('aujourd\'hui streakValid=false, J-1 valide → compte J-1 = 1 '
        '(pas de pénalité sur le jour en cours non terminé)', () {
      final history = [
        _day(today, streakValid: false),
        _day(today.subtract(const Duration(days: 1)), streakValid: true),
        _day(today.subtract(const Duration(days: 2)), streakValid: true),
      ];
      // Aujourd'hui n'est pas terminé → le streak démarre à J-1
      expect(useCase(history: history, referenceDate: today), 2);
    });

    test('jour d\'aujourd\'hui absent, J-1 valide → compte depuis J-1', () {
      final history = [
        _day(today.subtract(const Duration(days: 1)), streakValid: true),
        _day(today.subtract(const Duration(days: 2)), streakValid: true),
      ];
      expect(useCase(history: history, referenceDate: today), 2);
    });

    test('tous invalides → 0', () {
      final history = [
        _day(today, streakValid: false),
        _day(today.subtract(const Duration(days: 1)), streakValid: false),
      ];
      expect(useCase(history: history, referenceDate: today), 0);
    });
  });
}
