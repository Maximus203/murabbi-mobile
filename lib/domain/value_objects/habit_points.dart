import 'package:equatable/equatable.dart';

class HabitPoints extends Equatable {
  static const int min = 1;
  static const int max = 10;

  final int value;

  HabitPoints(this.value) {
    if (value < min || value > max) {
      throw ArgumentError.value(
        value,
        'value',
        'HabitPoints must be between $min and $max',
      );
    }
  }

  @override
  List<Object?> get props => [value];
}
