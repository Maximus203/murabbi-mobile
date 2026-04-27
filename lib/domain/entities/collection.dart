import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

class Collection extends Equatable {
  final CollectionId id;
  final NonEmptyString name;
  final NonEmptyString description;
  final List<HabitId> habitIds;
  final bool isSystem;
  final bool isActive;

  Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.habitIds,
    required this.isSystem,
    required this.isActive,
  }) {
    if (habitIds.isEmpty) {
      throw ArgumentError.value(
        habitIds,
        'habitIds',
        'Collection must contain at least one habit',
      );
    }
  }

  @override
  List<Object?> get props => [id, name, description, habitIds, isSystem, isActive];
}
