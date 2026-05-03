import 'package:equatable/equatable.dart';

class UserId extends Equatable {
  final String value;

  const UserId._(this.value);

  factory UserId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'value', 'UserId cannot be empty');
    }
    return UserId._(trimmed);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
