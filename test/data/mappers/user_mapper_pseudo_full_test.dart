import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/user_mapper.dart';

/// Issue #168 — `UserMapper.fromMaps` lit la colonne générée `pseudo_full`
/// de `public.users` (admin#125). La colonne est GENERATED ALWAYS AS
/// (`pseudo || '#' || pseudo_suffix::text`) STORED côté admin, donc :
///   - en lecture : on la projette dans `User.pseudoFull` ;
///   - en écriture : on ne doit JAMAIS l'envoyer dans un INSERT/UPDATE
///     (la base lèverait `cannot insert/update a generated column`).
void main() {
  Map<String, dynamic> authMap() => {
    'id': '11111111-1111-1111-1111-111111111111',
    'email': 'a@b.co',
    'created_at': '2026-01-01T00:00:00Z',
  };

  Map<String, dynamic> profileMap({
    String pseudo = 'ibrahim',
    Object? pseudoFull,
  }) => {
    'pseudo': pseudo,
    'pseudo_full': pseudoFull,
    'email': 'a@b.co',
    'level': 'aspirant',
    'current_streak': 0,
    'completion_rate': 0,
    'deletion_requested_at': null,
  };

  group('UserMapper.fromMaps — pseudo_full (issue #168)', () {
    test('reads pseudo_full when present in profile row', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileMap(pseudo: 'ibrahim', pseudoFull: 'ibrahim#4231'),
      );
      expect(user.pseudoFull, 'ibrahim#4231');
      expect(user.displayPseudo, 'ibrahim#4231');
    });

    test('returns null pseudoFull when column missing (pre-migration row)', () {
      // Ancienne ligne `users` sans la colonne `pseudo_full` (compatibilité
      // descendante tant que la migration admin n'est pas déployée).
      final profile = <String, dynamic>{
        'pseudo': 'ibrahim',
        'email': 'a@b.co',
        'level': 'aspirant',
        'current_streak': 0,
        'completion_rate': 0,
        'deletion_requested_at': null,
      };
      final user = UserMapper.fromMaps(authUser: authMap(), profile: profile);
      expect(user.pseudoFull, isNull);
      expect(user.displayPseudo, 'ibrahim');
    });

    test('returns null pseudoFull when column present but null', () {
      final user = UserMapper.fromMaps(
        authUser: authMap(),
        profile: profileMap(pseudoFull: null),
      );
      expect(user.pseudoFull, isNull);
    });
  });
}
