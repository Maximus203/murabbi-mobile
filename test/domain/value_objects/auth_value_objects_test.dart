import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/value_objects/email_address.dart';
import 'package:murabbi_mobile/domain/value_objects/password.dart';

void main() {
  group('EmailAddress', () {
    test(
      'accepts a well-formed email and exposes a normalized lowercase value',
      () {
        final email = EmailAddress('Cherif@Example.COM');
        expect(email.value, 'cherif@example.com');
      },
    );

    test('trims surrounding whitespace before validating', () {
      final email = EmailAddress('  hello@world.io  ');
      expect(email.value, 'hello@world.io');
    });

    test('rejects empty / whitespace-only input', () {
      expect(() => EmailAddress(''), throwsArgumentError);
      expect(() => EmailAddress('   '), throwsArgumentError);
    });

    test('rejects emails missing @ or domain or local part', () {
      expect(() => EmailAddress('plainaddress'), throwsArgumentError);
      expect(() => EmailAddress('@no-local.com'), throwsArgumentError);
      expect(() => EmailAddress('no-domain@'), throwsArgumentError);
      expect(() => EmailAddress('no-tld@example'), throwsArgumentError);
      expect(() => EmailAddress('two@@at.com'), throwsArgumentError);
      expect(() => EmailAddress('spaces in@email.com'), throwsArgumentError);
    });

    test('two EmailAddress with same normalized value are equal', () {
      expect(EmailAddress('A@B.com'), EmailAddress('a@b.com'));
    });
  });

  group('Password', () {
    test('accepts a password of at least 8 characters', () {
      final pwd = Password('hunter22');
      expect(pwd.value, 'hunter22');
    });

    test('rejects passwords shorter than 8 characters', () {
      expect(() => Password('short'), throwsArgumentError);
      expect(() => Password('1234567'), throwsArgumentError);
    });

    test('rejects empty password', () {
      expect(() => Password(''), throwsArgumentError);
    });

    test('does not trim — leading/trailing spaces are part of the secret', () {
      final pwd = Password(' hunter22 ');
      expect(pwd.value, ' hunter22 ');
    });

    test('toString never leaks the raw value', () {
      final pwd = Password('hunter22-secret');
      expect(pwd.toString(), isNot(contains('hunter22')));
      expect(pwd.toString(), isNot(contains('secret')));
    });

    test('two Password instances with same value are equal', () {
      expect(Password('hunter22'), Password('hunter22'));
    });
  });
}
