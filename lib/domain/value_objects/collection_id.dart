import 'package:equatable/equatable.dart';

class CollectionId extends Equatable {
  final String value;

  const CollectionId._(this.value);

  factory CollectionId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'CollectionId cannot be empty');
    }
    return CollectionId._(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
