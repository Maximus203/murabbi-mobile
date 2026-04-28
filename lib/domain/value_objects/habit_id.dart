import 'package:equatable/equatable.dart';

class HabitId extends Equatable {
  final String value;

  const HabitId._(this.value);

  factory HabitId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'value', 'HabitId cannot be empty');
    }
    return HabitId._(trimmed);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
