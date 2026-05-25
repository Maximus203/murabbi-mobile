import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

/// Verrous des VOs slice 3.C.1 — toute régression sur l'enum (suppression
/// d'une méthode, renommage non intentionnel) doit faire péter ces tests.
void main() {
  group('CalculationMethod (ADR-013 §2)', () {
    test('exposes the 16 official methods supported in V1', () {
      expect(CalculationMethod.values.length, 16);
    });

    test('exposes Maghreb francophone methods (FR, MA, DZ, TN)', () {
      expect(CalculationMethod.values, contains(CalculationMethod.uoif));
      expect(CalculationMethod.values, contains(CalculationMethod.morocco));
      expect(CalculationMethod.values, contains(CalculationMethod.algeria));
      expect(CalculationMethod.values, contains(CalculationMethod.tunisia));
    });

    test('exposes Middle-East methods', () {
      for (final m in [
        CalculationMethod.egyptian,
        CalculationMethod.ummAlQura,
        CalculationMethod.dubai,
        CalculationMethod.kuwait,
        CalculationMethod.qatar,
        CalculationMethod.diyanet,
        CalculationMethod.tehran,
      ]) {
        expect(CalculationMethod.values, contains(m));
      }
    });

    test('exposes global fallback (MWL) and ISNA / Karachi / Singapore', () {
      for (final m in [
        CalculationMethod.muslimWorldLeague,
        CalculationMethod.isna,
        CalculationMethod.karachi,
        CalculationMethod.singapore,
        CalculationMethod.moonsighting,
      ]) {
        expect(CalculationMethod.values, contains(m));
      }
    });
  });

  group('Madhab (ADR-013 §3)', () {
    test('exposes exactly Shafi and Hanafi', () {
      expect(Madhab.values, [Madhab.shafi, Madhab.hanafi]);
    });
  });

  group('HighLatitudeRule (ADR-013 §Limites)', () {
    test('exposes the 3 strategies (middle / seventh / twilight)', () {
      expect(HighLatitudeRule.values, [
        HighLatitudeRule.middleOfTheNight,
        HighLatitudeRule.seventhOfTheNight,
        HighLatitudeRule.twilightAngle,
      ]);
    });
  });
}
