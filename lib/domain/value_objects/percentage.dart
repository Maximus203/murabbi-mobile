import 'package:equatable/equatable.dart';

class Percentage extends Equatable {
  final double value;

  Percentage(this.value) {
    if (value < 0.0 || value > 1.0) {
      throw ArgumentError.value(
        value,
        'value',
        'Percentage must be between 0.0 and 1.0',
      );
    }
  }

  @override
  List<Object?> get props => [value];
}
