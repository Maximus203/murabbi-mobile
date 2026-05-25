import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> getCategories(UserId userId);
  Future<Category> createCategory({
    required UserId userId,
    required Category category,
  });

  /// Met à jour une catégorie existante et retourne sa version persistée.
  Future<Category> updateCategory(Category category);

  /// Supprime la catégorie identifiée par [categoryId].
  Future<void> deleteCategory(CategoryId categoryId);

  /// Retourne la catégorie système dont le [slug] correspond (ex. `"religion"`).
  ///
  /// Lance [CategoryNotFoundFailure] si aucune catégorie ne porte ce slug.
  /// Utilisé pour découpler le code mobile des UUIDs Supabase (Q-21 — Option B).
  Future<Category> getCategoryBySlug(UserId userId, String slug);
}
