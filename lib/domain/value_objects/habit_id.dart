import 'package:equatable/equatable.dart';

class HabitId extends Equatable {
  final String value;

  const HabitId._(this.value);

  factory HabitId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'HabitId cannot be empty');
    }
    return HabitId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
