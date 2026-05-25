import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/errors/collection_failure.dart';

void main() {
  group('CollectionFailure —', () {
    test('factory network crée CollectionNetworkFailure', () {
      const f = CollectionFailure.network(message: 'timeout');
      expect(f, isA<CollectionNetworkFailure>());
      expect(f.message, 'timeout');
    });

    test('factory database crée CollectionDatabaseFailure', () {
      const f = CollectionFailure.database(message: 'pgerr');
      expect(f, isA<CollectionDatabaseFailure>());
      expect(f.message, 'pgerr');
    });

    test('factory notFound crée CollectionNotFoundFailure', () {
      const f = CollectionFailure.notFound();
      expect(f, isA<CollectionNotFoundFailure>());
      expect(f.message, isNull);
    });

    test('factory unknown crée CollectionUnknownFailure', () {
      const f = CollectionFailure.unknown(message: 'oops');
      expect(f, isA<CollectionUnknownFailure>());
    });

    test('égalité structurelle — même type + message', () {
      const a = CollectionFailure.database(message: 'err');
      const b = CollectionFailure.database(message: 'err');
      expect(a, equals(b));
    });

    test('inégalité — types différents', () {
      const a = CollectionFailure.network();
      const b = CollectionFailure.database();
      expect(a, isNot(equals(b)));
    });

    test('est une Exception (peut être throwé/catché)', () {
      expect(
        () => throw const CollectionFailure.network(),
        throwsA(isA<CollectionFailure>()),
      );
    });

    test('toString contient le runtimeType', () {
      const f = CollectionFailure.notFound(message: 'x');
      expect(f.toString(), contains('CollectionNotFoundFailure'));
      expect(f.toString(), contains('x'));
    });
  });
}
