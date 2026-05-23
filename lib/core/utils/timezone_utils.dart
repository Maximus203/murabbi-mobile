import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Helper timezone-aware pour toute la couche domain/presentation (BUG-004).
///
/// Problème résolu : `DateTime.now()` retourne UTC ou l'heure système selon le
/// contexte. Un utilisateur en UTC+3 validant à 23h30 locale (= 00h30 UTC J+1)
/// voyait son occurrence assignée au mauvais jour, cassant le streak.
///
/// Solution : toutes les comparaisons de jour utilisent le fuseau IANA de
/// l'utilisateur, chargé depuis le device via `flutter_timezone`.
///
/// Usage :
/// ```dart
/// await TZHelper.init(); // une fois au démarrage de l'app
///
/// final today = TZHelper.todayIn(user.ianaTimezone);
/// final isSame = TZHelper.isSameDay(a, b, user.ianaTimezone);
/// ```
///
/// Cf. ADR-018 §timezone, BUG-004 (issue #184).
abstract final class TZHelper {
  /// Initialise les données tzdata (à appeler dans `main()` avant `runApp()`).
  ///
  /// Idempotent : un double appel n'a pas d'effet de bord.
  static Future<void> init() async {
    tz_data.initializeTimeZones();
  }

  /// Retourne `true` si [a] et [b] tombent le même jour **calendaire local**
  /// dans [ianaZone].
  ///
  /// Exemple : UTC+3, [a] = 2025-05-23T20:00Z (= 23h locale),
  ///           [b] = 2025-05-23T05:00Z (= 08h locale) → `true`.
  ///           [a] = 2025-05-24T00:30Z (= 03h30 locale J+1) → `false`.
  static bool isSameDay(DateTime a, DateTime b, String ianaZone) {
    final location = tz.getLocation(ianaZone);
    final tzA = tz.TZDateTime.from(a.toUtc(), location);
    final tzB = tz.TZDateTime.from(b.toUtc(), location);
    return tzA.year == tzB.year && tzA.month == tzB.month && tzA.day == tzB.day;
  }

  /// Retourne la **date locale** (sans composante heure) correspondant à
  /// [now] dans [ianaZone].
  ///
  /// [now] est facultatif (défaut : `DateTime.now().toUtc()`). Injectez-le
  /// dans les tests pour contrôler l'horloge sans `Clock` global.
  ///
  /// Retourne un `DateTime` en UTC à minuit (00:00:00.000 UTC) représentant
  /// le jour local — le stockage DB reste en UTC.
  static DateTime todayIn(String ianaZone, {DateTime? now}) {
    final utcNow = (now ?? DateTime.now()).toUtc();
    final location = tz.getLocation(ianaZone);
    final local = tz.TZDateTime.from(utcNow, location);
    // On retourne un DateTime UTC à minuit portant les composantes y/m/d
    // locales — pas un TZDateTime, pour rester dans le monde Dart standard.
    return DateTime.utc(local.year, local.month, local.day);
  }

  /// Retourne le `TZDateTime` courant dans [ianaZone].
  ///
  /// [utcNow] est facultatif (défaut : `DateTime.now().toUtc()`). Injectez-le
  /// dans les tests.
  static tz.TZDateTime nowIn(String ianaZone, {DateTime? utcNow}) {
    final utc = (utcNow ?? DateTime.now()).toUtc();
    final location = tz.getLocation(ianaZone);
    return tz.TZDateTime.from(utc, location);
  }

  /// Retourne l'instant UTC correspondant à **minuit local** du jour [date]
  /// dans [ianaZone].
  ///
  /// Utile pour calculer le cutoff "fin de journée" locale :
  /// ```dart
  /// final cutoff = TZHelper.localMidnightUtc(
  ///   date: TZHelper.todayIn(user.timezone),
  ///   ianaZone: user.timezone,
  /// );
  /// final isExpired = DateTime.now().toUtc().isAfter(cutoff);
  /// ```
  static DateTime localMidnightUtc({
    required DateTime date,
    required String ianaZone,
  }) {
    final location = tz.getLocation(ianaZone);
    // On construit minuit local pour ce jour dans la timezone.
    final localMidnight = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
    ); // implicitement 00:00:00
    // On convertit en UTC pur pour stockage / comparaison.
    return localMidnight.toUtc();
  }
}
