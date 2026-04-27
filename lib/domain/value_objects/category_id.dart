import 'package:equatable/equatable.dart';

class CategoryId extends Equatable {
  final String value;

  CategoryId(String value) : value = value {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'CategoryId cannot be empty');
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
