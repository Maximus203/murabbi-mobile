import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Issue #168 — `pseudo_full` (admin migration murabbi-admin#125).
///
/// Le pseudo affiché devient `pseudo#XXXX` (suffixe CSPRNG 1000..9999).
/// Côté entité Dart, le champ `pseudoFull` est ajouté en `String?` (nullable
/// tant que la migration admin n'est pas déployée pour tous les comptes
/// existants). Un getter `displayPseudo` fournit la chaîne à afficher avec
/// fallback sur l'ancien `pseudo` si `pseudoFull` est null.
void main() {
  User makeUser({String pseudo = 'ibrahim', String? pseudoFull}) {
    return User(
      id: UserId('11111111-1111-1111-1111-111111111111'),
      pseudo: Pseudonym(pseudo),
      email: NonEmptyString('a@b.co'),
      createdAt: DateTime.utc(2026, 1, 1),
      level: Level.aspirant,
      pseudoFull: pseudoFull,
    );
  }

  group('User.displayPseudo (issue #168)', () {
    test('returns pseudoFull when not null', () {
      final user = makeUser(pseudo: 'ibrahim', pseudoFull: 'ibrahim#4231');
      expect(user.displayPseudo, 'ibrahim#4231');
    });

    test('falls back to pseudo when pseudoFull is null', () {
      final user = makeUser(pseudo: 'ibrahim');
      expect(user.displayPseudo, 'ibrahim');
    });

    test('copyWith preserves pseudoFull when not overridden', () {
      final user = makeUser(pseudo: 'ibrahim', pseudoFull: 'ibrahim#4231');
      final copy = user.copyWith(currentStreak: 5);
      expect(copy.pseudoFull, 'ibrahim#4231');
      expect(copy.displayPseudo, 'ibrahim#4231');
    });

    test('copyWith can override pseudoFull explicitly', () {
      final user = makeUser(pseudo: 'ibrahim', pseudoFull: 'ibrahim#4231');
      final copy = user.copyWith(pseudoFull: 'ibrahim#9999');
      expect(copy.pseudoFull, 'ibrahim#9999');
    });

    test('equality takes pseudoFull into account', () {
      final a = makeUser(pseudo: 'ibrahim', pseudoFull: 'ibrahim#4231');
      final b = makeUser(pseudo: 'ibrahim', pseudoFull: 'ibrahim#4231');
      final c = makeUser(pseudo: 'ibrahim');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
