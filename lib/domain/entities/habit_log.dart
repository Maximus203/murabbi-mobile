import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';

enum HabitLogStatus { done, late, missed }

class HabitLog extends Equatable {
  final HabitId habitId;
  final DateTime date;
  final HabitLogStatus status;

  const HabitLog({
    required this.habitId,
    required this.date,
    required this.status,
  });

  @override
  List<Object?> get props => [habitId, date, status];
}
