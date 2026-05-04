import 'package:equatable/equatable.dart';

/// Valeur cible d'un objectif chiffré : entier strict dans [1..9999].
/// Borne haute issue de la spec v1.5 § 2.4.
class TargetValue extends Equatable {
  static const int min = 1;
  static const int max = 9999;

  final int value;

  TargetValue(this.value) {
    if (value < min || value > max) {
      throw ArgumentError.value(
        value,
        'value',
        'TargetValue must be between $min and $max',
      );
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => '$value';
}
