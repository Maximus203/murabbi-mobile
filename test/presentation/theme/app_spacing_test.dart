import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';

/// Tokens espacement — grille 4px (DS sheet § Espacement).
/// Aucun magic number d'espacement ne doit apparaître ailleurs (Q-5).
void main() {
  group('AppSpacing — 4px grid', () {
    test('s1 = 4', () => expect(AppSpacing.s1, 4));
    test('s2 = 8', () => expect(AppSpacing.s2, 8));
    test('s3 = 12', () => expect(AppSpacing.s3, 12));
    test('s4 = 16', () => expect(AppSpacing.s4, 16));
    test('s5 = 20', () => expect(AppSpacing.s5, 20));
    test('s6 = 24', () => expect(AppSpacing.s6, 24));
    test('s8 = 32', () => expect(AppSpacing.s8, 32));
  });

  group('AppRadius — 4 niveaux DS sheet § Rayons', () {
    test('chip = 6', () => expect(AppRadius.chip, 6));
    test('button = 10', () => expect(AppRadius.button, 10));
    test('card = 16', () => expect(AppRadius.card, 16));
    test('pill = 100', () => expect(AppRadius.pill, 100));
  });

  /// Grammaire ternaire volontaire (issue #28 — décision PO Option A) :
  ///   thin (0.5)            — bordures fines, séparateurs (P-5).
  ///   focusRing (1.5)       — focus ring accessibilité.
  ///   indicatorStroke (2.0) — indicateurs d'état (loaders, arcs, countdown).
  group('AppBorderWidth — grammaire ternaire (issue #28)', () {
    test('thin = 0.5 (P-5)', () => expect(AppBorderWidth.thin, 0.5));
    test('focusRing = 1.5', () => expect(AppBorderWidth.focusRing, 1.5));
    test(
      'indicatorStroke = 2.0',
      () => expect(AppBorderWidth.indicatorStroke, 2.0),
    );
  });
}
