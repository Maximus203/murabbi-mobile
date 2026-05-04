import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/domain/value_objects/target_value.dart';

void main() {
  group('TargetUnit enum', () {
    test('exposes 10 v1.5 spec units', () {
      expect(TargetUnit.values.length, 10);
      expect(
        TargetUnit.values,
        containsAll([
          TargetUnit.minutes,
          TargetUnit.hours,
          TargetUnit.pages,
          TargetUnit.glasses,
          TargetUnit.reps,
          TargetUnit.sets,
          TargetUnit.km,
          TargetUnit.meters,
          TargetUnit.steps,
          TargetUnit.custom,
        ]),
      );
    });

    test('isTimeBased true only for minutes and hours', () {
      expect(TargetUnit.minutes.isTimeBased, isTrue);
      expect(TargetUnit.hours.isTimeBased, isTrue);
      expect(TargetUnit.pages.isTimeBased, isFalse);
      expect(TargetUnit.custom.isTimeBased, isFalse);
    });

    test('parse(string) returns matching unit', () {
      expect(TargetUnit.parse('minutes'), TargetUnit.minutes);
      expect(TargetUnit.parse('custom'), TargetUnit.custom);
    });

    test('parse(unknown) throws ArgumentError', () {
      expect(() => TargetUnit.parse('nope'), throwsArgumentError);
    });
  });

  group('TargetValue', () {
    test('creates with positive int in [1..9999]', () {
      expect(TargetValue(1).value, 1);
      expect(TargetValue(20).value, 20);
      expect(TargetValue(9999).value, 9999);
    });

    test('throws on zero', () {
      expect(() => TargetValue(0), throwsArgumentError);
    });

    test('throws on negative', () {
      expect(() => TargetValue(-1), throwsArgumentError);
    });

    test('throws on > 9999', () {
      expect(() => TargetValue(10000), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      expect(TargetValue(5), equals(TargetValue(5)));
    });
  });

  group('HabitSubtaskId', () {
    test('creates with non-empty string', () {
      final id = HabitSubtaskId('subtask-uuid-001');
      expect(id.value, 'subtask-uuid-001');
    });

    test('trims whitespace', () {
      expect(HabitSubtaskId('  uuid-1  ').value, 'uuid-1');
    });

    test('throws on empty', () {
      expect(() => HabitSubtaskId(''), throwsArgumentError);
      expect(() => HabitSubtaskId('   '), throwsArgumentError);
    });

    test('two instances with same value are equal', () {
      expect(HabitSubtaskId('uuid-1'), equals(HabitSubtaskId('uuid-1')));
    });

    test('toString returns value', () {
      expect(HabitSubtaskId('uuid-1').toString(), 'uuid-1');
    });
  });

  group('Pseudonym (Q-10)', () {
    test('creates with valid pseudo (1..30 chars)', () {
      expect(Pseudonym('Cherif').value, 'Cherif');
      expect(Pseudonym('a').value, 'a');
      expect(Pseudonym('a' * 30).value, 'a' * 30);
    });

    test('trims whitespace before validation', () {
      expect(Pseudonym('  Cherif  ').value, 'Cherif');
    });

    test('throws on empty after trim', () {
      expect(() => Pseudonym(''), throwsArgumentError);
      expect(() => Pseudonym('   '), throwsArgumentError);
    });

    test('throws on > 30 chars after trim', () {
      expect(() => Pseudonym('a' * 31), throwsArgumentError);
    });

    test('accepts unicode (arabic, emoji-free latin)', () {
      expect(Pseudonym('شريف').value, 'شريف');
      expect(Pseudonym('Cherîf').value, 'Cherîf');
    });

    test('throws on control characters (newline, tab, NUL)', () {
      expect(() => Pseudonym('Che\nrif'), throwsArgumentError);
      expect(() => Pseudonym('Che\trif'), throwsArgumentError);
      expect(() => Pseudonym('Che\x00rif'), throwsArgumentError);
    });

    test('throws on zero-width characters', () {
      // U+200B ZERO WIDTH SPACE
      expect(() => Pseudonym('Che​rif'), throwsArgumentError);
      // U+FEFF ZERO WIDTH NO-BREAK SPACE
      expect(() => Pseudonym('Che﻿rif'), throwsArgumentError);
    });

    test('two pseudos with same value are equal', () {
      expect(Pseudonym('Cherif'), equals(Pseudonym('Cherif')));
    });

    test('toString returns value', () {
      expect(Pseudonym('Cherif').toString(), 'Cherif');
    });
  });
}
