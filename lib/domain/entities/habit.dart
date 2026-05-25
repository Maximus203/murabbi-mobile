import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/time_of_day_value.dart';

/// Mode de récurrence d'une habitude.
///
/// - `daily` : tous les jours (`activeDays` = 1..7)
/// - `perDay` : X fois par jour (`frequency` = X)
/// - `perWeek` : X fois par semaine (`frequency` = X, `activeDays` = jours actifs 1-7)
/// - `weekly` : jours précis de la semaine (`activeDays` ⊆ 1..7)
/// - `monthly` : un jour précis du mois (`monthlyDay` ∈ 1..31)
/// - `custom` : règle libre côté utilisateur
///
/// Cf. ADR-006 pour le mapping vers le schema Supabase (data layer Phase 4).
enum HabitFrequencyType { daily, perDay, perWeek, weekly, monthly, custom }

class Habit extends Equatable {
  final HabitId id;
  final NonEmptyString name;
  final CategoryId categoryId;
  final HabitFrequencyType frequencyType;
  final int frequency;

  /// Jour du mois (1-31), requis ssi `frequencyType == monthly`.
  final int? monthlyDay;

  /// Début de la plage horaire pour les notifications (P-7).
  /// `null` ⇔ `rangeEnd == null` ⇔ "anytime".
  /// Cf. ADR-007.
  final TimeOfDayValue? rangeStart;

  /// Fin de la plage horaire. Doit être strictement > rangeStart.
  final TimeOfDayValue? rangeEnd;

  final Set<int> activeDays;

  /// Points attribués à la complétion de l'habitude.
  ///
  /// `null` pour les habitudes utilisateur (`is_system = false`) qui n'ont pas
  /// de points fixés — le scoring utilise alors `category.pointsPerCompletion`
  /// comme fallback (cf. #163, ADR-006).
  final HabitPoints? points;
  final bool isSystem;

  /// Objectif chiffré et/ou timer (composition v1.5, ADR-008).
  final HabitTarget target;

  /// Sous-tâches associées (max 15, spec v1.5 § 2.4).
  /// L'unicité `(habitId, orderIndex)` est vérifiée à la construction.
  final List<HabitSubtask> subtasks;

  /// Si vrai, la validation de l'habitude requiert que **toutes** les
  /// sous-tâches soient cochées (cf. spec v1.5 § 3.1, scoring § 3.2).
  /// Implique `subtasks.isNotEmpty`.
  final bool subtasksAllRequired;

  static const int subtasksMaxCount = 15;

  Habit({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.frequencyType,
    required this.frequency,
    required this.activeDays,
    this.points,
    required this.isSystem,
    this.monthlyDay,
    this.rangeStart,
    this.rangeEnd,
    this.target = const HabitTarget.none(),
    this.subtasks = const [],
    this.subtasksAllRequired = false,
  }) {
    if (frequency <= 0) {
      throw ArgumentError.value(
        frequency,
        'frequency',
        'Habit frequency must be positive',
      );
    }
    if (activeDays.isEmpty) {
      throw ArgumentError.value(
        activeDays,
        'activeDays',
        'Habit must have at least one active day',
      );
    }

    if (frequencyType == HabitFrequencyType.monthly) {
      if (monthlyDay == null || monthlyDay! < 1 || monthlyDay! > 31) {
        throw ArgumentError.value(
          monthlyDay,
          'monthlyDay',
          'Habit monthly requires monthlyDay in [1..31]',
        );
      }
    } else if (monthlyDay != null) {
      throw ArgumentError.value(
        monthlyDay,
        'monthlyDay',
        'Habit monthlyDay is only valid when frequencyType == monthly',
      );
    }

    if ((rangeStart == null) != (rangeEnd == null)) {
      throw ArgumentError(
        'Habit rangeStart and rangeEnd must both be null or both non-null',
      );
    }
    if (rangeStart != null && !rangeStart!.isBefore(rangeEnd!)) {
      throw ArgumentError(
        'Habit rangeEnd must be strictly after rangeStart (no minuit wrap, ADR-007)',
      );
    }

    if (subtasks.length > subtasksMaxCount) {
      throw ArgumentError.value(
        subtasks.length,
        'subtasks.length',
        'Habit allows at most $subtasksMaxCount subtasks (spec v1.5 § 2.4)',
      );
    }
    final seenOrder = <int>{};
    for (final s in subtasks) {
      if (s.habitId != id) {
        throw ArgumentError.value(
          s.habitId,
          'subtask.habitId',
          'HabitSubtask.habitId must match the parent Habit.id',
        );
      }
      if (!seenOrder.add(s.orderIndex)) {
        throw ArgumentError.value(
          s.orderIndex,
          'subtask.orderIndex',
          'Habit.subtasks orderIndex must be unique',
        );
      }
    }
    if (subtasksAllRequired && subtasks.isEmpty) {
      throw ArgumentError(
        'Habit.subtasksAllRequired=true requires at least one subtask',
      );
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    categoryId,
    frequencyType,
    frequency,
    monthlyDay,
    rangeStart,
    rangeEnd,
    activeDays,
    points, // nullable : null = habitude user sans points fixés (#163)
    isSystem,
    target,
    subtasks,
    subtasksAllRequired,
  ];
}
