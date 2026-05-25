// Tests #190 — SupabaseCollectionDataSourceImpl appelle ensureFreshSession()
// en tête de chaque méthode publique. Voir
// `supabase_habit_data_source_jwt_test.dart` pour la stratégie générale.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_collection_data_source.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'jwt_refresh_test_helpers.dart';

class _MockSupabaseClient extends Mock implements sb.SupabaseClient {}

void main() {
  late JwtRefreshHarness harness;
  late _MockSupabaseClient client;
  late SupabaseCollectionDataSourceImpl ds;

  setUp(() {
    harness = JwtRefreshHarness.refreshThrows();
    client = _MockSupabaseClient();
    ds = SupabaseCollectionDataSourceImpl(client, wrapper: harness.wrapper);
  });

  group(
    'SupabaseCollectionDataSourceImpl — ensureFreshSession() called first (#190)',
    () {
      test('getCollections', () async {
        await expectLater(
          ds.getCollections(UserId('u1')),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('getHabitsForCollection', () async {
        await expectLater(
          ds.getHabitsForCollection('col-1'),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('activateCollection', () async {
        await expectLater(
          ds.activateCollection(
            collectionId: CollectionId('c1'),
            userId: UserId('u1'),
          ),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('deactivateCollection', () async {
        await expectLater(
          ds.deactivateCollection(
            collectionId: CollectionId('c1'),
            userId: UserId('u1'),
          ),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });

      test('createCollection', () async {
        final collection = Collection(
          id: CollectionId('c1'),
          name: NonEmptyString('Test'),
          description: NonEmptyString('Desc'),
          habitIds: [HabitId('h1')],
          isSystem: false,
          isActive: false,
          coverImageUrl: null,
        );
        await expectLater(
          ds.createCollection(collection: collection, userId: UserId('u1')),
          throwsA(isA<JwtRefreshSentinelException>()),
        );
        verify(() => harness.refresher.refresh()).called(1);
        verifyZeroInteractions(client);
      });
    },
  );
}
