import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/app.dart';
import 'package:murabbi_mobile/services/sync/sync_service.dart';
import '../helpers/test_uuids.dart';

class _MockSyncService extends Mock implements SyncService {}

/// Fixture alignée sur la table `users` (database_schema.md) :
/// - id     : uuid (format standard)
/// - pseudo : text 1..30 chars
/// - email  : text non vide
/// - level  : 'aspirant' (DEFAULT côté DB)
/// - current_streak : 0 (DEFAULT)
/// - completion_rate : 0.0 (DEFAULT)
final _testUser = User(
  id: UserId(kUserIdAlpha),
  pseudo: Pseudonym('Ibrahim'),
  email: NonEmptyString('ibrahim@example.com'),
  createdAt: DateTime(2026, 1, 1),
  level: Level.aspirant,
  currentStreak: 0,
  completionRate: 0.0,
);

void main() {
  late _MockSyncService mockSync;

  setUp(() {
    mockSync = _MockSyncService();
    when(() => mockSync.processPendingQueue()).thenAnswer((_) async {});
  });

  group('runStartupSync', () {
    test('attend la résolution de l\'auth avant de lancer le sync', () async {
      // GIVEN : auth se résout avec un utilisateur connecté
      final authCompleter = Future<User?>.value(_testUser);

      // WHEN
      await runStartupSync(
        authFuture: authCompleter,
        syncService: mockSync,
      );

      // THEN : processPendingQueue a été appelé exactement une fois
      verify(() => mockSync.processPendingQueue()).called(1);
    });

    test('déclenche le sync même si l\'utilisateur est null (non connecté)',
        () async {
      // GIVEN : auth résolue mais sans session (onboarding, logout)
      final authCompleter = Future<User?>.value(null);

      // WHEN
      await runStartupSync(
        authFuture: authCompleter,
        syncService: mockSync,
      );

      // THEN : sync joué quand même — queue peut contenir des items anonymes
      verify(() => mockSync.processPendingQueue()).called(1);
    });

    test('ne joue pas le sync si auth n\'est pas encore résolue', () async {
      // GIVEN : auth bloquée (Completer non complété)
      final authCompleter = Completer<User?>();

      // WHEN : on ne await pas intentionnellement (simule le comportement
      // asynchrone de initState — le sync ne doit pas partir avant l'auth)
      final syncFuture = runStartupSync(
        authFuture: authCompleter.future,
        syncService: mockSync,
      );

      // THEN : aucun appel pendant que l'auth est pending
      verifyNever(() => mockSync.processPendingQueue());

      // Cleanup
      authCompleter.complete(null);
      await syncFuture;
    });
  });
}
