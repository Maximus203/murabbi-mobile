import 'package:equatable/equatable.dart';

class CollectionId extends Equatable {
  final String value;

  CollectionId(String value) : value = value {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'CollectionId cannot be empty',
      );
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
