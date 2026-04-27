import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class GetCollectionsUseCase {
  final CollectionRepository _repository;
  const GetCollectionsUseCase(this._repository);

  Future<List<Collection>> call(UserId userId) =>
      _repository.getCollections(userId);
}
