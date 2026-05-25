import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';

/// Use case pur — applique la table de mapping ADR-013 §2.1 pour pré-remplir
/// la méthode de calcul à partir d'un code pays ISO-3166-1 alpha-2.
///
/// **Sans effet de bord** : pas de réseau, pas de persistance. La couche
/// présentation appelle ensuite [SavePrayerSettingsUseCase] avec une
/// [PrayerSettings] construite à partir du résultat.
///
/// L'utilisateur peut **toujours** changer la méthode dans les settings
/// (cf. ADR-013 §2 — la table n'est qu'un défaut intelligent).
class DeriveDefaultMethodFromCountryUseCase {
  const DeriveDefaultMethodFromCountryUseCase();

  /// Retourne la méthode pré-remplie pour un code pays. Le code est
  /// normalisé en upper-case pour tolérer les locales en `fr-fr`.
  ///
  /// Si le code est `null`, vide ou inconnu, retourne
  /// [CalculationMethod.muslimWorldLeague] (fallback global ADR-013 §2.1).
  CalculationMethod call(String? countryCode) {
    if (countryCode == null) return CalculationMethod.muslimWorldLeague;
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return CalculationMethod.muslimWorldLeague;

    switch (code) {
      // -- Francophonie / Maghreb (audience prioritaire Murabbi) -------------
      case 'FR':
        return CalculationMethod.uoif;
      case 'MA':
        return CalculationMethod.morocco;
      case 'DZ':
        return CalculationMethod.algeria;
      case 'TN':
        return CalculationMethod.tunisia;

      // -- Moyen-Orient ------------------------------------------------------
      case 'EG':
        return CalculationMethod.egyptian;
      case 'SA':
        return CalculationMethod.ummAlQura;
      case 'AE':
        return CalculationMethod.dubai;
      case 'KW':
        return CalculationMethod.kuwait;
      case 'QA':
        return CalculationMethod.qatar;
      case 'TR':
        return CalculationMethod.diyanet;
      case 'IR':
        return CalculationMethod.tehran;

      // -- Sous-continent indien --------------------------------------------
      case 'PK':
      case 'IN':
      case 'BD':
        return CalculationMethod.karachi;

      // -- Asie du Sud-Est ---------------------------------------------------
      case 'SG':
      case 'MY':
      case 'ID':
        return CalculationMethod.singapore;

      // -- Amérique du Nord --------------------------------------------------
      case 'US':
      case 'CA':
        return CalculationMethod.isna;

      // -- Fallback global ---------------------------------------------------
      default:
        return CalculationMethod.muslimWorldLeague;
    }
  }
}
