import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/services/remembered_accounts_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late RememberedAccountsStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = RememberedAccountsStorage(prefs);
  });

  group('RememberedAccountsStorage', () {
    test('getAll returns empty list when nothing persisted', () {
      expect(storage.getAll(), isEmpty);
    });

    test('remember persists a single email', () async {
      await storage.remember('Cherif@Example.COM');
      expect(storage.getAll(), ['cherif@example.com']);
    });

    test('remember normalizes to lowercase + trim', () async {
      await storage.remember('  Cherif@Example.COM  ');
      expect(storage.getAll(), ['cherif@example.com']);
    });

    test('remember ignores empty email', () async {
      await storage.remember('   ');
      expect(storage.getAll(), isEmpty);
    });

    test('remember moves existing entry to front (LRU)', () async {
      await storage.remember('a@a.co');
      await storage.remember('b@b.co');
      await storage.remember('a@a.co');
      expect(storage.getAll(), ['a@a.co', 'b@b.co']);
    });

    test('remember caps at maxAccounts (LRU eviction)', () async {
      for (var i = 0; i < RememberedAccountsStorage.maxAccounts + 3; i++) {
        await storage.remember('user$i@example.com');
      }
      final all = storage.getAll();
      expect(all.length, RememberedAccountsStorage.maxAccounts);
      // Le plus récent doit être en tête, le plus ancien évincé.
      expect(
        all.first,
        'user${RememberedAccountsStorage.maxAccounts + 2}@example.com',
      );
      expect(all, isNot(contains('user0@example.com')));
    });

    test('forget removes one email and keeps the rest', () async {
      await storage.remember('a@a.co');
      await storage.remember('b@b.co');
      await storage.forget('a@a.co');
      expect(storage.getAll(), ['b@b.co']);
    });

    test('forget is a no-op when email is not present', () async {
      await storage.remember('a@a.co');
      await storage.forget('zzz@nothere.co');
      expect(storage.getAll(), ['a@a.co']);
    });

    test('clear empties the list', () async {
      await storage.remember('a@a.co');
      await storage.remember('b@b.co');
      await storage.clear();
      expect(storage.getAll(), isEmpty);
    });
  });
}
