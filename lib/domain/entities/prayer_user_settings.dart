import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart'
    as v;
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart'
    as v;
import 'package:murabbi_mobile/domain/value_objects/madhab.dart' as v;

/// Mode de localisation utilisateur pour le calcul des horaires de prière.
enum LocationMode {
  /// Utilise le GPS de l'appareil — mise à jour automatique.
  automatic,

  /// Coordonnées saisies manuellement par l'utilisateur.
  manual,
}

/// Méthode de calcul des horaires — wrapping de [v.CalculationMethod] pour
/// l'entité enrichie [PrayerUserSettings] (cf. ADR-018, MOB-004).
///
/// Aligne les valeurs avec l'enum existant [v.CalculationMethod].
enum PrayerCalculationMethod {
  muslimWorldLeague,
  isna,
  egyptian,
  ummAlQura,
  dubai,
  moonsightingCommittee,
  northAmerica,
  kuwait,
  qatar,
  singapore,
  tehran,
  turkey,
}

/// Madhab pour le calcul d'Asr — wrapping de [v.Madhab].
enum PrayerMadhab { shafi, hanafi }

/// Règle hautes latitudes — wrapping de [v.HighLatitudeRule].
enum PrayerHighLatitudeRule {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
}

/// Identifiant d'une prière nominale — les 5 prières obligatoires.
enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

/// Préférences de prière utilisateur enrichies — méthode de calcul, madhab,
/// timezone, haute latitude, ajustements par prière.
///
/// Cf. MOB-004 — remplace l'ancienne [PrayerSettings] qui ne gérait que le
/// calcul on-device sans sync Supabase.
///
/// **Stratégie de stockage** :
/// - Local : `flutter_secure_storage` (TTL 1 heure).
/// - Remote : table `prayer_user_settings` Supabase (cf. ADM-006).
/// - Conflit : `remote wins` basé sur [updatedAt].
class PrayerUserSettings extends Equatable {
  /// Identifiant de l'utilisateur propriétaire de ces settings.
  final String userId;

  /// Latitude en degrés décimaux. `null` si [locationMode] == [LocationMode.automatic]
  /// et que la position n'a pas encore été résolue.
  final double? latitude;

  /// Longitude en degrés décimaux. `null` si position non résolue.
  final double? longitude;

  /// Mode de localisation (automatique GPS vs saisie manuelle).
  final LocationMode locationMode;

  /// Méthode de calcul des horaires de prière.
  final PrayerCalculationMethod calculationMethod;

  /// École juridique pour le calcul de l'heure d'Asr.
  final PrayerMadhab madhab;

  /// Règle hautes latitudes (Fajr/Isha aux latitudes > ~48°).
  final PrayerHighLatitudeRule highLatitudeRule;

  /// Gestion automatique du DST (heure d'été/hiver).
  final bool autoDst;

  /// Ajustements en minutes (±) pour chaque prière nominale.
  /// Contient exactement les 5 clés [PrayerName].
  final Map<PrayerName, int> adjustments;

  /// Horodatage UTC de la dernière modification — sert à la stratégie
  /// « remote wins » lors des conflits de sync.
  final DateTime updatedAt;

  const PrayerUserSettings({
    required this.userId,
    this.latitude,
    this.longitude,
    required this.locationMode,
    required this.calculationMethod,
    required this.madhab,
    required this.highLatitudeRule,
    required this.autoDst,
    required this.adjustments,
    required this.updatedAt,
  });

  /// Settings par défaut pour un nouvel utilisateur.
  ///
  /// Méthode par défaut : MWL (cf. ADR-013 §2.1 — fallback global).
  /// Madhab : Shafi (majoritaire global).
  factory PrayerUserSettings.defaults({required String userId}) {
    return PrayerUserSettings(
      userId: userId,
      locationMode: LocationMode.automatic,
      calculationMethod: PrayerCalculationMethod.muslimWorldLeague,
      madhab: PrayerMadhab.shafi,
      highLatitudeRule: PrayerHighLatitudeRule.middleOfTheNight,
      autoDst: true,
      adjustments: zeroAdjustments(),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Carte d'ajustements à zéro pour les 5 prières nominales.
  static Map<PrayerName, int> zeroAdjustments() => {
    PrayerName.fajr: 0,
    PrayerName.dhuhr: 0,
    PrayerName.asr: 0,
    PrayerName.maghrib: 0,
    PrayerName.isha: 0,
  };

  /// Sérialise en JSON pour `flutter_secure_storage` ou Supabase.
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'latitude': latitude,
    'longitude': longitude,
    'location_mode': locationMode.name,
    'calculation_method': calculationMethod.name,
    'madhab': madhab.name,
    'high_latitude_rule': highLatitudeRule.name,
    'auto_dst': autoDst,
    'adjustments': adjustments.map((k, v) => MapEntry(k.name, v)),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Désérialise depuis JSON (retour Supabase ou lecture secure storage).
  factory PrayerUserSettings.fromJson(Map<String, dynamic> json) {
    final rawAdj = json['adjustments'] as Map<String, dynamic>? ?? {};
    final adjustments = <PrayerName, int>{};
    for (final name in PrayerName.values) {
      adjustments[name] = (rawAdj[name.name] as num?)?.toInt() ?? 0;
    }

    return PrayerUserSettings(
      userId: json['user_id'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationMode: LocationMode.values.byName(
        json['location_mode'] as String? ?? 'automatic',
      ),
      calculationMethod: PrayerCalculationMethod.values.byName(
        json['calculation_method'] as String? ?? 'muslimWorldLeague',
      ),
      madhab: PrayerMadhab.values.byName(json['madhab'] as String? ?? 'shafi'),
      highLatitudeRule: PrayerHighLatitudeRule.values.byName(
        json['high_latitude_rule'] as String? ?? 'middleOfTheNight',
      ),
      autoDst: json['auto_dst'] as bool? ?? true,
      adjustments: adjustments,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Copie immutable — usage type-safe pour les use cases d'update.
  PrayerUserSettings copyWith({
    String? userId,
    double? latitude,
    double? longitude,
    LocationMode? locationMode,
    PrayerCalculationMethod? calculationMethod,
    PrayerMadhab? madhab,
    PrayerHighLatitudeRule? highLatitudeRule,
    bool? autoDst,
    Map<PrayerName, int>? adjustments,
    DateTime? updatedAt,
  }) {
    return PrayerUserSettings(
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationMode: locationMode ?? this.locationMode,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      autoDst: autoDst ?? this.autoDst,
      adjustments: adjustments ?? this.adjustments,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    latitude,
    longitude,
    locationMode,
    calculationMethod,
    madhab,
    highLatitudeRule,
    autoDst,
    adjustments,
    updatedAt,
  ];
}
