import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';

class UpdateCategoryUseCase {
  final CategoryRepository _repository;
  const UpdateCategoryUseCase(this._repository);

  Future<Category> call(Category category) =>
      _repository.updateCategory(category);
}
