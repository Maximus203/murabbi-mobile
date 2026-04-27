import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/percentage.dart';
import 'package:murabbi_mobile/domain/value_objects/prayer_points.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

void main() {
  group('UserId', () {
    test('creates with valid uuid', () {
      const id = UserId('550e8400-e29b-41d4-a716-446655440000');
      expect(id.value, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('throws on empty string', () {
      expect(() => UserId(''), throwsArgumentError);
    });

    test('throws on whitespace only', () {
      expect(() => UserId('   '), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      const a = UserId('550e8400-e29b-41d4-a716-446655440000');
      const b = UserId('550e8400-e29b-41d4-a716-446655440000');
      expect(a, equals(b));
    });

    test('two instances with different values are not equal', () {
      const a = UserId('550e8400-e29b-41d4-a716-446655440000');
      const b = UserId('660e8400-e29b-41d4-a716-446655440001');
      expect(a, isNot(equals(b)));
    });

    test('toString returns value', () {
      const id = UserId('550e8400-e29b-41d4-a716-446655440000');
      expect(id.toString(), '550e8400-e29b-41d4-a716-446655440000');
    });
  });

  group('HabitId', () {
    test('creates with valid uuid', () {
      const id = HabitId('habit-uuid-001');
      expect(id.value, 'habit-uuid-001');
    });

    test('throws on empty string', () {
      expect(() => HabitId(''), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      const a = HabitId('habit-uuid-001');
      const b = HabitId('habit-uuid-001');
      expect(a, equals(b));
    });
  });

  group('CategoryId', () {
    test('creates with valid uuid', () {
      const id = CategoryId('cat-uuid-001');
      expect(id.value, 'cat-uuid-001');
    });

    test('throws on empty string', () {
      expect(() => CategoryId(''), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      const a = CategoryId('cat-uuid-001');
      const b = CategoryId('cat-uuid-001');
      expect(a, equals(b));
    });
  });

  group('CollectionId', () {
    test('creates with valid uuid', () {
      const id = CollectionId('coll-uuid-001');
      expect(id.value, 'coll-uuid-001');
    });

    test('throws on empty string', () {
      expect(() => CollectionId(''), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      const a = CollectionId('coll-uuid-001');
      const b = CollectionId('coll-uuid-001');
      expect(a, equals(b));
    });
  });

  group('HabitPoints', () {
    test('creates with minimum value 1', () {
      const p = HabitPoints(1);
      expect(p.value, 1);
    });

    test('creates with maximum value 10', () {
      const p = HabitPoints(10);
      expect(p.value, 10);
    });

    test('creates with mid value 5', () {
      const p = HabitPoints(5);
      expect(p.value, 5);
    });

    test('throws on value below minimum (0)', () {
      expect(() => HabitPoints(0), throwsArgumentError);
    });

    test('throws on value above maximum (11)', () {
      expect(() => HabitPoints(11), throwsArgumentError);
    });

    test('throws on negative value', () {
      expect(() => HabitPoints(-1), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      const a = HabitPoints(5);
      const b = HabitPoints(5);
      expect(a, equals(b));
    });
  });

  group('PrayerPoints', () {
    test('creates with minimum value 0', () {
      const p = PrayerPoints(0);
      expect(p.value, 0);
    });

    test('creates with maximum value 3', () {
      const p = PrayerPoints(3);
      expect(p.value, 3);
    });

    test('creates with mid value 1', () {
      const p = PrayerPoints(1);
      expect(p.value, 1);
    });

    test('throws on value above maximum (4)', () {
      expect(() => PrayerPoints(4), throwsArgumentError);
    });

    test('throws on negative value', () {
      expect(() => PrayerPoints(-1), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      const a = PrayerPoints(2);
      const b = PrayerPoints(2);
      expect(a, equals(b));
    });
  });

  group('Percentage', () {
    test('creates with 0.0', () {
      const p = Percentage(0.0);
      expect(p.value, 0.0);
    });

    test('creates with 1.0', () {
      const p = Percentage(1.0);
      expect(p.value, 1.0);
    });

    test('creates with 0.5', () {
      const p = Percentage(0.5);
      expect(p.value, 0.5);
    });

    test('throws on value below 0.0', () {
      expect(() => Percentage(-0.1), throwsArgumentError);
    });

    test('throws on value above 1.0', () {
      expect(() => Percentage(1.1), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      const a = Percentage(0.75);
      const b = Percentage(0.75);
      expect(a, equals(b));
    });
  });

  group('NonEmptyString', () {
    test('creates with valid string', () {
      const s = NonEmptyString('Fajr');
      expect(s.value, 'Fajr');
    });

    test('throws on empty string', () {
      expect(() => NonEmptyString(''), throwsArgumentError);
    });

    test('throws on whitespace only', () {
      expect(() => NonEmptyString('   '), throwsArgumentError);
    });

    test('trims leading and trailing whitespace', () {
      const s = NonEmptyString('  Fajr  ');
      expect(s.value, 'Fajr');
    });

    test('two instances with same trimmed value are equal', () {
      const a = NonEmptyString('Fajr');
      const b = NonEmptyString('  Fajr  ');
      expect(a, equals(b));
    });

    test('two instances with different values are not equal', () {
      const a = NonEmptyString('Fajr');
      const b = NonEmptyString('Dhuhr');
      expect(a, isNot(equals(b)));
    });
  });
}
