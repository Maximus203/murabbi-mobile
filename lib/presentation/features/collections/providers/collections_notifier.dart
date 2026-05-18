import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

/// Provider du notifier Collections — exposé en `AsyncNotifierProvider` legacy
/// (cf. ADR-016 : 100% providers manuels, pas de codegen `@riverpod`).
final collectionsNotifierProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
      CollectionsNotifier.new,
    );

/// Notifier gérant la liste des [Collection] de l'utilisateur courant.
///
/// - `build` : charge via [CollectionRepository.getCollections].
/// - `activate` / `deactivate` : mutations optimistes avec refresh.
/// - `create` : création et refresh.
///
/// Si l'utilisateur n'est pas authentifié, retourne une liste vide.
class CollectionsNotifier extends AsyncNotifier<List<Collection>> {
  @override
  Future<List<Collection>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.read(collectionRepositoryProvider).getCollections(user.id);
  }

  /// Active la collection identifiée par [id] pour l'utilisateur courant.
  Future<void> activate(CollectionId id) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref
        .read(collectionRepositoryProvider)
        .activateCollection(userId: user.id, collectionId: id);
    ref.invalidateSelf();
    await future;
  }

  /// Désactive la collection identifiée par [id] pour l'utilisateur courant.
  Future<void> deactivate(CollectionId id) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref
        .read(collectionRepositoryProvider)
        .deactivateCollection(userId: user.id, collectionId: id);
    ref.invalidateSelf();
    await future;
  }

  /// Crée une nouvelle [collection] pour l'utilisateur courant et rafraîchit.
  Future<void> create(Collection collection) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref
        .read(collectionRepositoryProvider)
        .createCollection(userId: user.id, collection: collection);
    ref.invalidateSelf();
    await future;
  }
}
