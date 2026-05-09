import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';

enum HabitLogStatus { onTime, late, missed }

/// Log quotidien d'exécution d'une habitude.
///
/// Champs v1.5 (spec § 2.3) :
/// - [actualValue] : valeur effectivement atteinte (NULL si pas d'objectif).
/// - [targetReached] : objectif atteint ou non — calculé côté SQL via colonne
///   GENERATED, hydraté ici par le repository à la lecture.
/// - [subtasksCompleted] : UUIDs des sous-tâches cochées au moment du log.
/// - [duration] : durée mesurée par le timer (max 24h, cf. spec § 2.4).
/// - [openedAt] / [loggedAt] : horodatages session (analytics — alimentent
///   `vw_engagement_headline.avg_session_seconds`).
class HabitLog extends Equatable {
  static const Duration durationMax = Duration(seconds: 86400);

  final HabitId habitId;
  final DateTime date;
  final HabitLogStatus status;
  final int? actualValue;
  final bool? targetReached;
  final List<HabitSubtaskId> subtasksCompleted;
  final Duration? duration;

  /// Moment d'ouverture du formulaire de logging (démarrage du timer
  /// "session"). NULL si la saisie a été faite en 1-tap depuis la heatmap
  /// ou pour les logs antérieurs à l'introduction du timer.
  final DateTime? openedAt;

  /// Moment de la validation définitive (tap "Valider" ou "Marquer comme
  /// fait"). NULL pour les logs migrés depuis l'ancien schéma sans cette
  /// granularité. Quand non-null, alimente la métrique
  /// `vw_engagement_headline.avg_session_seconds = avg(logged_at - opened_at)`.
  final DateTime? loggedAt;

  HabitLog({
    required this.habitId,
    required this.date,
    required this.status,
    this.actualValue,
    this.targetReached,
    this.subtasksCompleted = const [],
    this.duration,
    this.openedAt,
    this.loggedAt,
  }) {
    if (actualValue != null && actualValue! < 0) {
      throw ArgumentError.value(
        actualValue,
        'actualValue',
        'HabitLog.actualValue must be >= 0 (spec v1.5 § 8.2)',
      );
    }
    if (targetReached != null && actualValue == null) {
      throw ArgumentError(
        'HabitLog.targetReached requires actualValue to be set',
      );
    }
    if (duration != null) {
      if (duration!.isNegative) {
        throw ArgumentError.value(
          duration,
          'duration',
          'HabitLog.duration must be non-negative',
        );
      }
      if (duration! > durationMax) {
        throw ArgumentError.value(
          duration,
          'duration',
          'HabitLog.duration must be <= 24h (spec v1.5 § 2.4)',
        );
      }
    }
    if (openedAt != null && loggedAt != null && loggedAt!.isBefore(openedAt!)) {
      throw ArgumentError(
        'HabitLog.loggedAt must be >= openedAt when both are set',
      );
    }
  }

  @override
  List<Object?> get props => [
    habitId,
    date,
    status,
    actualValue,
    targetReached,
    subtasksCompleted,
    duration,
    openedAt,
    loggedAt,
  ];
}
