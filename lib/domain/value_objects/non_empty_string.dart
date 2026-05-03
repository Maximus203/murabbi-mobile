import 'package:equatable/equatable.dart';

class NonEmptyString extends Equatable {
  final String value;

  NonEmptyString(String raw) : value = raw.trim() {
    if (value.isEmpty) {
      throw ArgumentError.value(raw, 'value', 'NonEmptyString cannot be empty');
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
