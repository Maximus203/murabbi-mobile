import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/category_data_source.dart';
import 'package:murabbi_mobile/data/mappers/category_mapper.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class _MockCategoryDataSource extends Mock implements CategoryDataSource {}

void main() {
  late _MockCategoryDataSource ds;
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
    repo = CategoryRepositoryImpl(ds);
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
}
