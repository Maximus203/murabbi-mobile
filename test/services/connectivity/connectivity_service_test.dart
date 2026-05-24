import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/services/connectivity/connectivity_service.dart';

/// Fake injectable — émet la séquence fournie par les tests.
class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService({
    required this.initialOnline,
    required this.changes,
  });

  final bool initialOnline;
  final Stream<bool> changes;

  @override
  Future<bool> isOnline() async => initialOnline;

  @override
  Stream<bool> onConnectivityChanged() => changes;
}

void main() {
  group('connectivityProvider', () {
    test('émet d\'abord le statut initial via isOnline()', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(
            _FakeConnectivityService(
              initialOnline: true,
              changes: const Stream.empty(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Le StreamProvider commence en loading puis bascule sur la 1re valeur.
      final first = await container.read(connectivityProvider.future);
      expect(first, isTrue);
    });

    test('relaie les changements de statut online → offline', () async {
      final controller = StreamController<bool>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(
            _FakeConnectivityService(
              initialOnline: true,
              changes: controller.stream,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Capture toutes les valeurs émises par le provider.
      final emitted = <bool>[];
      container.listen<AsyncValue<bool>>(connectivityProvider, (_, next) {
        next.whenData(emitted.add);
      }, fireImmediately: true);

      // Laisse passer le yield initial (isOnline()).
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [true]);

      // Émet une perte de connexion.
      controller.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [true, false]);

      // Retour à la normale.
      controller.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [true, false, true]);
    });
  });
}
