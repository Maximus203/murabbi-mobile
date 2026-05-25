import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

/// Mapping centralisé `PrayerStatus` → label FR / icône Lucide / couleur DS.
///
/// Évite la duplication entre `PrayerRow` (SA-01) et `StatusPickerBottomSheet`.
/// Le mapping suit ADR-013 et la grille Q-19 (statuts SQL alignés sur le
/// domain).
class PrayerStatusVisuals {
  PrayerStatusVisuals._();

  /// Libellé FR affiché à l'utilisateur (cf. CDC §UI Salat).
  static String label(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.pending:
        return 'Non priée';
      case PrayerStatus.onTime:
        return 'À l\'heure';
      case PrayerStatus.late:
        return 'En retard';
      case PrayerStatus.missed:
        return 'Manquée';
      case PrayerStatus.makeup:
        return 'Rattrapée';
    }
  }

  /// Icône Lucide associée à l'état.
  static IconData icon(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.pending:
        return LucideIcons.circle;
      case PrayerStatus.onTime:
        return LucideIcons.circleCheck;
      case PrayerStatus.late:
        return LucideIcons.clock;
      case PrayerStatus.missed:
        return LucideIcons.circleX;
      case PrayerStatus.makeup:
        return LucideIcons.rotateCcw;
    }
  }

  /// Couleur sémantique du statut (P-2 — pas de hex hors AppColors).
  static Color color(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.pending:
        return AppColors.textTertiary;
      case PrayerStatus.onTime:
        return AppColors.success;
      case PrayerStatus.late:
        return AppColors.warning;
      case PrayerStatus.missed:
        return AppColors.danger;
      case PrayerStatus.makeup:
        return AppColors.accent;
    }
  }
}

/// Libellés FR des cinq prières (clé `prayerName` côté domain → label UI).
class PrayerNameLabels {
  PrayerNameLabels._();

  static const Map<String, String> _fr = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  static String label(String prayerName) => _fr[prayerName] ?? prayerName;
}
