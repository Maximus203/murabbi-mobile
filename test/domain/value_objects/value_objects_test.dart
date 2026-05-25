import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/percentage.dart';
import 'package:murabbi_mobile/domain/value_objects/prayer_points.dart';
import 'package:murabbi_mobile/domain/value_objects/time_of_day_value.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

void main() {
  group('UserId', () {
    test('creates with valid uuid', () {
      final id = UserId('550e8400-e29b-41d4-a716-446655440000');
      expect(id.value, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('throws on empty string', () {
      expect(() => UserId(''), throwsArgumentError);
    });

    test('throws on whitespace only', () {
      expect(() => UserId('   '), throwsArgumentError);
    });

    test('trims leading and trailing whitespace', () {
      final id = UserId('  550e8400-e29b-41d4-a716-446655440000  ');
      expect(id.value, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('two instances with same value are equal', () {
      final a = UserId('550e8400-e29b-41d4-a716-446655440000');
      final b = UserId('550e8400-e29b-41d4-a716-446655440000');
      expect(a, equals(b));
    });

    test('two instances with different values are not equal', () {
      final a = UserId('550e8400-e29b-41d4-a716-446655440000');
      final b = UserId('660e8400-e29b-41d4-a716-446655440001');
      expect(a, isNot(equals(b)));
    });

    test('toString returns value', () {
      final id = UserId('550e8400-e29b-41d4-a716-446655440000');
      expect(id.toString(), '550e8400-e29b-41d4-a716-446655440000');
    });
  });

  group('HabitId', () {
    test('creates with valid uuid', () {
      final id = HabitId('habit-uuid-001');
      expect(id.value, 'habit-uuid-001');
    });

    test('throws on empty string', () {
      expect(() => HabitId(''), throwsArgumentError);
    });

    test('trims leading and trailing whitespace', () {
      final id = HabitId('  habit-uuid-001  ');
      expect(id.value, 'habit-uuid-001');
    });

    test('two instances with same value are equal', () {
      final a = HabitId('habit-uuid-001');
      final b = HabitId('habit-uuid-001');
      expect(a, equals(b));
    });

    test('toString returns value', () {
      final id = HabitId('habit-uuid-001');
      expect(id.toString(), 'habit-uuid-001');
    });
  });

  group('CategoryId', () {
    test('creates with valid uuid', () {
      final id = CategoryId('cat-uuid-001');
      expect(id.value, 'cat-uuid-001');
    });

    test('throws on empty string', () {
      expect(() => CategoryId(''), throwsArgumentError);
    });

    test('trims leading and trailing whitespace', () {
      final id = CategoryId('  cat-uuid-001  ');
      expect(id.value, 'cat-uuid-001');
    });

    test('two instances with same value are equal', () {
      final a = CategoryId('cat-uuid-001');
      final b = CategoryId('cat-uuid-001');
      expect(a, equals(b));
    });

    test('toString returns value', () {
      final id = CategoryId('cat-uuid-001');
      expect(id.toString(), 'cat-uuid-001');
    });
  });

  group('CollectionId', () {
    test('creates with valid uuid', () {
      final id = CollectionId('coll-uuid-001');
      expect(id.value, 'coll-uuid-001');
    });

    test('throws on empty string', () {
      expect(() => CollectionId(''), throwsArgumentError);
    });

    test('trims leading and trailing whitespace', () {
      final id = CollectionId('  coll-uuid-001  ');
      expect(id.value, 'coll-uuid-001');
    });

    test('two instances with same value are equal', () {
      final a = CollectionId('coll-uuid-001');
      final b = CollectionId('coll-uuid-001');
      expect(a, equals(b));
    });

    test('toString returns value', () {
      final id = CollectionId('coll-uuid-001');
      expect(id.toString(), 'coll-uuid-001');
    });
  });

  group('HabitPoints', () {
    test('creates with minimum value 1', () {
      final p = HabitPoints(1);
      expect(p.value, 1);
    });

    test('creates with maximum value 10', () {
      final p = HabitPoints(10);
      expect(p.value, 10);
    });

    test('creates with mid value 5', () {
      final p = HabitPoints(5);
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
      final a = HabitPoints(5);
      final b = HabitPoints(5);
      expect(a, equals(b));
    });
  });

  group('PrayerPoints', () {
    test('creates with minimum value 0', () {
      final p = PrayerPoints(0);
      expect(p.value, 0);
    });

    test('creates with maximum value 3', () {
      final p = PrayerPoints(3);
      expect(p.value, 3);
    });

    test('creates with mid value 1', () {
      final p = PrayerPoints(1);
      expect(p.value, 1);
    });

    test('throws on value above maximum (4)', () {
      expect(() => PrayerPoints(4), throwsArgumentError);
    });

    test('throws on negative value', () {
      expect(() => PrayerPoints(-1), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      final a = PrayerPoints(2);
      final b = PrayerPoints(2);
      expect(a, equals(b));
    });
  });

  group('Percentage', () {
    test('creates with 0.0', () {
      final p = Percentage(0.0);
      expect(p.value, 0.0);
    });

    test('creates with 1.0', () {
      final p = Percentage(1.0);
      expect(p.value, 1.0);
    });

    test('creates with 0.5', () {
      final p = Percentage(0.5);
      expect(p.value, 0.5);
    });

    test('throws on value below 0.0', () {
      expect(() => Percentage(-0.1), throwsArgumentError);
    });

    test('throws on value above 1.0', () {
      expect(() => Percentage(1.1), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      final a = Percentage(0.75);
      final b = Percentage(0.75);
      expect(a, equals(b));
    });
  });

  group('NonEmptyString', () {
    test('creates with valid string', () {
      final s = NonEmptyString('Fajr');
      expect(s.value, 'Fajr');
    });

    test('throws on empty string', () {
      expect(() => NonEmptyString(''), throwsArgumentError);
    });

    test('throws on whitespace only', () {
      expect(() => NonEmptyString('   '), throwsArgumentError);
    });

    test('trims leading and trailing whitespace', () {
      final s = NonEmptyString('  Fajr  ');
      expect(s.value, 'Fajr');
    });

    test('two instances with same trimmed value are equal', () {
      final a = NonEmptyString('Fajr');
      final b = NonEmptyString('  Fajr  ');
      expect(a, equals(b));
    });

    test('two instances with different values are not equal', () {
      final a = NonEmptyString('Fajr');
      final b = NonEmptyString('Dhuhr');
      expect(a, isNot(equals(b)));
    });
  });

  group('TimeOfDayValue', () {
    test('creates with valid hour and minute', () {
      final t = TimeOfDayValue(8, 30);
      expect(t.hour, 8);
      expect(t.minute, 30);
    });

    test('creates with boundary 0:0', () {
      final t = TimeOfDayValue(0, 0);
      expect(t.hour, 0);
      expect(t.minute, 0);
    });

    test('creates with boundary 23:59', () {
      final t = TimeOfDayValue(23, 59);
      expect(t.hour, 23);
      expect(t.minute, 59);
    });

    test('throws on hour below 0', () {
      expect(() => TimeOfDayValue(-1, 0), throwsArgumentError);
    });

    test('throws on hour above 23', () {
      expect(() => TimeOfDayValue(24, 0), throwsArgumentError);
    });

    test('throws on minute below 0', () {
      expect(() => TimeOfDayValue(10, -1), throwsArgumentError);
    });

    test('throws on minute above 59', () {
      expect(() => TimeOfDayValue(10, 60), throwsArgumentError);
    });

    test('toString pads hour and minute with zero', () {
      expect(TimeOfDayValue(8, 5).toString(), '08:05');
      expect(TimeOfDayValue(23, 59).toString(), '23:59');
      expect(TimeOfDayValue(0, 0).toString(), '00:00');
    });

    test('two instances with same hour/minute are equal', () {
      final a = TimeOfDayValue(8, 30);
      final b = TimeOfDayValue(8, 30);
      expect(a, equals(b));
    });

    test('two instances with different values are not equal', () {
      final a = TimeOfDayValue(8, 30);
      final b = TimeOfDayValue(8, 31);
      expect(a, isNot(equals(b)));
    });

    test('isBefore returns true when earlier same hour', () {
      expect(TimeOfDayValue(8, 0).isBefore(TimeOfDayValue(8, 30)), isTrue);
    });

    test('isBefore returns true when earlier different hour', () {
      expect(TimeOfDayValue(7, 30).isBefore(TimeOfDayValue(8, 0)), isTrue);
    });

    test('isBefore returns false when equal', () {
      expect(TimeOfDayValue(8, 0).isBefore(TimeOfDayValue(8, 0)), isFalse);
    });

    test('isBefore returns false when later', () {
      expect(TimeOfDayValue(9, 0).isBefore(TimeOfDayValue(8, 30)), isFalse);
    });
  });
}
