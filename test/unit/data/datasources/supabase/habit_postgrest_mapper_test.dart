// Tests unitaires de [mapHabitPostgrestException] (#198 / M4 / Q-backend-01).
//
// PostgreSQL pose le code RPC exactement dans `message` via
// `RAISE EXCEPTION 'CODE' USING HINT = '...'` (migration 20260523000001).
// On utilise donc `==` et non `.contains()` — mis à jour Q-backend-01.

import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_habit_data_source.dart';
import 'package:murabbi_mobile/domain/errors/habit_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

sb.PostgrestException _rpc(String code) =>
    sb.PostgrestException(message: code, code: 'P0001');

sb.PostgrestException _pg(String pgCode, String msg) =>
    sb.PostgrestException(message: msg, code: pgCode);

void main() {
  group('mapHabitPostgrestException — codes Postgres natifs (#198 / M4)', () {
    test('23505 (unique_violation) → HabitDuplicateFailure', () {
      final failure = mapHabitPostgrestException(
        _pg('23505', 'duplicate key value violates unique constraint'),
      );
      expect(failure, isA<HabitDuplicateFailure>());
    });

    test('code inconnu → HabitDatabaseFailure', () {
      final failure = mapHabitPostgrestException(
        _pg('42P01', 'some other db error'),
      );
      expect(failure, isA<HabitDatabaseFailure>());
    });
  });

  group('mapHabitPostgrestException — codes RPC toggle_habit_log (Q-backend-01)', () {
    test('FUTURE_LOG_NOT_ALLOWED → HabitFutureLogNotAllowedFailure', () {
      expect(
        mapHabitPostgrestException(_rpc('FUTURE_LOG_NOT_ALLOWED')),
        isA<HabitFutureLogNotAllowedFailure>(),
      );
    });

    test('BACKDATE_TOO_OLD → HabitBackdateTooOldFailure', () {
      expect(
        mapHabitPostgrestException(_rpc('BACKDATE_TOO_OLD')),
        isA<HabitBackdateTooOldFailure>(),
      );
    });

    test('HABIT_NOT_FOUND → HabitUnauthorizedFailure (ownership raté)', () {
      expect(
        mapHabitPostgrestException(_rpc('HABIT_NOT_FOUND')),
        isA<HabitUnauthorizedFailure>(),
      );
    });

    test('AUTH_REQUIRED → HabitUnauthorizedFailure', () {
      expect(
        mapHabitPostgrestException(_rpc('AUTH_REQUIRED')),
        isA<HabitUnauthorizedFailure>(),
      );
    });

    test('INVALID_STATUS → HabitDatabaseFailure', () {
      expect(
        mapHabitPostgrestException(_rpc('INVALID_STATUS')),
        isA<HabitDatabaseFailure>(),
      );
    });

    test('match exact — message composite non reconnu → HabitDatabaseFailure', () {
      // Vérifie que le switch utilise == et non .contains().
      expect(
        mapHabitPostgrestException(_pg('P0001', 'error: FUTURE_LOG_NOT_ALLOWED detail')),
        isA<HabitDatabaseFailure>(),
      );
    });
  });
}
