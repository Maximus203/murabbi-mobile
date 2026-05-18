import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/category_icons.dart';

void main() {
  group('categoryIconFromSlug', () {
    test('mappe les slugs catégories système connus', () {
      expect(categoryIconFromSlug('moon-star'), LucideIcons.moonStar);
      expect(categoryIconFromSlug('dumbbell'), LucideIcons.dumbbell);
      expect(categoryIconFromSlug('heart-pulse'), LucideIcons.heartPulse);
      expect(categoryIconFromSlug('brain'), LucideIcons.brain);
      expect(categoryIconFromSlug('users'), LucideIcons.users);
    });

    test('slug inconnu retombe sur target', () {
      expect(categoryIconFromSlug('inexistant'), LucideIcons.target);
    });

    test('slug null ou vide retombe sur target', () {
      expect(categoryIconFromSlug(null), LucideIcons.target);
      expect(categoryIconFromSlug(''), LucideIcons.target);
    });

    test('deux catégories distinctes donnent des icônes distinctes', () {
      expect(
        categoryIconFromSlug('dumbbell'),
        isNot(categoryIconFromSlug('brain')),
      );
    });
  });
}
