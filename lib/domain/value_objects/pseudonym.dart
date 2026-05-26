import 'package:equatable/equatable.dart';

/// Pseudonyme public d'un utilisateur — affiché sur le leaderboard (Q-09)
/// et tout écran social.
///
/// Décision Q-10 (`product_decisions_v1.md`) :
/// - longueur 1..30 caractères Unicode (post-trim)
/// - exclusion : caractères de contrôle (NUL, tab, newline, etc.) et
///   caractères « invisibles » zero-width (U+200B..U+200F, U+FEFF)
/// - **non unique** : la collision est tolérée, l'UI ajoute `· #1234` si besoin
/// - modération : banlist V1 côté admin (Q-10 — vérifiée par
///   `CheckPseudoAvailableUseCase`, hors VO)
class Pseudonym extends Equatable {
  static const int maxLength = 30;

  final String value;

  const Pseudonym._(this.value);

  factory Pseudonym(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'Pseudonym cannot be empty');
    }
    if (trimmed.runes.length > maxLength) {
      throw ArgumentError.value(
        raw,
        'raw',
        'Pseudonym must be at most $maxLength characters',
      );
    }
    for (final rune in trimmed.runes) {
      if (_isForbidden(rune)) {
        throw ArgumentError.value(
          raw,
          'raw',
          'Pseudonym contains forbidden character (control or zero-width)',
        );
      }
    }
    return Pseudonym._(trimmed);
  }

  static bool _isForbidden(int rune) {
    // C0/C1 control characters.
    if (rune <= 0x1F) return true;
    if (rune >= 0x7F && rune <= 0x9F) return true;
    // Zero-width / formatting characters that allow visual collisions.
    if (rune >= 0x200B && rune <= 0x200F) return true;
    if (rune == 0x2028 || rune == 0x2029) return true;
    if (rune == 0xFEFF) return true;
    return false;
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
