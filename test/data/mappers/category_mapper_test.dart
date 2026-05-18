import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/category_mapper.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

void main() {
  group('CategoryMapper.fromRow', () {
    test('maps a system category', () {
      final cat = CategoryMapper.fromRow({
        'id': 'cat-religion',
        'name': 'Religion',
        'color': '#3A6B8C',
        'icon': 'moon-star',
        'is_system': true,
      });
      expect(cat.id, CategoryId('cat-religion'));
      expect(cat.name, NonEmptyString('Religion'));
      expect(cat.color, HexColor('#3A6B8C'));
      expect(cat.icon, 'moon-star');
      expect(cat.isSystem, true);
    });

    test('maps a user category', () {
      final cat = CategoryMapper.fromRow({
        'id': 'cat-x',
        'name': 'Custom',
        'color': '#ABCDEF',
        'icon': 'star',
        'is_system': false,
      });
      expect(cat.isSystem, false);
    });
  });

  group('CategoryMapper.toRow', () {
    test('round-trips a category', () {
      final cat = CategoryMapper.fromRow({
        'id': 'cat-religion',
        'name': 'Religion',
        'color': '#3A6B8C',
        'icon': 'moon-star',
        'is_system': true,
      });
      final row = CategoryMapper.toRow(cat);
      expect(row['id'], 'cat-religion');
      expect(row['name'], 'Religion');
      expect(row['color'], '#3A6B8C');
      expect(row['icon'], 'moon-star');
      expect(row['is_system'], true);
    });
  });
}
