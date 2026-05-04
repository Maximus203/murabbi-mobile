import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/build_collection_cover_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_cover.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

/// Source: product_decisions_v1.md § Q-13-cover.
/// - URL présente → `CollectionCoverImage`
/// - URL absente → `CollectionCoverFallback` (gradient catégorie + initiale)
/// - Catégorie absente → fallback avec une couleur sandstone neutre
void main() {
  Collection makeCollection({
    String? coverImageUrl,
    String name = 'Routine du matin',
  }) {
    return Collection(
      id: CollectionId('coll-uuid-001'),
      name: NonEmptyString(name),
      description: NonEmptyString('Start the day right'),
      habitIds: [HabitId('h-1')],
      isSystem: true,
      isActive: false,
      coverImageUrl: coverImageUrl,
    );
  }

  Category makeCategory({String color = '#3A6B8C'}) {
    return Category(
      id: CategoryId('cat-uuid-001'),
      name: NonEmptyString('Salat'),
      color: color,
      icon: 'pray',
      points: HabitPoints(3),
      isSystem: true,
    );
  }

  late BuildCollectionCoverUseCase useCase;

  setUp(() => useCase = BuildCollectionCoverUseCase());

  group('with cover URL', () {
    test('returns CollectionCoverImage when URL is non-empty', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: 'https://x.example/c.jpg'),
        category: makeCategory(),
      );
      expect(cover, isA<CollectionCoverImage>());
      expect((cover as CollectionCoverImage).url, 'https://x.example/c.jpg');
    });

    test('cover URL takes precedence over category (no gradient)', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: 'https://x.example/c.jpg'),
        category: makeCategory(color: '#FF00FF'),
      );
      expect(cover, isA<CollectionCoverImage>());
    });
  });

  group('without cover URL — fallback gradient', () {
    test('uses category color when category is provided', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: null),
        category: makeCategory(color: '#3A6B8C'),
      );
      expect(cover, isA<CollectionCoverFallback>());
      final fb = cover as CollectionCoverFallback;
      expect(fb.categoryColorHex, '#3A6B8C');
      expect(fb.initial, 'R');
    });

    test('uses sandstone neutral when category is null (P-3 design)', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: null),
        category: null,
      );
      final fb = cover as CollectionCoverFallback;
      expect(fb.categoryColorHex, '#A19D93'); // CDC §P-3 sandstone neutral
      expect(fb.initial, 'R');
    });

    test('uses uppercase initial of the collection name', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: null, name: 'salat al fajr'),
        category: makeCategory(),
      );
      final fb = cover as CollectionCoverFallback;
      expect(fb.initial, 'S');
    });

    test('handles non-ASCII initial (Arabic letter passes through)', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: null, name: 'صلاة'),
        category: makeCategory(),
      );
      final fb = cover as CollectionCoverFallback;
      // toUpperCase is a no-op on Arabic glyphs — first char preserved.
      expect(fb.initial, 'ص');
    });
  });

  group('treats empty/whitespace URL as absent', () {
    test('empty string → fallback', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: ''),
        category: makeCategory(),
      );
      expect(cover, isA<CollectionCoverFallback>());
    });

    test('whitespace-only URL → fallback', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: '   '),
        category: makeCategory(),
      );
      expect(cover, isA<CollectionCoverFallback>());
    });
  });
}
