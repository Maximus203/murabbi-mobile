import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

/// Sous-tâche d'une habitude (spec v1.5 § 2.2).
///
/// Limites métier :
/// - `title` : 1..120 caractères (post-trim de [NonEmptyString]).
/// - `orderIndex` : entier >= 0, unicité `(habitId, orderIndex)` à enforcer
///   au niveau data layer (contrainte SQL `idx_habit_subtasks_order`).
/// - Une habitude porte au plus 15 sous-tâches — invariant collection,
///   vérifié sur `Habit.subtasks` lors de la construction.
class HabitSubtask extends Equatable {
  static const int titleMaxLength = 120;

  final HabitSubtaskId id;
  final HabitId habitId;
  final NonEmptyString title;
  final int orderIndex;

  HabitSubtask({
    required this.id,
    required this.habitId,
    required this.title,
    required this.orderIndex,
  }) {
    if (orderIndex < 0) {
      throw ArgumentError.value(
        orderIndex,
        'orderIndex',
        'HabitSubtask.orderIndex must be >= 0',
      );
    }
    if (title.value.runes.length > titleMaxLength) {
      throw ArgumentError.value(
        title.value,
        'title',
        'HabitSubtask.title must be <= $titleMaxLength chars',
      );
    }
  }

  HabitSubtask copyWith({HabitSubtaskId? id, NonEmptyString? title, int? orderIndex}) {
    return HabitSubtask(
      id: id ?? this.id,
      habitId: habitId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  List<Object?> get props => [id, habitId, title, orderIndex];
}
