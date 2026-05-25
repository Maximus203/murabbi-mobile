import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

/// Tokens couleurs — source de vérité : `docs/wireframes/bundle/design-system-sheet.jsx`.
/// Toute valeur hex de l'app DOIT vivre ici (P-2). Si un test échoue ici, la
/// design system source de vérité a bougé — soit le sheet, soit ce token.
void main() {
  group('AppColors — backgrounds & texte (DS sheet § Couleurs)', () {
    test('bgPrimary = #F5F2ED', () {
      expect(AppColors.bgPrimary, const Color(0xFFF5F2ED));
    });
    test('bgSurface = #FDFBF8', () {
      expect(AppColors.bgSurface, const Color(0xFFFDFBF8));
    });
    test('bgInput = #EDE9E2', () {
      expect(AppColors.bgInput, const Color(0xFFEDE9E2));
    });
    test('textPrimary = #1C1A16', () {
      expect(AppColors.textPrimary, const Color(0xFF1C1A16));
    });
    test('textSecondary = #6B6155', () {
      expect(AppColors.textSecondary, const Color(0xFF6B6155));
    });
    test('textTertiary = #A89880', () {
      expect(AppColors.textTertiary, const Color(0xFFA89880));
    });
  });

  group('AppColors — accent ocre & sémantiques', () {
    test('accent = #8B6F47', () {
      expect(AppColors.accent, const Color(0xFF8B6F47));
    });
    test('accentHover = #7A6240', () {
      expect(AppColors.accentHover, const Color(0xFF7A6240));
    });
    test('success = #6B8C6B', () {
      expect(AppColors.success, const Color(0xFF6B8C6B));
    });
    test('warning = #9B5E3C', () {
      expect(AppColors.warning, const Color(0xFF9B5E3C));
    });
    test('danger = #8C3D3D', () {
      expect(AppColors.danger, const Color(0xFF8C3D3D));
    });
    test('borderEmphasis = rgba(28,26,22,0.16)', () {
      // 0.16 × 255 ≈ 41 (0x29)
      expect(AppColors.borderEmphasis, const Color(0x291C1A16));
    });
    test('borderDefault = rgba(28,26,22,~0.08) (Copilot #8)', () {
      // 0.08 × 255 ≈ 20 (0x14) — bordure hairline plus douce que emphasis.
      expect(AppColors.borderDefault, const Color(0x141C1A16));
    });
  });

  group('AppColors — utilitaires', () {
    test('transparent = Colors.transparent', () {
      expect(AppColors.transparent, Colors.transparent);
    });
  });

  group('AppColors — catégories (DS sheet § Catégories)', () {
    test('religion = #8B6F47 (= accent)', () {
      expect(AppColors.categoryReligion, const Color(0xFF8B6F47));
    });
    test('sport = #6B8C6B', () {
      expect(AppColors.categorySport, const Color(0xFF6B8C6B));
    });
    test('sante = #5C7A8C', () {
      expect(AppColors.categorySante, const Color(0xFF5C7A8C));
    });
    test('mental = #7A6B8C', () {
      expect(AppColors.categoryMental, const Color(0xFF7A6B8C));
    });
    test('social = #9B7A4A', () {
      expect(AppColors.categorySocial, const Color(0xFF9B7A4A));
    });
  });
}
