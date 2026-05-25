import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

/// Mapper pur — convertit les rows `categories` Supabase en [Category] domain
/// et inversement.
///
/// Schéma `categories` consommé : `id, user_id, name, color, icon, is_system`.
/// `user_id` est NULL pour les catégories système (cf. ADR-009).
class CategoryMapper {
  const CategoryMapper._();

  /// SQL row → entité domain.
  static Category fromRow(Map<String, dynamic> row) {
    return Category(
      id: CategoryId(row['id'] as String),
      name: NonEmptyString(row['name'] as String),
      color: HexColor(row['color'] as String),
      icon: row['icon'] as String,
      isSystem: (row['is_system'] as bool?) ?? false,
      slug: row['slug'] as String?,
    );
  }

  /// Entité domain → SQL row (clés alignées sur le schéma `categories`).
  ///
  /// `slug` est omis de la row quand null pour éviter d'écraser la valeur
  /// existante en base (upsert safe).
  static Map<String, dynamic> toRow(Category category) {
    return {
      'id': category.id.value,
      'name': category.name.value,
      'color': category.color.value,
      'icon': category.icon,
      'is_system': category.isSystem,
      if (category.slug != null) 'slug': category.slug,
    };
  }
}
