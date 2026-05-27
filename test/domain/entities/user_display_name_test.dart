// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Q-26 Option A — champ `displayName` (TEXT nullable) dans l'entité [User].
///
/// Migration requise côté admin : `ALTER TABLE users ADD COLUMN display_name TEXT;`
/// (murabbi-admin — à ouvrir en issue de suivi).
void main() {
  User makeUser({
    String pseudo = 'cherif',
    String? pseudoFull,
    String? displayName,
  }) {
    return User(
      id: UserId('11111111-1111-1111-1111-111111111111'),
      pseudo: Pseudonym(pseudo),
      email: NonEmptyString('cherif@example.com'),
      createdAt: DateTime.utc(2026, 1, 1),
      level: Level.murid,
      pseudoFull: pseudoFull,
      displayName: displayName,
    );
  }

  // ---------------------------------------------------------------------------
  // Champ displayName
  // ---------------------------------------------------------------------------
  group('User.displayName (Q-26 Option A)', () {
    test('defaults to null when not provided', () {
      final user = makeUser();
      expect(user.displayName, isNull);
    });

    test('stores provided value', () {
      final user = makeUser(displayName: 'Cherif Diouf');
      expect(user.displayName, 'Cherif Diouf');
    });

    test('copyWith can override displayName', () {
      final user = makeUser();
      final updated = user.copyWith(displayName: 'Cherif Diouf');
      expect(updated.displayName, 'Cherif Diouf');
    });

    test('copyWith preserves displayName when not overridden', () {
      final user = makeUser(displayName: 'Cherif Diouf');
      final copy = user.copyWith(currentStreak: 3);
      expect(copy.displayName, 'Cherif Diouf');
    });

    test('equality accounts for displayName', () {
      final a = makeUser(displayName: 'Cherif Diouf');
      final b = makeUser(displayName: 'Cherif Diouf');
      final c = makeUser();
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ---------------------------------------------------------------------------
  // displayPseudo — ordre de priorité Q-26
  // ---------------------------------------------------------------------------
  group('User.displayPseudo priority with displayName (Q-26)', () {
    test('prefers displayName over pseudoFull when set and non-empty', () {
      final user = makeUser(
        pseudo: 'cherif',
        pseudoFull: 'cherif#4231',
        displayName: 'Cherif Diouf',
      );
      expect(user.displayPseudo, 'Cherif Diouf');
    });

    test('falls back to pseudoFull when displayName is null', () {
      final user = makeUser(pseudo: 'cherif', pseudoFull: 'cherif#4231');
      expect(user.displayPseudo, 'cherif#4231');
    });

    test('falls back to pseudo when displayName null and pseudoFull null', () {
      final user = makeUser(pseudo: 'cherif');
      expect(user.displayPseudo, 'cherif');
    });

    test('empty displayName falls back to pseudoFull', () {
      final user = makeUser(
        pseudo: 'cherif',
        pseudoFull: 'cherif#4231',
        displayName: '',
      );
      expect(user.displayPseudo, 'cherif#4231');
    });

    test('whitespace-only displayName falls back to pseudoFull', () {
      final user = makeUser(
        pseudo: 'cherif',
        pseudoFull: 'cherif#4231',
        displayName: '   ',
      );
      expect(user.displayPseudo, 'cherif#4231');
    });
  });
}
