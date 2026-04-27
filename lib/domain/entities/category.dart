import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

class Category extends Equatable {
  final CategoryId id;
  final NonEmptyString name;
  final String color;
  final String icon;
  final HabitPoints points;
  final bool isSystem;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.points,
    required this.isSystem,
  });

  @override
  List<Object?> get props => [id, name, color, icon, points, isSystem];
}
