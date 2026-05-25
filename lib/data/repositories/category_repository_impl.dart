import 'package:murabbi_mobile/core/network/current_user_id_resolver.dart';
import 'package:murabbi_mobile/core/utils/ownership_guard.dart';
import 'package:murabbi_mobile/data/datasources/category_data_source.dart';
import 'package:murabbi_mobile/data/mappers/category_mapper.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/errors/category_failure.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Implémentation Supabase du [CategoryRepository] — délègue à un
/// [CategoryDataSource] et passe par [CategoryMapper] pour la sérialisation.
///
/// La protection « interdiction de supprimer une catégorie système » est
/// portée par la RLS Supabase (`is_system = true` ⇒ DELETE refusé) : le
/// repository reste un wrapper thin et laisse la base trancher, comme
/// `InMemoryCategoryRepository`.
class CategoryRepositoryImpl with OwnershipGuard implements CategoryRepository {
  final CategoryDataSource _ds;

  /// Resolver d'`userId` courant (issue #202 / M3) — utilisé par
  /// [OwnershipGuard] pour valider l'ownership avant tout appel réseau.
  final CurrentUserIdResolver _currentUserIdResolver;

  const CategoryRepositoryImpl(
    this._ds, {
    required CurrentUserIdResolver currentUserIdResolver,
  }) : _currentUserIdResolver = currentUserIdResolver;

  Future<void> _guardOwnership(UserId userId) async {
    final currentId = await _currentUserIdResolver.currentUserId();
    assertOwnership(
      requestedId: userId.value,
      currentId: currentId,
      failureIfMismatch: const CategoryFailure.unauthorized(),
    );
  }

  @override
  Future<List<Category>> getCategories(UserId userId) async {
    await _guardOwnership(userId);
    final rows = await _ds.getCategories(userId.value);
    return rows.map(CategoryMapper.fromRow).toList(growable: false);
  }

  @override
  Future<Category> createCategory({
    required UserId userId,
    required Category category,
  }) async {
    await _guardOwnership(userId);
    final row = CategoryMapper.toRow(category)..['user_id'] = userId.value;
    final created = await _ds.createCategory(row);
    return CategoryMapper.fromRow(created);
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final updated = await _ds.updateCategory(CategoryMapper.toRow(category));
    return CategoryMapper.fromRow(updated);
  }

  @override
  Future<void> deleteCategory(CategoryId categoryId) {
    return _ds.deleteCategory(categoryId.value);
  }

  @override
  Future<Category> getCategoryBySlug(UserId userId, String slug) async {
    await _guardOwnership(userId);
    final row = await _ds.getCategoryBySlug(userId.value, slug);
    if (row == null) {
      throw CategoryFailure.notFound(message: 'No category with slug "$slug"');
    }
    return CategoryMapper.fromRow(row);
  }
}
