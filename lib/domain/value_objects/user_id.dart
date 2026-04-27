import 'package:equatable/equatable.dart';

class UserId extends Equatable {
  final String value;

  const UserId._(this.value);

  factory UserId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'UserId cannot be empty');
    }
    return UserId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
