import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/user_mapper.dart';

/// Q-26 Option A — [UserMapper.fromMaps] lit la colonne `display_name`
/// de `public.users` (migration à appliquer côté murabbi-admin).
///
/// La colonne est TEXT nullable : absente ou null → `User.displayName` null.
/// Présente et non vide → projetée dans `User.displayName`.
void main() {
  Map<String, dynamic> authMap() => {
    'id': '11111111-1111-1111-1111-111111111111',
    'email': 'a@b.co',
    'created_at': '2026-01-01T00:00:00Z',
  };

  /// Profil sans `display_name` (row pré-migration).
  Map<String, dynamic> baseProfile() => {
    'pseudo': 'cherif',
    'pseudo_full': 'cherif#4231',
    'email': 'a@b.co',
    'level': 'murid',
    'current_streak': 0,
    'completion_rate': 0,
    'deletion_requested_at': null,
  };

  /// Profil avec `display_name` explicite.
  Map<String, dynamic> profileWithDisplayName(Object? value) => {
    ...baseProfile(),
    'display_name': value,
  };

  group('UserMapper.fromMaps — display_name (Q-26 Option A)', () {
    test('reads display_name when present and non-empty', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileWithDisplayName('Cherif Diouf'),
      );
      expect(user.displayName, 'Cherif Diouf');
    });

    test('displayPseudo returns displayName when set', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileWithDisplayName('Cherif Diouf'),
      );
      expect(user.displayPseudo, 'Cherif Diouf');
    });

    test('returns null displayName when column absent (pre-migration row)', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: baseProfile(),
      );
      expect(user.displayName, isNull);
    });

    test('returns null displayName when column present but null', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileWithDisplayName(null),
      );
      expect(user.displayName, isNull);
    });

    test('returns null displayName when column is empty string', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileWithDisplayName(''),
      );
      expect(user.displayName, isNull);
    });

    test('displayPseudo falls back to pseudoFull when displayName absent', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: baseProfile(),
      );
      expect(user.displayPseudo, 'cherif#4231');
    });
  });
}
