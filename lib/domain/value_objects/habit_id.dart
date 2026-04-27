import 'package:equatable/equatable.dart';

class HabitId extends Equatable {
  final String value;

  HabitId(String value) : value = value {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'HabitId cannot be empty');
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
