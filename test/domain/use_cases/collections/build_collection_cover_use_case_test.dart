import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/build_collection_cover_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_cover.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
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
      color: HexColor(color),
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
      expect(fb.categoryColor, HexColor('#3A6B8C'));
      expect(fb.initial, 'R');
    });

    test('uses sandstone neutral when category is null (P-3 design)', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: null),
        category: null,
      );
      final fb = cover as CollectionCoverFallback;
      expect(fb.categoryColor, HexColor('#A19D93')); // CDC §P-3 sandstone
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
  });

  group('grapheme cluster initial (Copilot fix #2)', () {
    test('emoji-prefixed name keeps the full glyph as initial', () {
      // `'🚀 Routine'.substring(0, 1)` returns the high surrogate alone,
      // which is a malformed UTF-16 code unit. `characters.first` returns
      // the full emoji as a single user-perceived character.
      final cover = useCase(
        collection: makeCollection(coverImageUrl: null, name: '🚀 Routine'),
        category: makeCategory(),
      );
      final fb = cover as CollectionCoverFallback;
      expect(fb.initial, '🚀');
      // Must not be the high-surrogate-only artefact:
      expect(fb.initial.length, greaterThan(1)); // emoji = 2 UTF-16 code units
    });

    test('Arabic name returns the first Arabic glyph', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: null, name: 'بسم الله'),
        category: makeCategory(),
      );
      final fb = cover as CollectionCoverFallback;
      expect(fb.initial, 'ب');
    });

    test('combining mark / accented latin keeps the cluster intact', () {
      // 'É' as base + combining acute → counted as ONE grapheme.
      final cover = useCase(
        collection: makeCollection(coverImageUrl: null, name: 'Étoile'),
        category: makeCategory(),
      );
      final fb = cover as CollectionCoverFallback;
      // 'É' may live in source as NFC (U+00C9) or NFD (E + U+0301). Both
      // forms must produce a single grapheme cluster, never a bare ASCII
      // 'E' with the combining mark stripped off (which is what
      // `substring(0, 1)` would do on NFD input — the bug we fix).
      expect(fb.initial.characters.length, 1);
      expect(fb.initial, isNot('E'));
    });

    test('simple ASCII name returns first char uppercased', () {
      final cover = useCase(
        collection: makeCollection(coverImageUrl: null, name: 'lecture'),
        category: makeCategory(),
      );
      final fb = cover as CollectionCoverFallback;
      expect(fb.initial, 'L');
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
