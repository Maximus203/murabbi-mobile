import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/user_mapper.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';

void main() {
  Map<String, dynamic> authMap({
    String id = '11111111-1111-1111-1111-111111111111',
    String email = 'cherif@example.com',
    String createdAt = '2026-01-01T00:00:00Z',
  }) => {'id': id, 'email': email, 'created_at': createdAt};

  Map<String, dynamic> profileMap({
    String displayName = 'Cherif',
    int totalPoints = 0,
  }) => {'display_name': displayName, 'total_points': totalPoints};

  group('UserMapper.fromMaps', () {
    test('maps a freshly-created profile to a Level.aspirant user', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileMap(),
      );

      expect(user.id.value, '11111111-1111-1111-1111-111111111111');
      expect(user.email.value, 'cherif@example.com');
      expect(user.displayName.value, 'Cherif');
      expect(user.createdAt, DateTime.parse('2026-01-01T00:00:00Z'));
      expect(user.level, Level.aspirant);
    });

    test('derives Level from total_points via Level.fromPoints', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileMap(totalPoints: 50000),
      );
      expect(user.level, Level.salik);
    });

    test('throws ArgumentError when display_name is empty', () {
      expect(
        () => UserMapper.fromMaps(
          authUser: authMap(),
          profile: profileMap(displayName: ''),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when email is missing', () {
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
  });
}
