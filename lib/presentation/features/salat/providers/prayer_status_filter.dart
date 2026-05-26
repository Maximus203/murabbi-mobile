import 'package:murabbi_mobile/domain/entities/prayer_status.dart';

/// Filtre par statut de la liste des prières SA-01 (issue #94).
///
/// Logique de classification en **Dart pur** (testée unitairement). La prière
/// est considérée "faite" pour les statuts `onTime`, `late` et `makeup` ;
/// "à faire" pour `pending` ; "manquée" pour `missed`.
enum PrayerStatusFilter {
  /// Toutes les prières, sans filtre.
  all('Toutes'),

  /// Prières non encore priées (`pending`).
  todo('À faire'),

  /// Prières accomplies (`onTime`, `late`, `makeup`).
  done('Faites'),

  /// Prières manquées (`missed`).
  missed('Manquées');

  const PrayerStatusFilter(this.label);

  /// Libellé affiché dans le chip de filtre.
  final String label;

  /// Indique si une prière de [status] passe ce filtre.
  bool matches(PrayerStatus status) {
    switch (this) {
      case PrayerStatusFilter.all:
        return true;
      case PrayerStatusFilter.todo:
        return status == PrayerStatus.pending;
      case PrayerStatusFilter.done:
        return status == PrayerStatus.onTime ||
            status == PrayerStatus.late ||
            status == PrayerStatus.makeup;
      case PrayerStatusFilter.missed:
        return status == PrayerStatus.missed;
    }
  }
}
