import 'package:equatable/equatable.dart';

/// Email validé côté domaine. Normalise en lowercase pour que la comparaison
/// d'unicité côté Supabase ne dépende pas de la casse saisie.
class EmailAddress extends Equatable {
  final String value;

  EmailAddress(String raw) : value = raw.trim().toLowerCase() {
    if (value.isEmpty) {
      throw ArgumentError.value(raw, 'value', 'EmailAddress cannot be empty');
    }
    if (!_pattern.hasMatch(value)) {
      throw ArgumentError.value(raw, 'value', 'EmailAddress is malformed');
    }
  }

  static final RegExp _pattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
