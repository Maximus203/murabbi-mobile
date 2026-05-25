import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/remembered_accounts_notifier.dart';
import 'package:murabbi_mobile/services/remembered_accounts_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('RememberedAccountsNotifier', () {
    test(
      'build() retourne une liste vide quand aucun email persisté',
      () async {
        final container = makeContainer();
        final emails = await container.read(
          rememberedAccountsNotifierProvider.future,
        );
        expect(emails, isEmpty);
      },
    );

    test('remember() ajoute en tête et propage le state', () async {
      final container = makeContainer();
      await container.read(rememberedAccountsNotifierProvider.future);

      await container
          .read(rememberedAccountsNotifierProvider.notifier)
          .remember('cherif@example.com');

      final state = container
          .read(rememberedAccountsNotifierProvider)
          .requireValue;
      expect(state, ['cherif@example.com']);
    });

    test('remember() applique LRU + normalisation lowercase/trim', () async {
      final container = makeContainer();
      final notifier = container.read(
        rememberedAccountsNotifierProvider.notifier,
      );
      await container.read(rememberedAccountsNotifierProvider.future);

      await notifier.remember('  ALICE@Example.COM  ');
      await notifier.remember('bob@example.com');
      await notifier.remember('alice@example.com'); // remonte en tête

      final state = container
          .read(rememberedAccountsNotifierProvider)
          .requireValue;
      expect(state, ['alice@example.com', 'bob@example.com']);
    });

    test('forget() retire l\'email et propage le state', () async {
      final container = makeContainer();
      final notifier = container.read(
        rememberedAccountsNotifierProvider.notifier,
      );
      await container.read(rememberedAccountsNotifierProvider.future);

      await notifier.remember('a@a.co');
      await notifier.remember('b@b.co');
      await notifier.forget('a@a.co');

      final state = container
          .read(rememberedAccountsNotifierProvider)
          .requireValue;
      expect(state, ['b@b.co']);
    });

    test('plafond LRU : 6e remember évince le plus ancien', () async {
      final container = makeContainer();
      final notifier = container.read(
        rememberedAccountsNotifierProvider.notifier,
      );
      await container.read(rememberedAccountsNotifierProvider.future);

      for (var i = 0; i < RememberedAccountsStorage.maxAccounts + 1; i++) {
        await notifier.remember('user$i@example.com');
      }

      final state = container
          .read(rememberedAccountsNotifierProvider)
          .requireValue;
      expect(state.length, RememberedAccountsStorage.maxAccounts);
      expect(state, isNot(contains('user0@example.com')));
    });
  });
}
