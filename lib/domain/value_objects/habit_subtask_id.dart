import 'package:equatable/equatable.dart';

class HabitSubtaskId extends Equatable {
  final String value;

  const HabitSubtaskId._(this.value);

  factory HabitSubtaskId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'HabitSubtaskId cannot be empty',
      );
    }
    return HabitSubtaskId._(trimmed);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
