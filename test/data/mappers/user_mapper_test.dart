import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/user_mapper.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';

void main() {
  Map<String, dynamic> authMap({
    String id = '11111111-1111-1111-1111-111111111111',
    String email = 'cherif@example.com',
    String createdAt = '2026-01-01T00:00:00Z',
  }) => {'id': id, 'email': email, 'created_at': createdAt};

  Map<String, dynamic> profileMap({
    String pseudo = 'Cherif',
    String level = 'aspirant',
    int totalPoints = 0,
    int currentStreak = 0,
    num completionRate = 0,
    Object? deletionRequestedAt,
  }) => {
    'pseudo': pseudo,
    'email': 'cherif@example.com',
    'level': level,
    'total_points': totalPoints,
    'current_streak': currentStreak,
    'completion_rate': completionRate,
    'deletion_requested_at': deletionRequestedAt,
  };

  group('UserMapper.fromMaps (users schema, Q-18)', () {
    test('maps a fresh row to an aspirant user with defaults', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileMap(),
      );

      expect(user.id.value, '11111111-1111-1111-1111-111111111111');
      expect(user.email.value, 'cherif@example.com');
      expect(user.pseudo.value, 'Cherif');
      expect(user.createdAt, DateTime.parse('2026-01-01T00:00:00Z'));
      expect(user.level, Level.aspirant);
      expect(user.currentStreak, 0);
      expect(user.completionRate, 0);
    });

    test('reads level enum string directly from DB (no derivation)', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileMap(level: 'salik', totalPoints: 50000),
      );
      // Important : le niveau vient du DB (Q-18), pas de fromPoints.
      expect(user.level, Level.salik);
    });

    test('throws ArgumentError on unknown level string', () {
      expect(
        () => UserMapper.fromMaps(
          authUser: authMap(),
          profile: profileMap(level: 'wizard'),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when pseudo is empty', () {
      expect(
        () => UserMapper.fromMaps(
          authUser: authMap(),
          profile: profileMap(pseudo: ''),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when email is missing in authUser', () {
      expect(
        () => UserMapper.fromMaps(
          authUser: {
            'id': '11111111-1111-1111-1111-111111111111',
            'created_at': '2026-01-01T00:00:00Z',
          },
          profile: profileMap(),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when total_points is negative', () {
      expect(
        () => UserMapper.fromMaps(
          authUser: authMap(),
          profile: profileMap(totalPoints: -1),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when current_streak is negative', () {
      expect(
        () => UserMapper.fromMaps(
          authUser: authMap(),
          profile: profileMap(currentStreak: -1),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when completion_rate is negative', () {
      expect(
        () => UserMapper.fromMaps(
          authUser: authMap(),
          profile: profileMap(completionRate: -0.01),
        ),
        throwsArgumentError,
      );
    });

    test('parses created_at when given as DateTime instead of String', () {
      final dt = DateTime.utc(2026, 5, 1, 12);
      final user = UserMapper.fromMaps(
        authUser: {
          'id': '11111111-1111-1111-1111-111111111111',
          'email': 'a@b.co',
          'created_at': dt,
        },
        profile: profileMap(),
      );
      expect(user.createdAt, dt);
    });

    test('preserves currentStreak and completionRate from row', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileMap(currentStreak: 12, completionRate: 87.5),
      );
      expect(user.currentStreak, 12);
      expect(user.completionRate, 87.5);
    });

    test('throws AuthFailure.accountDeleted when deletion_requested_at is set '
        '(ADR-011)', () {
      expect(
        () => UserMapper.fromMaps(
          authUser: authMap(),
          profile: profileMap(deletionRequestedAt: '2026-05-01T00:00:00Z'),
        ),
        throwsA(isA<AccountDeletedFailure>()),
      );
    });
  });
}
