import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/auth_data_source.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_impl.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockAuthDataSource extends Mock implements AuthDataSource {}

typedef AuthMaps = ({
  Map<String, dynamic> authUser,
  Map<String, dynamic> profile,
});

void main() {
  late MockAuthDataSource ds;
  late AuthRepositoryImpl repo;

  AuthMaps validMaps({Object? deletionRequestedAt}) => (
    authUser: const {
      'id': '11111111-1111-1111-1111-111111111111',
      'email': 'cherif@example.com',
      'created_at': '2026-01-01T00:00:00Z',
    },
    profile: {
      'pseudo': 'Cherif',
      'email': 'cherif@example.com',
      'level': 'aspirant',
      'total_points': 0,
      'current_streak': 0,
      'completion_rate': 0,
      'deletion_requested_at': deletionRequestedAt,
    },
  );

  setUp(() {
    ds = MockAuthDataSource();
    repo = AuthRepositoryImpl(ds);
  });

  group('signIn', () {
    test('returns mapped User on success', () async {
      when(
        () => ds.signInWithPassword(
          email: 'cherif@example.com',
          password: 'pass1234',
        ),
      ).thenAnswer((_) async => validMaps());

      final user = await repo.signIn(
        email: 'cherif@example.com',
        password: 'pass1234',
      );

      expect(user.email.value, 'cherif@example.com');
      expect(user.pseudo.value, 'Cherif');
    });

    test('throws AccountDeletedFailure when soft-delete flag is set', () async {
      when(
        () => ds.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => validMaps(deletionRequestedAt: '2026-05-01T00:00:00Z'),
      );

      expect(
        () => repo.signIn(email: 'a@b.co', password: 'pass1234'),
        throwsA(isA<AccountDeletedFailure>()),
      );
    });

    test(
      'translates "invalid credentials" exception to InvalidCredentialsFailure',
      () async {
        when(
          () => ds.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('Invalid login credentials'));

        expect(
          () => repo.signIn(email: 'a@b.co', password: 'pass1234'),
          throwsA(isA<InvalidCredentialsFailure>()),
        );
      },
    );

    test(
      'translates a network/SocketException-like error to NetworkFailure',
      () async {
        when(
          () => ds.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('SocketException: Failed host lookup'));

        expect(
          () => repo.signIn(email: 'a@b.co', password: 'pass1234'),
          throwsA(isA<NetworkFailure>()),
        );
      },
    );

    test('falls back to UnknownAuthFailure on unrecognized error', () async {
      when(
        () => ds.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(StateError('something weird'));

      expect(
        () => repo.signIn(email: 'a@b.co', password: 'pass1234'),
        throwsA(isA<UnknownAuthFailure>()),
      );
    });
  });

  group('signUp (Q-18 — no displayName param)', () {
    test('returns mapped User on success', () async {
      when(
        () => ds.signUp(email: 'cherif@example.com', password: 'pass1234'),
      ).thenAnswer((_) async => validMaps());

      final user = await repo.signUp(
        email: 'cherif@example.com',
        password: 'pass1234',
      );

      expect(user.pseudo.value, 'Cherif');
    });

    test(
      'translates "already registered" to EmailAlreadyInUseFailure',
      () async {
        when(
          () => ds.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('User already registered'));

        expect(
          () => repo.signUp(email: 'a@b.co', password: 'pass1234'),
          throwsA(isA<EmailAlreadyInUseFailure>()),
        );
      },
    );

    test(
      'translates "password should be at least" to WeakPasswordFailure',
      () async {
        when(
          () => ds.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('Password should be at least 6 characters'));

        expect(
          () => repo.signUp(email: 'a@b.co', password: 'pass1234'),
          throwsA(isA<WeakPasswordFailure>()),
        );
      },
    );
  });

  group('signInWithGoogle / sendPasswordResetEmail / signOut / deleteAccount', () {
    test('signInWithGoogle delegates and maps', () async {
      when(() => ds.signInWithGoogle()).thenAnswer((_) async => validMaps());
      final user = await repo.signInWithGoogle();
      expect(user.email.value, 'cherif@example.com');
    });

    test('signInWithGoogle throws AccountDeletedFailure on soft-delete', () {
      when(() => ds.signInWithGoogle()).thenAnswer(
        (_) async => validMaps(deletionRequestedAt: '2026-05-01T00:00:00Z'),
      );
      expect(
        () => repo.signInWithGoogle(),
        throwsA(isA<AccountDeletedFailure>()),
      );
    });

    test('sendPasswordResetEmail forwards email', () async {
      when(
        () => ds.sendPasswordResetEmail(email: 'a@b.co'),
      ).thenAnswer((_) async {});
      await repo.sendPasswordResetEmail(email: 'a@b.co');
      verify(() => ds.sendPasswordResetEmail(email: 'a@b.co')).called(1);
    });

    test('resendVerificationEmail forwards email', () async {
      when(
        () => ds.resendVerificationEmail(email: 'cherif@example.com'),
      ).thenAnswer((_) async {});
      await repo.resendVerificationEmail(email: 'cherif@example.com');
      verify(
        () => ds.resendVerificationEmail(email: 'cherif@example.com'),
      ).called(1);
    });

    test(
      'resendVerificationEmail translates rate-limit error to NetworkFailure',
      () async {
        when(
          () => ds.resendVerificationEmail(email: any(named: 'email')),
        ).thenThrow(
          Exception(
            'AuthApiException(message: For security purposes, you can only request this once every 60 seconds, code: over_email_send_rate_limit)',
          ),
        );
        expect(
          () => repo.resendVerificationEmail(email: 'a@b.co'),
          throwsA(isA<NetworkFailure>()),
        );
      },
    );

    test(
      'resendVerificationEmail translates SocketException-like error to NetworkFailure',
      () async {
        when(
          () => ds.resendVerificationEmail(email: any(named: 'email')),
        ).thenThrow(Exception('SocketException: Failed host lookup'));
        expect(
          () => repo.resendVerificationEmail(email: 'a@b.co'),
          throwsA(isA<NetworkFailure>()),
        );
      },
    );

    test(
      'resendVerificationEmail translates unexpected error to UnknownAuthFailure',
      () async {
        when(
          () => ds.resendVerificationEmail(email: any(named: 'email')),
        ).thenThrow(Exception('totally unexpected'));
        expect(
          () => repo.resendVerificationEmail(email: 'a@b.co'),
          throwsA(isA<UnknownAuthFailure>()),
        );
      },
    );

    test('signOut delegates', () async {
      when(() => ds.signOut()).thenAnswer((_) async {});
      await repo.signOut();
      verify(() => ds.signOut()).called(1);
    });

    test(
      'deleteAccount forwards UUID string (soft-delete in ADR-011)',
      () async {
        when(() => ds.deleteAccount('uid-1')).thenAnswer((_) async {});
        await repo.deleteAccount(UserId('uid-1'));
        verify(() => ds.deleteAccount('uid-1')).called(1);
      },
    );
  });

  group('getCurrentUser / authStateChanges', () {
    test('getCurrentUser returns null when datasource returns null', () async {
      when(() => ds.getCurrentUser()).thenAnswer((_) async => null);
      expect(await repo.getCurrentUser(), isNull);
    });

    test('getCurrentUser maps when datasource returns maps', () async {
      when(() => ds.getCurrentUser()).thenAnswer((_) async => validMaps());
      final user = await repo.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.email.value, 'cherif@example.com');
    });

    test('getCurrentUser throws AccountDeletedFailure on soft-delete', () {
      when(() => ds.getCurrentUser()).thenAnswer(
        (_) async => validMaps(deletionRequestedAt: '2026-05-01T00:00:00Z'),
      );
      expect(
        () => repo.getCurrentUser(),
        throwsA(isA<AccountDeletedFailure>()),
      );
    });

    test(
      'authStateChanges emits null/User mirror of datasource stream',
      () async {
        final controller = StreamController<AuthMaps?>();
        when(() => ds.authStateChanges).thenAnswer((_) => controller.stream);

        final emitted = <Object?>[];
        final sub = repo.authStateChanges.listen(emitted.add);

        controller
          ..add(null)
          ..add(validMaps())
          ..add(null);
        await Future<void>.delayed(Duration.zero);

        expect(emitted, hasLength(3));
        expect(emitted[0], isNull);
        expect(emitted[1], isNotNull);
        expect(emitted[2], isNull);

        await sub.cancel();
        await controller.close();
      },
    );
  });
}
