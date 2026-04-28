import 'package:equatable/equatable.dart';
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
  final HabitPoints points;
  final bool isSystem;

  Habit({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.frequencyType,
    required this.frequency,
    required this.activeDays,
    required this.points,
    required this.isSystem,
    this.monthlyDay,
    this.rangeStart,
    this.rangeEnd,
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
    points,
    isSystem,
  ];
}
