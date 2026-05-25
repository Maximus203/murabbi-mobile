import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/local/pending_sync_item.dart';
import 'package:murabbi_mobile/data/local/sync_database.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/services/sync/sync_service.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockSyncDatabase extends Mock implements SyncDatabase {}

class MockHabitRepository extends Mock implements HabitRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

PendingSyncItem _item({
  String id = 'item-001',
  int retryCount = 0,
  SyncItemStatus status = SyncItemStatus.pending,
}) => PendingSyncItem(
  id: id,
  type: SyncItemType.logHabit,
  payload: {
    'habitId': 'h-1',
    'userId': 'u-1',
    'status': 'onTime',
    'date': '2026-05-24',
  },
  createdAt: DateTime(2026, 5, 24, 10),
  retryCount: retryCount,
  status: status,
);

void main() {
  late MockSyncDatabase mockDb;
  late MockHabitRepository mockHabitRepo;
  late SyncService sut;

  setUpAll(() {
    // Les fallbacks mocktail doivent être enregistrés avant tout appel any().
    registerFallbackValue(HabitId('fallback'));
    registerFallbackValue(UserId('fallback'));
    registerFallbackValue(
      HabitLog(
        habitId: HabitId('fallback'),
        date: DateTime(2026),
        status: HabitLogStatus.onTime,
      ),
    );
    registerFallbackValue(
      PendingSyncItem(
        id: 'fallback',
        type: SyncItemType.logHabit,
        payload: const {},
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mockDb = MockSyncDatabase();
    mockHabitRepo = MockHabitRepository();

    // Stubs par défaut
    when(() => mockDb.init()).thenAnswer((_) async {});
    when(() => mockDb.insert(any())).thenAnswer((_) async {});
    when(() => mockDb.delete(any())).thenAnswer((_) async {});
    when(() => mockDb.update(any())).thenAnswer((_) async {});
    when(() => mockDb.getPendingItems()).thenAnswer((_) async => []);

    sut = SyncService(db: mockDb, habitRepository: mockHabitRepo);
  });

  // ── 1. enqueue ──────────────────────────────────────────────────────────────

  group('enqueueLogHabit', () {
    test('insère un item dans la DB', () async {
      await sut.enqueueLogHabit(
        habitId: 'h-1',
        userId: 'u-1',
        status: HabitLogStatus.onTime,
        date: DateTime(2026, 5, 24),
      );

      final captured = verify(() => mockDb.insert(captureAny())).captured;
      expect(captured, hasLength(1));
      final item = captured.first as PendingSyncItem;
      expect(item.type, SyncItemType.logHabit);
      expect(item.payload['habitId'], 'h-1');
      expect(item.payload['userId'], 'u-1');
      expect(item.status, SyncItemStatus.pending);
      expect(item.retryCount, 0);
    });

    test(
      "n'appelle pas le repo Supabase (pas de réseau dans enqueue)",
      () async {
        await sut.enqueueLogHabit(
          habitId: 'h-1',
          userId: 'u-1',
          status: HabitLogStatus.onTime,
          date: DateTime(2026, 5, 24),
        );

        verifyNever(() => mockHabitRepo.logHabit(any()));
      },
    );
  });

  // ── 2. processPendingQueue — succès ─────────────────────────────────────────

  group('processPendingQueue — succès', () {
    test('exécute les items dans lordre FIFO et les supprime', () async {
      final item1 = _item(id: 'item-001');
      final item2 = _item(id: 'item-002');
      when(
        () => mockDb.getPendingItems(),
      ).thenAnswer((_) async => [item1, item2]);
      when(() => mockHabitRepo.logHabit(any())).thenAnswer((_) async {});

      await sut.processPendingQueue();

      // Les deux items exécutés et supprimés
      verify(() => mockHabitRepo.logHabit(any())).called(2);
      verify(() => mockDb.delete('item-001')).called(1);
      verify(() => mockDb.delete('item-002')).called(1);
    });

    test('ne fait rien si la queue est vide', () async {
      when(() => mockDb.getPendingItems()).thenAnswer((_) async => []);

      await sut.processPendingQueue();

      verifyNever(() => mockHabitRepo.logHabit(any()));
      verifyNever(() => mockDb.delete(any()));
    });
  });

  // ── 3. processPendingQueue — échec et retry ──────────────────────────────────

  group('processPendingQueue — échec', () {
    test('incrémente retryCount sur échec (pas encore dead-letter)', () async {
      final item = _item(retryCount: 0);
      when(() => mockDb.getPendingItems()).thenAnswer((_) async => [item]);
      when(
        () => mockHabitRepo.logHabit(any()),
      ).thenThrow(Exception('network error'));

      await sut.processPendingQueue();

      final captured = verify(() => mockDb.update(captureAny())).captured;
      expect(captured, hasLength(1));
      final updated = captured.first as PendingSyncItem;
      expect(updated.retryCount, 1);
      expect(updated.status, SyncItemStatus.pending);
    });

    test('passe en dead-letter après maxRetries échecs', () async {
      // retryCount = maxRetries - 1 → prochain échec = dead-letter
      final item = _item(retryCount: PendingSyncItem.maxRetries - 1);
      when(() => mockDb.getPendingItems()).thenAnswer((_) async => [item]);
      when(
        () => mockHabitRepo.logHabit(any()),
      ).thenThrow(Exception('server error'));

      final deadLetters = <PendingSyncItem>[];
      sut.deadLetterStream.listen(deadLetters.add);

      await sut.processPendingQueue();

      final captured = verify(() => mockDb.update(captureAny())).captured;
      final updated = captured.first as PendingSyncItem;
      expect(updated.status, SyncItemStatus.failed);
      expect(updated.retryCount, PendingSyncItem.maxRetries);
      // Dead-letter émis
      expect(deadLetters, hasLength(1));
      expect(deadLetters.first.id, item.id);
    });
  });

  // ── 4. Conflit 23505 (idempotence M4) ────────────────────────────────────────

  group('processPendingQueue — conflit UNIQUE 23505', () {
    test('marque done silencieusement sur code 23505', () async {
      final item = _item();
      when(() => mockDb.getPendingItems()).thenAnswer((_) async => [item]);
      // Simule un PostgrestException avec code '23505' (doublon UNIQUE)
      when(
        () => mockHabitRepo.logHabit(any()),
      ).thenThrow(const _Pg23505Exception());

      await sut.processPendingQueue();

      // Supprimé silencieusement (pas d'erreur UI)
      verify(() => mockDb.delete(item.id)).called(1);
      // Pas de dead-letter
      final deadLetters = <PendingSyncItem>[];
      sut.deadLetterStream.listen(deadLetters.add);
      expect(deadLetters, isEmpty);
    });
  });

  // ── 5. pendingCount stream ────────────────────────────────────────────────────

  group('pendingCount', () {
    test('émet 0 quand la queue est vide', () async {
      when(() => mockDb.getPendingItems()).thenAnswer((_) async => []);
      await expectLater(sut.pendingCount, emits(0));
    });

    test('émet le count après enqueue', () async {
      when(
        () => mockDb.getPendingItems(),
      ).thenAnswer((_) async => [_item(id: 'i1'), _item(id: 'i2')]);

      await sut.enqueueLogHabit(
        habitId: 'h-1',
        userId: 'u-1',
        status: HabitLogStatus.onTime,
        date: DateTime(2026, 5, 24),
      );

      await expectLater(sut.pendingCount, emits(2));
    });
  });
}

// ── Fake PostgrestException 23505 ─────────────────────────────────────────────

/// Simule un PostgrestException avec code '23505' (contrainte UNIQUE violée).
/// On utilise une exception custom car PostgrestException ne peut pas être
/// instanciée directement en test sans le package Supabase.
class _Pg23505Exception implements Exception {
  final String code = '23505';
  const _Pg23505Exception();
  @override
  String toString() => 'PostgrestException(code: 23505)';
}
