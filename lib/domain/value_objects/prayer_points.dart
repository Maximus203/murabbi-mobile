import 'package:equatable/equatable.dart';

class PrayerPoints extends Equatable {
  static const int min = 0;
  static const int max = 3;

  final int value;

  PrayerPoints(this.value) {
    if (value < min || value > max) {
      throw ArgumentError.value(
        value,
        'value',
        'PrayerPoints must be between $min and $max',
      );
    }
  }

  @override
  List<Object?> get props => [value];
}
