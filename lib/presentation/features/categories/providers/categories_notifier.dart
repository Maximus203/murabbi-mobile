import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/use_cases/categories/create_category_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/categories/delete_category_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/categories/get_categories_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/categories/update_category_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

/// Use case providers Categories (issue #150 — HB-03/HB-04).
final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  return GetCategoriesUseCase(ref.watch(categoryRepositoryProvider));
});

final createCategoryUseCaseProvider = Provider<CreateCategoryUseCase>((ref) {
  return CreateCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final updateCategoryUseCaseProvider = Provider<UpdateCategoryUseCase>((ref) {
  return UpdateCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

final deleteCategoryUseCaseProvider = Provider<DeleteCategoryUseCase>((ref) {
  return DeleteCategoryUseCase(ref.watch(categoryRepositoryProvider));
});

/// Notifier des catégories de l'utilisateur courant (HB-03).
///
/// Charge la liste au build, recharge au signin/signout, et expose les
/// mutations create/update/delete. La suppression d'une catégorie système
/// est interdite — garde côté UI doublée d'une garde ici (cf. issue #150,
/// acceptance criteria « catégories système non-supprimables »).
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  UserId _resolveUserId() {
    final user = ref.read(authNotifierProvider).valueOrNull;
    // Les routes catégories sont gardées par auth_redirect ; on retombe
    // sur une valeur synthétique uniquement pour les contextes de test
    // sans session, le repo in-memory n'en dépend pas.
    return user?.id ?? UserId('anonymous');
  }

  @override
  Future<List<Category>> build() async {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final userId = user?.id ?? UserId('anonymous');
    return ref.read(getCategoriesUseCaseProvider).call(userId);
  }

  /// Recharge la liste — pull-to-refresh HB-03.
  ///
  /// Conserve les données affichées pendant le rechargement (pas de spinner
  /// plein écran) — cohérent avec [HabitsNotifier.refresh].
  Future<void> loadCategories() async {
    state = AsyncValue.data(state.valueOrNull ?? const []);
    state = await AsyncValue.guard(
      () => ref.read(getCategoriesUseCaseProvider).call(_resolveUserId()),
    );
  }

  /// Crée une catégorie utilisateur puis recharge la liste.
  Future<void> createCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(createCategoryUseCaseProvider)
          .call(userId: _resolveUserId(), category: category);
      return ref.read(getCategoriesUseCaseProvider).call(_resolveUserId());
    });
  }

  /// Met à jour une catégorie utilisateur puis recharge la liste.
  Future<void> updateCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateCategoryUseCaseProvider).call(category);
      return ref.read(getCategoriesUseCaseProvider).call(_resolveUserId());
    });
  }

  /// Supprime une catégorie utilisateur puis recharge la liste.
  ///
  /// Lève un [StateError] si [categoryId] désigne une catégorie système :
  /// les catégories seed ne sont jamais supprimables (issue #150).
  Future<void> deleteCategory(CategoryId categoryId) async {
    final current = state.valueOrNull ?? const <Category>[];
    final target = current.where((c) => c.id == categoryId);
    if (target.isNotEmpty && target.first.isSystem) {
      throw StateError(
        'Catégorie système non-supprimable: ${categoryId.value}',
      );
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(deleteCategoryUseCaseProvider).call(categoryId);
      return ref.read(getCategoriesUseCaseProvider).call(_resolveUserId());
    });
  }
}

final categoriesNotifierProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
      CategoriesNotifier.new,
    );
