import 'package:equatable/equatable.dart';

/// Password validé côté domaine. Pas de trim : un espace est un caractère
/// légitime du secret. `toString()` ne fuite jamais la valeur (sécurité logs).
class Password extends Equatable {
  static const int minLength = 8;

  final String value;

  Password(this.value) {
    if (value.length < minLength) {
      throw ArgumentError.value(
        '***',
        'value',
        'Password must be at least $minLength characters',
      );
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'Password(***)';
}
