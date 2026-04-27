import 'package:equatable/equatable.dart';

class UserId extends Equatable {
  final String value;

  UserId(String value) : value = value {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'UserId cannot be empty');
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
