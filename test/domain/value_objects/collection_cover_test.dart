import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_cover.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';

void main() {
  group('CollectionCoverImage', () {
    test('exposes the URL it was built with', () {
      final cover = CollectionCoverImage('https://x.example/c.jpg');
      expect(cover.url, 'https://x.example/c.jpg');
    });

    test('throws on empty URL', () {
      expect(() => CollectionCoverImage(''), throwsArgumentError);
    });

    test('throws on whitespace URL', () {
      expect(() => CollectionCoverImage('   '), throwsArgumentError);
    });

    test('two instances with the same URL are equal', () {
      final a = CollectionCoverImage('https://x.example/c.jpg');
      final b = CollectionCoverImage('https://x.example/c.jpg');
      expect(a, equals(b));
    });

    test('different URLs are not equal', () {
      final a = CollectionCoverImage('https://x.example/a.jpg');
      final b = CollectionCoverImage('https://x.example/b.jpg');
      expect(a, isNot(equals(b)));
    });
  });

  group('CollectionCoverFallback', () {
    test('builds from category color (HexColor) + initial', () {
      final cover = CollectionCoverFallback(
        categoryColor: HexColor('#3A6B8C'),
        initial: 'M',
      );
      expect(cover.categoryColor, HexColor('#3A6B8C'));
      expect(cover.initial, 'M');
    });

    test('rejects empty initial', () {
      expect(
        () => CollectionCoverFallback(
          categoryColor: HexColor('#3A6B8C'),
          initial: '',
        ),
        throwsArgumentError,
      );
    });

    test('accepts a multi-codepoint initial (emoji grapheme cluster)', () {
      // The use case computes initial via `characters.first`, which can return
      // multiple UTF-16 code units for a single user-perceived character
      // (emoji, ZWJ sequences, …). The value object MUST accept this.
      final cover = CollectionCoverFallback(
        categoryColor: HexColor('#3A6B8C'),
        initial: '🚀',
      );
      expect(cover.initial, '🚀');
    });

    test('two fallbacks with the same fields are equal', () {
      final a = CollectionCoverFallback(
        categoryColor: HexColor('#3A6B8C'),
        initial: 'M',
      );
      final b = CollectionCoverFallback(
        categoryColor: HexColor('#3A6B8C'),
        initial: 'M',
      );
      expect(a, equals(b));
    });

    test('different categoryColor or initial → not equal', () {
      final a = CollectionCoverFallback(
        categoryColor: HexColor('#3A6B8C'),
        initial: 'M',
      );
      final b = CollectionCoverFallback(
        categoryColor: HexColor('#FF00FF'),
        initial: 'M',
      );
      final c = CollectionCoverFallback(
        categoryColor: HexColor('#3A6B8C'),
        initial: 'N',
      );
      expect(a, isNot(equals(b)));
      expect(a, isNot(equals(c)));
    });
  });

  group('CollectionCover sealed type', () {
    test('Image and Fallback are not equal even with related data', () {
      final image = CollectionCoverImage('https://x.example/c.jpg');
      final fallback = CollectionCoverFallback(
        categoryColor: HexColor('#3A6B8C'),
        initial: 'M',
      );
      expect(image, isNot(equals(fallback)));
    });

    test('switch on sealed exhausts both variants without default', () {
      // Type-system regression: if a future variant is added without
      // updating callers, this switch becomes a compile error — proving
      // the sealed contract is enforced at the language level.
      final CollectionCover cover = CollectionCoverImage(
        'https://x.example/c.jpg',
      );
      final label = switch (cover) {
        CollectionCoverImage(:final url) => 'image:$url',
        CollectionCoverFallback(:final initial) => 'fallback:$initial',
      };
      expect(label, 'image:https://x.example/c.jpg');
    });
  });
}
