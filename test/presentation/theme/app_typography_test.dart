import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Typographie — Geist + Geist Mono + Noto Sans Arabic uniquement (P-3).
/// Source de vérité : DS sheet § Typographie.
void main() {
  group('AppTypography — sizes (DS sheet)', () {
    test('display = 42 / Geist Mono Medium / -1px tracking', () {
      final s = AppTypography.display;
      expect(s.fontSize, 42);
      expect(s.fontWeight, FontWeight.w500);
      expect(s.letterSpacing, -1);
    });

    test('h1 = 26 / SemiBold / -0.3px', () {
      final s = AppTypography.h1;
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
      final s = AppTypography.arabic;
      expect(s.fontSize, 22);
      expect(s.fontWeight, FontWeight.w500);
    });
  });
}
