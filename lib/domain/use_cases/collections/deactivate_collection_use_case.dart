import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Désactive une collection pour un utilisateur (toggle actif/inactif).
///
/// Q#22 validée par le PO : `deactivateCollection` est symétrique de
/// `activateCollection`. Ne supprime pas les habitudes — l'utilisateur
/// peut réactiver la collection ultérieurement.
class DeactivateCollectionUseCase {
  final CollectionRepository _repository;

  const DeactivateCollectionUseCase(this._repository);

  Future<void> call({
    required UserId userId,
    required CollectionId collectionId,
  }) => _repository.deactivateCollection(
    userId: userId,
    collectionId: collectionId,
  );
}
