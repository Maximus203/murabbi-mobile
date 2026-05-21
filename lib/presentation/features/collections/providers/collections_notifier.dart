import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/activate_collection_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/create_collection_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/deactivate_collection_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/get_collections_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

/// Use cases collections exposés via Riverpod (issue #6, Phase 5).
final getCollectionsUseCaseProvider = Provider<GetCollectionsUseCase>((ref) {
  return GetCollectionsUseCase(ref.watch(collectionRepositoryProvider));
});

final activateCollectionUseCaseProvider = Provider<ActivateCollectionUseCase>((
  ref,
) {
  return ActivateCollectionUseCase(ref.watch(collectionRepositoryProvider));
});

final deactivateCollectionUseCaseProvider =
    Provider<DeactivateCollectionUseCase>((ref) {
      return DeactivateCollectionUseCase(
        ref.watch(collectionRepositoryProvider),
      );
    });

final createCollectionUseCaseProvider = Provider<CreateCollectionUseCase>((
  ref,
) {
  return CreateCollectionUseCase(ref.watch(collectionRepositoryProvider));
});

/// Liste des collections visibles par l'utilisateur connecté — alimente
/// CO-01. État `AsyncNotifier` pour exposer activation / création.
class CollectionsNotifier extends AsyncNotifier<List<Collection>> {
  @override
  Future<List<Collection>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    final getCollections = ref.watch(getCollectionsUseCaseProvider);
    return getCollections(user.id);
  }

  /// Active une collection système puis recharge la liste.
  Future<void> activate(CollectionId collectionId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(activateCollectionUseCaseProvider)(
        userId: user.id,
        collectionId: collectionId,
      );
      return ref.read(getCollectionsUseCaseProvider)(user.id);
    });
  }

  /// Désactive une collection pour l'utilisateur connecté puis recharge la liste.
  Future<void> deactivate(CollectionId collectionId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(deactivateCollectionUseCaseProvider)(
        userId: user.id,
        collectionId: collectionId,
      );
      return ref.read(getCollectionsUseCaseProvider)(user.id);
    });
  }

  /// Crée une nouvelle collection utilisateur puis recharge la liste.
  Future<void> create(Collection collection) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(createCollectionUseCaseProvider)(
        userId: user.id,
        collection: collection,
      );
      return ref.read(getCollectionsUseCaseProvider)(user.id);
    });
  }
}

final collectionsNotifierProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
      CollectionsNotifier.new,
    );
