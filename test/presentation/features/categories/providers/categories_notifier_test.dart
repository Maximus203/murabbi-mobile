import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import '../../../../helpers/in_memory_repositories.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo authRepo;

  final testUser = User(
    id: UserId('user-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );

  setUp(() {
    authRepo = _MockAuthRepo();
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => authRepo.getCurrentUser()).thenAnswer((_) async => testUser);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        categoryRepositoryProvider.overrideWithValue(
          InMemoryCategoryRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Category userCategory(String id, String name) => Category(
    id: CategoryId(id),
    name: NonEmptyString(name),
    color: HexColor('#8B6F47'),
    icon: 'star',
    isSystem: false,
  );

  group('CategoriesNotifier', () {
    test('build() charge les catégories système seed', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);
      final list = await container.read(categoriesNotifierProvider.future);
      expect(list, hasLength(5));
      expect(list.every((c) => c.isSystem), isTrue);
    });

    test('createCategory ajoute une catégorie et recharge', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);
      await container.read(categoriesNotifierProvider.future);

      await container
          .read(categoriesNotifierProvider.notifier)
          .createCategory(userCategory('cat-x', 'Lecture'));

      final list = container.read(categoriesNotifierProvider).requireValue;
      expect(list, hasLength(6));
      expect(list.any((c) => c.name.value == 'Lecture'), isTrue);
    });

    test('updateCategory met à jour le nom', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);
      await container.read(categoriesNotifierProvider.future);
      final notifier = container.read(categoriesNotifierProvider.notifier);

      await notifier.createCategory(userCategory('cat-x', 'Lecture'));
      await notifier.updateCategory(userCategory('cat-x', 'Méditation'));

      final list = container.read(categoriesNotifierProvider).requireValue;
      expect(
        list.firstWhere((c) => c.id.value == 'cat-x').name.value,
        'Méditation',
      );
    });

    test('deleteCategory retire une catégorie utilisateur', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);
      await container.read(categoriesNotifierProvider.future);
      final notifier = container.read(categoriesNotifierProvider.notifier);

      await notifier.createCategory(userCategory('cat-x', 'Lecture'));
      await notifier.deleteCategory(CategoryId('cat-x'));

      final list = container.read(categoriesNotifierProvider).requireValue;
      expect(list.any((c) => c.id.value == 'cat-x'), isFalse);
    });

    test('deleteCategory lève une erreur pour une catégorie système', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);
      final seed = await container.read(categoriesNotifierProvider.future);
      final systemId = seed.firstWhere((c) => c.isSystem).id;

      expect(
        () => container
            .read(categoriesNotifierProvider.notifier)
            .deleteCategory(systemId),
        throwsStateError,
      );
    });

    test('loadCategories recharge la liste', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);
      await container.read(categoriesNotifierProvider.future);

      await container
          .read(categoriesNotifierProvider.notifier)
          .loadCategories();

      final list = container.read(categoriesNotifierProvider).requireValue;
      expect(list, hasLength(5));
    });
  });
}
