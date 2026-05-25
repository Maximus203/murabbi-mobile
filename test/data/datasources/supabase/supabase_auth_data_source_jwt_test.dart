// Tests #190 — SupabaseAuthDataSource : seules les méthodes
// "authentifiées qui appellent PostgREST" sont wrappées par
// ensureFreshSession(). Les méthodes d'auth (signIn, signUp, signOut,
// refreshSession, getCurrentUser, authStateChanges, OAuth, reset/resend
// password) NE doivent PAS l'appeler — chicken-and-egg (pas de session
// à rafraîchir, ou en cours d'établissement).
//
// Décision documentée dans la description de PR #190.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_auth_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'jwt_refresh_test_helpers.dart';

class _MockSupabaseClient extends Mock implements sb.SupabaseClient {}

void main() {
  late JwtRefreshHarness harness;
  late _MockSupabaseClient client;
  late SupabaseAuthDataSource ds;

  setUp(() {
    harness = JwtRefreshHarness.refreshThrows();
    client = _MockSupabaseClient();
    ds = SupabaseAuthDataSource(client, wrapper: harness.wrapper);
  });

  group(
    'SupabaseAuthDataSource — ensureFreshSession() called first (#190)',
    () {
      test(
        'deleteAccount appelle ensureFreshSession avant le client',
        () async {
          await expectLater(
            ds.deleteAccount('u1'),
            throwsA(isA<JwtRefreshSentinelException>()),
          );
          verify(() => harness.refresher.refresh()).called(1);
          verifyZeroInteractions(client);
        },
      );
    },
  );
}
