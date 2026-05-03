import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> getCategories(UserId userId);
  Future<Category> createCategory({
    required UserId userId,
    required Category category,
  });
}
