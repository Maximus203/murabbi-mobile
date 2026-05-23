import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/core/utils/ownership_guard.dart';
import 'package:murabbi_mobile/domain/errors/habit_failure.dart';

class _Guarded with OwnershipGuard {}

void main() {
  group('OwnershipGuard.assertOwnership (issue #202 / M3)', () {
    final guard = _Guarded();

    test('ne lève rien si requestedId == currentId', () {
      expect(
        () => guard.assertOwnership(
          requestedId: 'u1',
          currentId: 'u1',
          failureIfMismatch: const HabitFailure.unauthorized(),
        ),
        returnsNormally,
      );
    });

    test('lève la failure typée si requestedId != currentId — avant tout appel '
        'réseau', () {
      expect(
        () => guard.assertOwnership(
          requestedId: 'u1',
          currentId: 'u2',
          failureIfMismatch: const HabitFailure.unauthorized(
            message: 'ownership mismatch',
          ),
        ),
        throwsA(isA<HabitUnauthorizedFailure>()),
      );
    });

    test(
      'lève précisément la failure passée en paramètre (transparente au type)',
      () {
        Object? caught;
        try {
          guard.assertOwnership(
            requestedId: 'a',
            currentId: 'b',
            failureIfMismatch: const HabitFailure.unauthorized(message: 'X'),
          );
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<HabitFailure>());
        expect((caught! as HabitFailure).message, 'X');
      },
    );
  });
}
