// Tests #190 — vérifie que [SupabaseHabitDataSource] appelle
// `ensureFreshSession()` AVANT toute requête Supabase. Sans mocker la
// fluent API Supabase (cf. convention repo), on s'appuie sur une exception
// sentinelle levée par le `SessionRefresher` du wrapper : si le datasource
// appelle bien le wrapper en première ligne, la sentinelle remonte avant
// tout accès au client → preuve d'ordre.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_habit_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'jwt_refresh_test_helpers.dart';

class _MockSupabaseClient extends Mock implements sb.SupabaseClient {}

void main() {
  late JwtRefreshHarness harness;
  late _MockSupabaseClient client;
  late SupabaseHabitDataSource ds;

  setUp(() {
    harness = JwtRefreshHarness.refreshThrows();
    client = _MockSupabaseClient();
    ds = SupabaseHabitDataSource(client, wrapper: harness.wrapper);
  });

  group(
    'SupabaseHabitDataSource — ensureFreshSession() called first (#190)',
    () {
      test('getHabits appelle ensureFreshSession avant le client', () async {
        await expectLater(
          ds.getHabits('user-1'),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('createHabit appelle ensureFreshSession avant le client', () async {
        await expectLater(
          ds.createHabit({'id': 'h1'}),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('updateHabit appelle ensureFreshSession avant le client', () async {
        await expectLater(
          ds.updateHabit({'id': 'h1'}),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('deleteHabit appelle ensureFreshSession avant le client', () async {
        await expectLater(
          ds.deleteHabit('h1'),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test(
        'upsertHabitLog appelle ensureFreshSession avant le client',
        () async {
          await expectLater(
            ds.upsertHabitLog({'habit_id': 'h1', 'date': '2026-05-23'}),
            throwsA(isA<JwtRefreshSentinelException>()),
          );
          verify(() => harness.refresher.refresh()).called(1);
          verifyZeroInteractions(client);
        },
      );

      test(
        'getLogsForHabit appelle ensureFreshSession avant le client',
        () async {
          await expectLater(
            ds.getLogsForHabit(
              habitId: 'h1',
              from: '2026-05-01',
              to: '2026-05-23',
            ),
            throwsA(isA<JwtRefreshSentinelException>()),
          );
          verify(() => harness.refresher.refresh()).called(1);
          verifyZeroInteractions(client);
        },
      );

      test(
        'toggleHabitLog appelle ensureFreshSession avant le client',
        () async {
          await expectLater(
            ds.toggleHabitLog(
              habitId: 'h1',
              date: DateTime.utc(2026, 5, 23),
              status: 'done',
            ),
            throwsA(isA<JwtRefreshSentinelException>()),
          );
          verify(() => harness.refresher.refresh()).called(1);
          verifyZeroInteractions(client);
        },
      );

      test(
        'getHabitsForCollection appelle ensureFreshSession avant le client',
        () async {
          await expectLater(
            ds.getHabitsForCollection('col-1'),
            throwsA(isA<JwtRefreshSentinelException>()),
          );
          verify(() => harness.refresher.refresh()).called(1);
          verifyZeroInteractions(client);
        },
      );
    },
  );
}
