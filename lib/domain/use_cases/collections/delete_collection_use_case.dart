import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Supprime une collection utilisateur (Q-collections-01 — Option A).
///
/// Ne s'applique qu'aux collections `is_system = false` — la garde est
/// appliquée au niveau datasource (filtre `user_id + is_system = false`) et
/// renforcée par la policy RLS Supabase. L'UI n'expose le bouton de
/// suppression que pour `!collection.isSystem`.
class DeleteCollectionUseCase {
  final CollectionRepository _repository;

  const DeleteCollectionUseCase(this._repository);

  Future<void> call({
    required UserId userId,
    required CollectionId collectionId,
  }) => _repository.deleteCollection(userId: userId, collectionId: collectionId);
}
