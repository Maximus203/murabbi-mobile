import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class ActivateCollectionUseCase {
  final CollectionRepository _repository;
  const ActivateCollectionUseCase(this._repository);

  Future<void> call({
    required UserId userId,
    required CollectionId collectionId,
  }) => _repository.activateCollection(
    userId: userId,
    collectionId: collectionId,
  );
}
