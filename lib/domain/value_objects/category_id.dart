import 'package:equatable/equatable.dart';

class CategoryId extends Equatable {
  final String value;

  const CategoryId._(this.value);

  factory CategoryId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'CategoryId cannot be empty');
    }
    return CategoryId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
