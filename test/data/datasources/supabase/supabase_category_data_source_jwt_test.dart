// Tests #190 — SupabaseCategoryDataSource appelle ensureFreshSession()
// en tête de chaque méthode publique. Voir
// `supabase_habit_data_source_jwt_test.dart` pour la stratégie générale.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_category_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'jwt_refresh_test_helpers.dart';

class _MockSupabaseClient extends Mock implements sb.SupabaseClient {}

void main() {
  late JwtRefreshHarness harness;
  late _MockSupabaseClient client;
  late SupabaseCategoryDataSource ds;

  setUp(() {
    harness = JwtRefreshHarness.refreshThrows();
    client = _MockSupabaseClient();
    ds = SupabaseCategoryDataSource(client, wrapper: harness.wrapper);
  });

  group(
    'SupabaseCategoryDataSource — ensureFreshSession() called first (#190)',
    () {
      test('getCategories', () async {
        await expectLater(
          ds.getCategories('user-1'),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('createCategory', () async {
        await expectLater(
          ds.createCategory({'id': 'c1'}),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('updateCategory', () async {
        await expectLater(
          ds.updateCategory({'id': 'c1'}),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('deleteCategory', () async {
        await expectLater(
          ds.deleteCategory('c1'),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });
    },
  );
}
