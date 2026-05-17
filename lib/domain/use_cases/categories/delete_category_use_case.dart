import 'package:murabbi_mobile/domain/repositories/category_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';

class DeleteCategoryUseCase {
  final CategoryRepository _repository;
  const DeleteCategoryUseCase(this._repository);

  Future<void> call(CategoryId categoryId) =>
      _repository.deleteCategory(categoryId);
}
