import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Typographie — Geist + Geist Mono + Noto Sans Arabic uniquement (P-3).
/// Source de vérité : DS sheet § Typographie.
void main() {
  group('AppTypography — sizes (DS sheet)', () {
    test('display = 42 / Geist Mono Medium / -1px tracking', () {
      const s = AppTypography.display;
      expect(s.fontSize, 42);
      expect(s.fontWeight, FontWeight.w500);
      expect(s.letterSpacing, -1);
    });

    test('h1 = 26 / SemiBold / -0.3px', () {
      const s = AppTypography.h1;
      expect(s.fontSize, 26);
      expect(s.fontWeight, FontWeight.w600);
      expect(s.letterSpacing, -0.3);
    });

    test('h2 = 18', () => expect(AppTypography.h2.fontSize, 18));
    test('h3 = 15', () => expect(AppTypography.h3.fontSize, 15));
    test('body = 14', () => expect(AppTypography.body.fontSize, 14));
    test('label = 11 (UPPERCASE expected at usage)', () {
      expect(AppTypography.label.fontSize, 11);
    });
    test('caption = 11', () => expect(AppTypography.caption.fontSize, 11));
    test('arabic = 22 / Noto Sans Arabic Medium', () {
      const s = AppTypography.arabic;
      expect(s.fontSize, 22);
      expect(s.fontWeight, FontWeight.w500);
    });
  });

  // Copilot review #9 — verrouille les fontFamily pour qu'une régression
  // vers Roboto/system font ne passe pas silencieusement.
  group('AppTypography — fontFamily lock (Copilot #9)', () {
    test('display uses Geist Mono', () {
      expect(AppTypography.display.fontFamily, 'Geist Mono');
    });
    test('h1 / h2 / h3 / body / label / caption use Geist', () {
      for (final s in [
        AppTypography.h1,
        AppTypography.h2,
        AppTypography.h3,
        AppTypography.body,
        AppTypography.label,
        AppTypography.caption,
      ]) {
        expect(s.fontFamily, 'Geist');
      }
    });
    test('arabic uses Noto Sans Arabic', () {
      expect(AppTypography.arabic.fontFamily, 'Noto Sans Arabic');
    });
    test('mono uses Geist Mono', () {
      expect(AppTypography.mono.fontFamily, 'Geist Mono');
    });
  });
}
