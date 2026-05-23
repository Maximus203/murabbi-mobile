import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/domain/value_objects/target_value.dart';
import 'package:murabbi_mobile/domain/value_objects/time_of_day_value.dart';

/// Mapper pur — convertit les rows `habits` Supabase en [Habit] domain et
/// inversement.
///
/// Schéma `habits` consommé (cf. ADR-006 / ADR-008) :
///   `id, user_id, name, category_id, frequency_type, frequency,
///    monthly_day, range_start, range_end, active_days, points, is_system,
///    target_value, target_unit, target_unit_custom, has_timer,
///    subtasks_required, created_at`.
///
/// La composition [HabitTarget] est repliée sur le SQL flat (5 colonnes
/// `target_value`/`target_unit`/`target_unit_custom`/`has_timer`/
/// `subtasks_required`).
///
/// Colonnes optionnelles gérées `null` : `monthly_day`, `range_start`,
/// `range_end`, `target_value`, `target_unit`, `target_unit_custom`.
class HabitMapper {
  const HabitMapper._();

  /// SQL row → entité domain.
  ///
  /// [subtasks] est injecté par le repository (les sous-tâches vivent dans
  /// une table séparée `habit_subtasks`).
  static Habit fromRow(Map<String, dynamic> row) {
    final activeDaysRaw = row['active_days'] as List<dynamic>?;

    return Habit(
      id: HabitId(row['id'] as String),
      name: NonEmptyString(row['name'] as String),
      categoryId: CategoryId(row['category_id'] as String),
      frequencyType: _frequencyFromSql(row['frequency_type'] as String),
      frequency: row['frequency'] as int,
      monthlyDay: row['monthly_day'] as int?,
      rangeStart: _timeFromSql(row['range_start']),
      rangeEnd: _timeFromSql(row['range_end']),
      activeDays:
          activeDaysRaw?.map((e) => e as int).toSet() ??
          const {1, 2, 3, 4, 5, 6, 7},
      points: row['points'] != null ? HabitPoints(row['points'] as int) : null,
      isSystem: (row['is_system'] as bool?) ?? false,
      target: _targetFromRow(row),
      subtasksAllRequired: (row['subtasks_required'] as bool?) ?? false,
    );
  }

  /// Entité domain → SQL row (sans `subtasks`, persistés séparément).
  ///
  /// La clé `'points'` est omise si `habit.points == null` (habitude user sans
  /// points fixés) — on n'envoie pas `null` au backend pour éviter d'écraser
  /// une valeur existante ou de violer une contrainte NOT NULL côté admin
  /// (#163, companion admin #113).
  static Map<String, dynamic> toRow(Habit habit) {
    final target = habit.target;
    final row = <String, dynamic>{
      'id': habit.id.value,
      'name': habit.name.value,
      'category_id': habit.categoryId.value,
      'frequency_type': _frequencyToSql(habit.frequencyType),
      'frequency': habit.frequency,
      'monthly_day': habit.monthlyDay,
      'range_start': _timeToSql(habit.rangeStart),
      'range_end': _timeToSql(habit.rangeEnd),
      'active_days': habit.activeDays.toList()..sort(),
      'is_system': habit.isSystem,
      'target_value': switch (target) {
        HabitTargetNone() => null,
        HabitTargetValue(:final value) => value.value,
        HabitTargetTimed(:final value) => value.value,
      },
      'target_unit': switch (target) {
        HabitTargetNone() => null,
        HabitTargetValue(:final unit) => unit.name,
        HabitTargetTimed(:final unit) => unit.name,
      },
      'target_unit_custom': switch (target) {
        HabitTargetValue(:final customLabel) => customLabel,
        _ => null,
      },
      'has_timer': target.hasTimer,
      'subtasks_required': habit.subtasksAllRequired,
    };
    // #163 : n'envoyer la clé 'points' que si elle est non-null.
    if (habit.points != null) {
      row['points'] = habit.points!.value;
    }
    return row;
  }

  static HabitTarget _targetFromRow(Map<String, dynamic> row) {
    final rawValue = row['target_value'] as int?;
    final rawUnit = row['target_unit'] as String?;
    if (rawValue == null || rawUnit == null) {
      return const HabitTarget.none();
    }
    final value = TargetValue(rawValue);
    final unit = TargetUnit.parse(rawUnit);
    final hasTimer = (row['has_timer'] as bool?) ?? false;
    if (hasTimer) {
      return HabitTarget.timed(value: value, unit: unit);
    }
    return HabitTarget.value(
      value: value,
      unit: unit,
      customLabel: row['target_unit_custom'] as String?,
    );
  }

  static HabitFrequencyType _frequencyFromSql(String raw) {
    for (final type in HabitFrequencyType.values) {
      if (type.name == raw) return type;
    }
    throw ArgumentError.value(raw, 'frequency_type', 'Unknown frequency type');
  }

  static String _frequencyToSql(HabitFrequencyType type) => type.name;

  static TimeOfDayValue? _timeFromSql(Object? raw) {
    if (raw == null) return null;
    if (raw is! String || raw.isEmpty) {
      throw ArgumentError.value(raw, 'time', 'must be HH:MM or null');
    }
    final parts = raw.split(':');
    if (parts.length < 2) {
      throw ArgumentError.value(raw, 'time', 'must be HH:MM');
    }
    return TimeOfDayValue(int.parse(parts[0]), int.parse(parts[1]));
  }

  static String? _timeToSql(TimeOfDayValue? time) {
    if (time == null) return null;
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
