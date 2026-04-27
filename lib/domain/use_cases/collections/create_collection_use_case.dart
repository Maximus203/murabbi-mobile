import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class CreateCollectionUseCase {
  final CollectionRepository _repository;
  const CreateCollectionUseCase(this._repository);

  Future<Collection> call({
    required UserId userId,
    required Collection collection,
  }) => _repository.createCollection(userId: userId, collection: collection);
}
