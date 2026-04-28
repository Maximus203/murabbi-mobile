import 'package:equatable/equatable.dart';

class CategoryId extends Equatable {
  final String value;

  const CategoryId._(this.value);

  factory CategoryId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'value', 'CategoryId cannot be empty');
    }
    return CategoryId._(trimmed);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
