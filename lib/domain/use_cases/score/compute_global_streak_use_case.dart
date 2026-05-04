import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';

/// Score quotidien (date normalisée + total de points).
class DailyScore extends Equatable {
  final DateTime date;
  final int points;

  const DailyScore({required this.date, required this.points});

  @override
  List<Object?> get props => [date, points];
}

/// Q-17 verrouillée — option C : streak global = jours consécutifs où
/// `dailyPoints >= level.dailyGoal`, comptés à rebours depuis [referenceDate].
///
/// Cas particuliers (cf. issue #9 commentaire Q-17) :
/// - Pas d'historique ou jour de référence < goal → streak = 0
/// - Trou dans l'historique → break (pas de « jour off » en V1)
/// - Changement de niveau → on évalue avec le **nouveau** dailyGoal partout
class ComputeGlobalStreakUseCase {
  const ComputeGlobalStreakUseCase();

  int call({
    required List<DailyScore> history,
    required DateTime referenceDate,
    required Level level,
  }) {
    if (history.isEmpty) return 0;

    final goal = level.dailyGoal;
    final byDay = <DateTime, int>{
      for (final s in history) _normalize(s.date): s.points,
    };

    var streak = 0;
    var cursor = _normalize(referenceDate);
    while (true) {
      final pts = byDay[cursor];
      if (pts == null || pts < goal) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
