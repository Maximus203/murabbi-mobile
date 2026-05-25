// Tests #190 — SupabaseSalatDataSource appelle ensureFreshSession()
// en tête de chaque méthode publique. Voir
// `supabase_habit_data_source_jwt_test.dart` pour la stratégie générale.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_salat_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'jwt_refresh_test_helpers.dart';

class _MockSupabaseClient extends Mock implements sb.SupabaseClient {}

void main() {
  late JwtRefreshHarness harness;
  late _MockSupabaseClient client;
  late SupabaseSalatDataSource ds;

  setUp(() {
    harness = JwtRefreshHarness.refreshThrows();
    client = _MockSupabaseClient();
    ds = SupabaseSalatDataSource(client, wrapper: harness.wrapper);
  });

  group(
    'SupabaseSalatDataSource — ensureFreshSession() called first (#190)',
    () {
      test('getPrayerDay', () async {
        await expectLater(
          ds.getPrayerDay(userId: 'u1', day: '2026-05-23'),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('upsertPrayerDay', () async {
        await expectLater(
          ds.upsertPrayerDay({'user_id': 'u1', 'day': '2026-05-23'}),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('getPrayerDaysRange', () async {
        await expectLater(
          ds.getPrayerDaysRange(
            userId: 'u1',
            from: '2026-05-01',
            to: '2026-05-23',
          ),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });
    },
  );
}
