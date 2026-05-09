/// Méthode de calcul des horaires de prière (cf. ADR-013 §2).
///
/// Liste verrouillée des méthodes officielles supportées en V1. Le mapping
/// pays → méthode est documenté dans ADR-013 §2.1 et implémenté dans
/// `DeriveDefaultMethodFromCountryUseCase`.
///
/// Toute valeur ici est un VO pur — la conversion vers les types
/// `adhan_dart` (slice 3.C.2) sera centralisée dans
/// `services/prayer/prayer_times_service.dart` (règle d'isolation
/// ADR-013 §Architecture).
enum CalculationMethod {
  /// Muslim World League — fallback global par défaut (Fajr 18° / Isha 17°).
  muslimWorldLeague,

  /// Islamic Society of North America (Fajr 15° / Isha 15°). Défaut US/CA.
  isna,

  /// Egyptian General Authority (Fajr 19.5° / Isha 17.5°).
  egyptian,

  /// University of Islamic Sciences, Karachi (Fajr 18° / Isha 18°).
  /// Défaut PK / IN / BD.
  karachi,

  /// Umm al-Qura, Mecque (Fajr 18.5° / Isha 90 min après Maghrib).
  /// Défaut SA.
  ummAlQura,

  /// Diyanet İşleri Başkanlığı (Turquie). Défaut TR.
  diyanet,

  /// Institute of Geophysics, Tehran. Défaut IR.
  tehran,

  /// Moonsighting Committee Worldwide. Défaut robuste hautes latitudes (>55°)
  /// — applique automatiquement la règle 1/7.
  moonsighting,

  /// Majlis Ugama Islam Singapura (MUIS). Défaut SG / MY / ID.
  singapore,

  /// Dubai (UAE General Authority of Islamic Affairs).
  dubai,

  /// Qatar (basé Umm al-Qura mais Isha = 18° au lieu de 90 min).
  qatar,

  /// Kuwait (Fajr 18° / Isha 17.5°).
  kuwait,

  /// Union des Organisations Islamiques de France (Fajr 12° / Isha 12°).
  /// Défaut FR. Si non exposée nativement par `adhan_dart` 1.2.0, mapper
  /// vers méthode "Other" avec params custom dans
  /// `prayer_times_service.dart` (cf. ADR-013 §Limites).
  uoif,

  /// Maroc — Ministère des Habous et des Affaires Islamiques.
  /// Défaut MA.
  morocco,

  /// Algérie — Ministère des Affaires Religieuses.
  /// Défaut DZ.
  algeria,

  /// Tunisie — Ministère des Affaires Religieuses.
  /// Défaut TN.
  tunisia,
}
