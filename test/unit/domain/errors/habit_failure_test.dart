import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/errors/habit_failure.dart';

void main() {
  group('HabitFailure.duplicate (issue #198 / M4)', () {
    test('construit une instance typée HabitDuplicateFailure', () {
      const failure = HabitFailure.duplicate(message: 'already logged');
      expect(failure, isA<HabitDuplicateFailure>());
      expect(failure, isA<HabitFailure>());
      expect(failure.message, 'already logged');
    });

    test('équivalence par valeur (Equatable)', () {
      const a = HabitFailure.duplicate(message: 'dup');
      const b = HabitFailure.duplicate(message: 'dup');
      expect(a, equals(b));
    });

    test('toString contient le message', () {
      const failure = HabitFailure.duplicate(message: 'unique violation');
      expect(failure.toString(), contains('unique violation'));
    });

    test('exhaustivité du switch sealed', () {
      const failure = HabitFailure.duplicate();
      final result = switch (failure) {
        HabitFutureLogNotAllowedFailure() => 'future',
        HabitBackdateTooOldFailure() => 'backdate',
        HabitDatabaseFailure() => 'database',
        HabitNetworkFailure() => 'network',
        HabitUnauthorizedFailure() => 'unauthorized',
        HabitDuplicateFailure() => 'duplicate',
      };
      expect(result, 'duplicate');
    });
  });
}
