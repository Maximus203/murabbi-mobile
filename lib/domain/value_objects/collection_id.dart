import 'package:equatable/equatable.dart';

class CollectionId extends Equatable {
  final String value;

  const CollectionId._(this.value);

  factory CollectionId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'value', 'CollectionId cannot be empty');
    }
    return CollectionId._(trimmed);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
