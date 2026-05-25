import 'package:equatable/equatable.dart';

/// Score journalier brut — points gagnés sur une journée calendaire.
///
/// Utilisé par [ComputeWeeklyScoreUseCase] pour agréger le total hebdomadaire.
class DailyScore extends Equatable {
  final DateTime date;
  final int points;

  const DailyScore({required this.date, required this.points});

  @override
  List<Object?> get props => [date, points];
}
