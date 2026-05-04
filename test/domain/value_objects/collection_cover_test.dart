import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_cover.dart';

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
    test('builds from category color hex + initial', () {
      final cover = CollectionCoverFallback(
        categoryColorHex: '#3A6B8C',
        initial: 'M',
      );
      expect(cover.categoryColorHex, '#3A6B8C');
      expect(cover.initial, 'M');
    });

    test('uppercases the initial', () {
      final cover = CollectionCoverFallback(
        categoryColorHex: '#3A6B8C',
        initial: 'm',
      );
      expect(cover.initial, 'M');
    });

    test('rejects multi-char initial', () {
      expect(
        () =>
            CollectionCoverFallback(categoryColorHex: '#3A6B8C', initial: 'Mo'),
        throwsArgumentError,
      );
    });

    test('rejects empty initial', () {
      expect(
        () => CollectionCoverFallback(categoryColorHex: '#3A6B8C', initial: ''),
        throwsArgumentError,
      );
    });

    test('rejects malformed color hex (no leading #)', () {
      expect(
        () => CollectionCoverFallback(categoryColorHex: '3A6B8C', initial: 'M'),
        throwsArgumentError,
      );
    });

    test('rejects color hex with bad length', () {
      expect(
        () => CollectionCoverFallback(categoryColorHex: '#3A6', initial: 'M'),
        throwsArgumentError,
      );
    });

    test('two fallbacks with the same fields are equal', () {
      final a = CollectionCoverFallback(
        categoryColorHex: '#3A6B8C',
        initial: 'M',
      );
      final b = CollectionCoverFallback(
        categoryColorHex: '#3A6B8C',
        initial: 'M',
      );
      expect(a, equals(b));
    });
  });

  group('CollectionCover sealed type', () {
    test('Image and Fallback are not equal even with related data', () {
      final image = CollectionCoverImage('https://x.example/c.jpg');
      final fallback = CollectionCoverFallback(
        categoryColorHex: '#3A6B8C',
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
