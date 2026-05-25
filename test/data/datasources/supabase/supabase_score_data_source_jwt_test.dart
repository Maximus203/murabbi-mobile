// Tests #190 — SupabaseScoreDataSource appelle ensureFreshSession()
// en tête de chaque méthode publique. Voir
// `supabase_habit_data_source_jwt_test.dart` pour la stratégie générale.
//
// Couvre aussi #199 (M10) : `getUserScore` route via RPC `get_user_score`,
// mais le test n'a pas besoin d'observer l'appel RPC — il vérifie seulement
// que l'ordre est respecté (wrapper d'abord, aucune interaction client
// avant `ensureFreshSession()` succès).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_score_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'jwt_refresh_test_helpers.dart';

class _MockSupabaseClient extends Mock implements sb.SupabaseClient {}

void main() {
  late JwtRefreshHarness harness;
  late _MockSupabaseClient client;
  late SupabaseScoreDataSource ds;

  setUp(() {
    harness = JwtRefreshHarness.refreshThrows();
    client = _MockSupabaseClient();
    ds = SupabaseScoreDataSource(client, wrapper: harness.wrapper);
  });

  group(
    'SupabaseScoreDataSource — ensureFreshSession() called first (#190)',
    () {
      test('getUserScore', () async {
        await expectLater(
          ds.getUserScore('u1'),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('getLeaderboard', () async {
        await expectLater(
          ds.getLeaderboard(limit: 10),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });
    },
  );
}
