import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class GetCategoriesUseCase {
  final CategoryRepository _repository;
  const GetCategoriesUseCase(this._repository);

  Future<List<Category>> call(UserId userId) =>
      _repository.getCategories(userId);
}
