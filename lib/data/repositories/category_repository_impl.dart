import 'package:murabbi_mobile/data/datasources/category_data_source.dart';
import 'package:murabbi_mobile/data/mappers/category_mapper.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
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
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDataSource _ds;

  const CategoryRepositoryImpl(this._ds);

  @override
  Future<List<Category>> getCategories(UserId userId) async {
    final rows = await _ds.getCategories(userId.value);
    return rows.map(CategoryMapper.fromRow).toList(growable: false);
  }

  @override
  Future<Category> createCategory({
    required UserId userId,
    required Category category,
  }) async {
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
}
