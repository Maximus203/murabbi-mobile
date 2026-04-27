import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class CreateCategoryUseCase {
  final CategoryRepository _repository;
  const CreateCategoryUseCase(this._repository);

  Future<Category> call({required UserId userId, required Category category}) =>
      _repository.createCategory(userId: userId, category: category);
}
