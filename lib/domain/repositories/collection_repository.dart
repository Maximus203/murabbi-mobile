import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class CollectionRepository {
  Future<List<Collection>> getCollections(UserId userId);
  Future<void> activateCollection({
    required UserId userId,
    required CollectionId collectionId,
  });
  Future<Collection> createCollection({
    required UserId userId,
    required Collection collection,
  });
}
