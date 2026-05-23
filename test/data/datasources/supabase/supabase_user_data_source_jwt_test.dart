// Tests #190 — SupabaseUserDataSource appelle ensureFreshSession()
// en tête de chaque méthode publique. Voir
// `supabase_habit_data_source_jwt_test.dart` pour la stratégie générale.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_user_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'jwt_refresh_test_helpers.dart';

class _MockSupabaseClient extends Mock implements sb.SupabaseClient {}

void main() {
  late JwtRefreshHarness harness;
  late _MockSupabaseClient client;
  late SupabaseUserDataSource ds;

  setUp(() {
    harness = JwtRefreshHarness.refreshThrows();
    client = _MockSupabaseClient();
    ds = SupabaseUserDataSource(client, wrapper: harness.wrapper);
  });

  group(
    'SupabaseUserDataSource — ensureFreshSession() called first (#190)',
    () {
      test('updatePseudo', () async {
        await expectLater(
          ds.updatePseudo(userId: 'u1', pseudo: 'Cherif'),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });
    },
  );
}
