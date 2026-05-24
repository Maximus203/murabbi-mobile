import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/local/pending_sync_item.dart';
import 'package:murabbi_mobile/data/local/sqflite_sync_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialise sqflite sur desktop / CI (pas de Flutter channel requis).
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late SqfliteSyncDatabase db;

  setUp(() async {
    db = SqfliteSyncDatabase.inMemory();
    await db.init();
  });

  tearDown(() async {
    await db.close();
  });

  test('insert puis getPendingItems retourne les items triés FIFO', () async {
    final i1 = PendingSyncItem(
      id: 'item-001',
      type: SyncItemType.logHabit,
      payload: {'habitId': 'h1'},
      createdAt: DateTime(2026, 5, 24, 10, 0),
    );
    final i2 = PendingSyncItem(
      id: 'item-002',
      type: SyncItemType.logPrayer,
      payload: {'prayer': 'fajr'},
      createdAt: DateTime(2026, 5, 24, 10, 5),
    );

    await db.insert(i2); // inséré en second
    await db.insert(i1); // inséré en premier

    final items = await db.getPendingItems();
    expect(items, hasLength(2));
    expect(items.first.id, 'item-001'); // FIFO : createdAt plus ancien d'abord
    expect(items.last.id, 'item-002');
  });

  test('delete retire litem de la table', () async {
    final item = PendingSyncItem(
      id: 'item-del',
      type: SyncItemType.logHabit,
      payload: {},
      createdAt: DateTime(2026, 5, 24),
    );
    await db.insert(item);
    await db.delete(item.id);
    final items = await db.getPendingItems();
    expect(items, isEmpty);
  });

  test('update modifie retryCount et status', () async {
    final item = PendingSyncItem(
      id: 'item-upd',
      type: SyncItemType.logHabit,
      payload: {},
      createdAt: DateTime(2026, 5, 24),
    );
    await db.insert(item);

    final updated = item.incrementRetry().incrementRetry().incrementRetry();
    expect(updated.status, SyncItemStatus.failed);
    await db.update(updated);

    final items = await db.getPendingItems(); // failed → absent de getPending
    expect(items, isEmpty);

    // Vérification directe via getAllItems (inclut dead-letters)
    final all = await db.getAllItems();
    expect(all.first.retryCount, 3);
    expect(all.first.status, SyncItemStatus.failed);
  });

  test('getPendingItems exclut les items failed', () async {
    final pending = PendingSyncItem(
      id: 'item-pend',
      type: SyncItemType.logHabit,
      payload: {},
      createdAt: DateTime(2026, 5, 24, 10),
    );
    final failed = PendingSyncItem(
      id: 'item-fail',
      type: SyncItemType.logHabit,
      payload: {},
      createdAt: DateTime(2026, 5, 24, 11),
      retryCount: PendingSyncItem.maxRetries,
      status: SyncItemStatus.failed,
    );

    await db.insert(pending);
    await db.insert(failed);

    final items = await db.getPendingItems();
    expect(items, hasLength(1));
    expect(items.first.id, 'item-pend');
  });

  test('la DB survit à une réouverture (persistance)', () async {
    const dbPath = 'murabbi_sync_test_persist.db';
    final db1 = SqfliteSyncDatabase(dbPath: dbPath);
    await db1.init();

    await db1.insert(
      PendingSyncItem(
        id: 'survive-001',
        type: SyncItemType.logHabit,
        payload: {'x': 1},
        createdAt: DateTime(2026, 5, 24),
      ),
    );
    await db1.close();

    final db2 = SqfliteSyncDatabase(dbPath: dbPath);
    await db2.init();
    final items = await db2.getPendingItems();
    expect(items.any((i) => i.id == 'survive-001'), isTrue);
    await db2.close();

    // Nettoyage
    await databaseFactoryFfi.deleteDatabase(dbPath);
  });
}
