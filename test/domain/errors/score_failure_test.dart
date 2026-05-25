import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/errors/score_failure.dart';

void main() {
  group('ScoreFailure —', () {
    test('factory network crée ScoreNetworkFailure', () {
      const f = ScoreFailure.network(message: 'timeout');
      expect(f, isA<ScoreNetworkFailure>());
      expect(f.message, 'timeout');
    });

    test('factory database crée ScoreDatabaseFailure', () {
      const f = ScoreFailure.database(message: 'pgerr');
      expect(f, isA<ScoreDatabaseFailure>());
      expect(f.message, 'pgerr');
    });

    test('factory notFound crée ScoreNotFoundFailure', () {
      const f = ScoreFailure.notFound();
      expect(f, isA<ScoreNotFoundFailure>());
      expect(f.message, isNull);
    });

    test('factory unknown crée ScoreUnknownFailure', () {
      const f = ScoreFailure.unknown(message: 'oops');
      expect(f, isA<ScoreUnknownFailure>());
    });

    test('égalité structurelle — même type + message', () {
      const a = ScoreFailure.database(message: 'err');
      const b = ScoreFailure.database(message: 'err');
      expect(a, equals(b));
    });

    test('inégalité — types différents', () {
      const a = ScoreFailure.network();
      const b = ScoreFailure.database();
      expect(a, isNot(equals(b)));
    });

    test('est une Exception (peut être throwé/catché)', () {
      expect(
        () => throw const ScoreFailure.network(),
        throwsA(isA<ScoreFailure>()),
      );
    });

    test('toString contient le runtimeType et le message', () {
      const f = ScoreFailure.notFound(message: 'missing');
      expect(f.toString(), contains('ScoreNotFoundFailure'));
      expect(f.toString(), contains('missing'));
    });
  });
}
