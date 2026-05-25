import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/core/utils/action_serializer.dart';

void main() {
  group('ActionSerializer', () {
    test('exécute l\'action et renvoie le résultat quand idle', () async {
      final serializer = ActionSerializer();
      final result = await serializer.run<int>(() async => 42);
      expect(result, 42);
    });

    test('deuxième appel concurrent ignoré (renvoie null) pendant que le '
        'premier est en cours', () async {
      final serializer = ActionSerializer();
      final completer = Completer<int>();

      final first = serializer.run<int>(() => completer.future);

      // L'action est en cours — un second appel doit être ignoré.
      final second = await serializer.run<int>(() async => 99);
      expect(second, isNull);

      completer.complete(7);
      expect(await first, 7);
    });

    test(
      'libère le verrou après une exception et permet un nouvel appel',
      () async {
        final serializer = ActionSerializer();

        Object? caught;
        try {
          await serializer.run<int>(() async => throw StateError('boom'));
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<StateError>());

        // Nouvel appel après échec → exécuté normalement.
        final result = await serializer.run<int>(() async => 1);
        expect(result, 1);
      },
    );

    test('appel séquentiel après complétion est autorisé', () async {
      final serializer = ActionSerializer();
      expect(await serializer.run<int>(() async => 1), 1);
      expect(await serializer.run<int>(() async => 2), 2);
      expect(await serializer.run<int>(() async => 3), 3);
    });
  });
}
