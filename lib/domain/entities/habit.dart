import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

enum HabitTimeRange { morning, afternoon, evening, anytime }

/// How often a habit recurs. Determines how `frequency` and `activeDays` are
/// interpreted: perWeek/weekly use day-of-week (1=Mon, 7=Sun); monthly uses
/// day-of-month (1–31); custom is user-defined.
enum HabitFrequencyType { daily, perDay, perWeek, weekly, monthly, custom }

class Habit extends Equatable {
  final HabitId id;
  final NonEmptyString name;
  final CategoryId categoryId;
  final HabitFrequencyType frequencyType;
  final int frequency;
  final HabitTimeRange timeRange;
  final Set<int> activeDays;
  final HabitPoints points;
  final bool isSystem;

  Habit({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.frequencyType,
    required this.frequency,
    required this.timeRange,
    required this.activeDays,
    required this.points,
    required this.isSystem,
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
  }

  @override
  List<Object?> get props => [
    id,
    name,
    categoryId,
    frequencyType,
    frequency,
    timeRange,
    activeDays,
    points,
    isSystem,
  ];
}
