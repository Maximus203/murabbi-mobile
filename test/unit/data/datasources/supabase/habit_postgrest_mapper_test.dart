import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_habit_data_source.dart';
import 'package:murabbi_mobile/domain/errors/habit_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

void main() {
  group('mapHabitPostgrestException (issue #198 / M4)', () {
    test('code 23505 (unique_violation) → HabitFailure.duplicate()', () {
      const ex = sb.PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      );
      final failure = mapHabitPostgrestException(ex);
      expect(failure, isA<HabitDuplicateFailure>());
    });

    test('FUTURE_LOG_NOT_ALLOWED dans le message → futureLogNotAllowed', () {
      const ex = sb.PostgrestException(
        message: 'P0001 FUTURE_LOG_NOT_ALLOWED',
        code: 'P0001',
      );
      final failure = mapHabitPostgrestException(ex);
      expect(failure, isA<HabitFutureLogNotAllowedFailure>());
    });

    test('BACKDATE_TOO_OLD dans le message → backdateTooOld', () {
      const ex = sb.PostgrestException(
        message: 'P0001 BACKDATE_TOO_OLD',
        code: 'P0001',
      );
      final failure = mapHabitPostgrestException(ex);
      expect(failure, isA<HabitBackdateTooOldFailure>());
    });

    test('autre PostgrestException → database failure', () {
      const ex = sb.PostgrestException(
        message: 'some other db error',
        code: '42P01',
      );
      final failure = mapHabitPostgrestException(ex);
      expect(failure, isA<HabitDatabaseFailure>());
    });
  });
}
