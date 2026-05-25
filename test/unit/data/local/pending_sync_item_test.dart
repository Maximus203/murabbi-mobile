import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/local/pending_sync_item.dart';

void main() {
  group('PendingSyncItem', () {
    final base = PendingSyncItem(
      id: 'item-001',
      type: SyncItemType.logHabit,
      payload: {'habitId': 'h1', 'userId': 'u1', 'status': 'done'},
      createdAt: DateTime(2026, 5, 24, 10),
    );

    test('isPending est true par défaut', () {
      expect(base.isPending, isTrue);
      expect(base.isFailed, isFalse);
    });

    test('incrementRetry incrémente retryCount', () {
      final r1 = base.incrementRetry();
      expect(r1.retryCount, 1);
      expect(r1.status, SyncItemStatus.pending);
    });

    test('incrementRetry passe en failed après maxRetries tentatives', () {
      var item = base;
      for (int i = 0; i < PendingSyncItem.maxRetries; i++) {
        item = item.incrementRetry();
      }
      expect(item.retryCount, PendingSyncItem.maxRetries);
      expect(item.status, SyncItemStatus.failed);
      expect(item.isFailed, isTrue);
      expect(item.isPending, isFalse);
    });

    test('toMap / fromMap roundtrip', () {
      final map = base.toMap();
      final restored = PendingSyncItem.fromMap(map);
      expect(restored.id, base.id);
      expect(restored.type, base.type);
      expect(restored.payload, base.payload);
      expect(
        restored.createdAt.toIso8601String(),
        base.createdAt.toIso8601String(),
      );
      expect(restored.retryCount, base.retryCount);
      expect(restored.status, base.status);
    });

    test('SyncItemType.logPrayer roundtrips correctement', () {
      final item = base.copyWith(type: SyncItemType.logPrayer);
      final restored = PendingSyncItem.fromMap(item.toMap());
      expect(restored.type, SyncItemType.logPrayer);
    });

    test('payload JSON complexe roundtrip', () {
      final item = base.copyWith(
        payload: {
          'habitId': 'h1',
          'date': '2026-05-24',
          'nested': {'a': 1, 'b': 'test'},
        },
      );
      final restored = PendingSyncItem.fromMap(item.toMap());
      expect(restored.payload['nested'], {'a': 1, 'b': 'test'});
    });
  });
}
