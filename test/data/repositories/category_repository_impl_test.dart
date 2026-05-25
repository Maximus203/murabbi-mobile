import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/core/network/current_user_id_resolver.dart';
import 'package:murabbi_mobile/data/datasources/category_data_source.dart';
import 'package:murabbi_mobile/data/mappers/category_mapper.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/errors/category_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class _MockCategoryDataSource extends Mock implements CategoryDataSource {}

class _StubResolver implements CurrentUserIdResolver {
  _StubResolver(this.id);
  String? id;
  @override
  Future<String?> currentUserId() async => id;
}

void main() {
  late _MockCategoryDataSource ds;
  late _StubResolver resolver;
  late CategoryRepositoryImpl repo;

  const userIdValue = '11111111-1111-1111-1111-111111111111';

  Category categoryFixture({String id = 'cat-x', bool isSystem = false}) =>
      Category(
        id: CategoryId(id),
        name: NonEmptyString('Custom'),
        color: HexColor('#ABCDEF'),
        icon: 'star',
        isSystem: isSystem,
      );

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    ds = _MockCategoryDataSource();
    resolver = _StubResolver(userIdValue);
    repo = CategoryRepositoryImpl(ds, currentUserIdResolver: resolver);
  });

  group('getCategories', () {
    test('includes system categories returned by the datasource', () async {
      when(() => ds.getCategories(userIdValue)).thenAnswer(
        (_) async => [
          CategoryMapper.toRow(
            categoryFixture(id: 'cat-religion', isSystem: true),
          ),
          CategoryMapper.toRow(categoryFixture()),
        ],
      );
      final cats = await repo.getCategories(UserId(userIdValue));
      expect(cats, hasLength(2));
      expect(cats.any((c) => c.isSystem), isTrue);
    });
  });

  group('createCategory', () {
    test('returns the created category', () async {
      final cat = categoryFixture();
      when(
        () => ds.createCategory(any()),
      ).thenAnswer((_) async => CategoryMapper.toRow(cat));
      final created = await repo.createCategory(
        userId: UserId(userIdValue),
        category: cat,
      );
      expect(created.id, cat.id);
      final captured =
          verify(() => ds.createCategory(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['user_id'], userIdValue);
    });
  });

  group('updateCategory', () {
    test('forwards updated data to the datasource', () async {
      final cat = categoryFixture();
      when(
        () => ds.updateCategory(any()),
      ).thenAnswer((_) async => CategoryMapper.toRow(cat));
      final updated = await repo.updateCategory(cat);
      expect(updated.id, cat.id);
      verify(() => ds.updateCategory(any())).called(1);
    });
  });

  group('deleteCategory', () {
    test('delegates to the datasource', () async {
      when(() => ds.deleteCategory('cat-x')).thenAnswer((_) async {});
      await repo.deleteCategory(CategoryId('cat-x'));
      verify(() => ds.deleteCategory('cat-x')).called(1);
    });
  });

  group('getCategoryBySlug', () {
    test('returns category matching slug', () async {
      when(() => ds.getCategories(userIdValue)).thenAnswer(
        (_) async => [
          {
            ...CategoryMapper.toRow(categoryFixture(id: 'uuid-001')),
            'slug': 'religion',
          },
          CategoryMapper.toRow(categoryFixture(id: 'cat-x')),
        ],
      );
      final cat = await repo.getCategoryBySlug(UserId(userIdValue), 'religion');
      expect(cat.slug, 'religion');
    });

    test('throws CategoryFailure.notFound when slug is absent', () async {
      when(
        () => ds.getCategories(userIdValue),
      ).thenAnswer((_) async => [CategoryMapper.toRow(categoryFixture())]);
      await expectLater(
        repo.getCategoryBySlug(UserId(userIdValue), 'unknown-slug'),
        throwsA(isA<CategoryNotFoundFailure>()),
      );
    });
  });

  group('OwnershipGuard (issue #202 / M3)', () {
    test('getCategories avec userId != currentUser lève '
        'CategoryFailure.unauthorized avant tout appel datasource', () async {
      resolver.id = 'autre-user';
      await expectLater(
        repo.getCategories(UserId(userIdValue)),
        throwsA(isA<CategoryUnauthorizedFailure>()),
      );
      verifyNever(() => ds.getCategories(any()));
    });

    test(
      'createCategory avec userId != currentUser lève unauthorized',
      () async {
        resolver.id = 'autre-user';
        await expectLater(
          repo.createCategory(
            userId: UserId(userIdValue),
            category: categoryFixture(),
          ),
          throwsA(isA<CategoryUnauthorizedFailure>()),
        );
        verifyNever(() => ds.createCategory(any()));
      },
    );
  });
}
