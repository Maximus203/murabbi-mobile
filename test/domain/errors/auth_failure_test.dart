import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';

void main() {
  group('AuthFailure', () {
    test(
      'invalidCredentials carries an optional message and equality holds',
      () {
        const a = AuthFailure.invalidCredentials();
        const b = AuthFailure.invalidCredentials();
        const c = AuthFailure.invalidCredentials(message: 'wrong pass');
        expect(a, b);
        expect(a, isNot(c));
      },
    );

    test(
      'emailAlreadyInUse / weakPassword / network / unknown are distinct',
      () {
        const inUse = AuthFailure.emailAlreadyInUse();
        const weak = AuthFailure.weakPassword();
        const network = AuthFailure.network();
        const unknown = AuthFailure.unknown(message: 'boom');

        expect(inUse, isNot(weak));
        expect(inUse, isNot(network));
        expect(network, isNot(unknown));
        expect(unknown, const AuthFailure.unknown(message: 'boom'));
      },
    );

    test('is an Exception (can be thrown/caught)', () {
      expect(
        () => throw const AuthFailure.invalidCredentials(),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        () => throw const AuthFailure.network(),
        throwsA(isA<Exception>()),
      );
    });

    test('exhaustive switch on subtypes (compile-time safety)', () {
      String describe(AuthFailure f) => switch (f) {
        InvalidCredentialsFailure() => 'invalid',
        EmailAlreadyInUseFailure() => 'in-use',
        WeakPasswordFailure() => 'weak',
        NetworkFailure() => 'network',
        AccountDeletedFailure() => 'deleted',
        UnknownAuthFailure() => 'unknown',
      };

      expect(describe(const AuthFailure.invalidCredentials()), 'invalid');
      expect(describe(const AuthFailure.emailAlreadyInUse()), 'in-use');
      expect(describe(const AuthFailure.weakPassword()), 'weak');
      expect(describe(const AuthFailure.network()), 'network');
      expect(describe(const AuthFailure.accountDeleted()), 'deleted');
      expect(describe(const AuthFailure.unknown()), 'unknown');
    });
  });
}
