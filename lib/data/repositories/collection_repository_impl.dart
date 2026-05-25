import 'package:murabbi_mobile/core/network/current_user_id_resolver.dart';
import 'package:murabbi_mobile/core/utils/ownership_guard.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_collection_data_source.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/errors/collection_failure.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase du [CollectionRepository] — délègue à
/// [SupabaseCollectionDataSource] (migration issue #162 : published_catalog).
///
/// Suit le pattern `PrayerRepositoryImpl` (#149) : les exceptions natives
/// sont traduites en [CollectionFailure] typées, jamais laissées remonter
/// brutes.
///
/// Le contrat de soft-delete (`deleted_at IS NULL`) est appliqué par la
/// policy RLS Supabase côté serveur — le datasource ne filtre pas côté client.
class CollectionRepositoryImpl
    with OwnershipGuard
    implements CollectionRepository {
  final SupabaseCollectionDataSource _ds;

  /// Resolver d'`userId` courant (issue #202 / M3) — utilisé par
  /// [OwnershipGuard] pour valider l'ownership avant tout appel réseau.
  final CurrentUserIdResolver _currentUserIdResolver;

  const CollectionRepositoryImpl(
    this._ds, {
    required CurrentUserIdResolver currentUserIdResolver,
  }) : _currentUserIdResolver = currentUserIdResolver;

  Future<void> _guardOwnership(UserId userId) async {
    final currentId = await _currentUserIdResolver.currentUserId();
    assertOwnership(
      requestedId: userId.value,
      currentId: currentId,
      failureIfMismatch: const CollectionFailure.unauthorized(),
    );
  }

  @override
  Future<List<Collection>> getCollections(UserId userId) => _guard(() async {
    await _guardOwnership(userId);
    return _ds.getCollections(userId);
  });

  @override
  Future<void> activateCollection({
    required UserId userId,
    required CollectionId collectionId,
  }) => _guard(() async {
    await _guardOwnership(userId);
    return _ds.activateCollection(collectionId: collectionId, userId: userId);
  });

  @override
  Future<void> deactivateCollection({
    required UserId userId,
    required CollectionId collectionId,
  }) => _guard(() async {
    await _guardOwnership(userId);
    return _ds.deactivateCollection(collectionId: collectionId, userId: userId);
  });

  @override
  Future<Collection> createCollection({
    required UserId userId,
    required Collection collection,
  }) => _guard(() async {
    await _guardOwnership(userId);
    return _ds.createCollection(collection: collection, userId: userId);
  });

  @override
  Future<List<Map<String, dynamic>>> getHabitsForCollection({
    required CollectionId collectionId,
  }) => _guard(() => _ds.getHabitsForCollection(collectionId.value));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on CollectionFailure {
      rethrow;
    } on sb.PostgrestException catch (e) {
      throw CollectionFailure.database(message: '${e.code ?? ''} ${e.message}');
    } catch (e) {
      throw _translate(e);
    }
  }

  CollectionFailure _translate(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('rate_limit') ||
        msg.contains('rate limit')) {
      return CollectionFailure.network(message: error.toString());
    }
    return CollectionFailure.unknown(message: error.toString());
  }
}
