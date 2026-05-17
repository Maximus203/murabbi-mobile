import 'package:flutter/material.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Heatmap des 30 derniers jours d'une habitude (issue #153 — HB-DETAIL).
///
/// Grille de 30 cellules, une par jour, colorée selon le statut du log :
/// - [HabitLogStatus.onTime] → [AppColors.success] (vert)
/// - [HabitLogStatus.late]   → [AppColors.warning] (orange)
/// - [HabitLogStatus.missed] → [AppColors.danger]  (rouge)
/// - `null` (aucun log)      → [AppColors.bgInput] (gris clair recessé)
///
/// Décision DS : l'issue mentionne `AppColors.surface` pour la cellule vide ;
/// ce token n'existe pas. On utilise [AppColors.bgInput] — le gris clair
/// recessé du DS, lisible sur une carte `bgSurface`.
///
/// Un long-press sur une cellule affiche un tooltip date + statut.
class Heatmap30 extends StatelessWidget {
  /// 30 entrées exactement — clé = date, valeur = statut du log (ou `null`).
  final Map<DateTime, HabitLogStatus?> heatmapData;

  const Heatmap30({super.key, required this.heatmapData});

  static Color cellColorFor(HabitLogStatus? status) {
    switch (status) {
      case null:
        return AppColors.bgInput;
      case HabitLogStatus.onTime:
        return AppColors.success;
      case HabitLogStatus.late:
        return AppColors.warning;
      case HabitLogStatus.missed:
        return AppColors.danger;
    }
  }

  static String _statusLabel(HabitLogStatus? status) {
    switch (status) {
      case null:
        return 'Aucun log';
      case HabitLogStatus.onTime:
        return 'À temps';
      case HabitLogStatus.late:
        return 'En retard';
      case HabitLogStatus.missed:
        return 'Manquée';
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    // Tri chronologique croissant — le jour le plus ancien en premier.
    final days = heatmapData.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            for (final day in days)
              Tooltip(
                message:
                    '${_formatDate(day)} — ${_statusLabel(heatmapData[day])}',
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  key: ValueKey('heatmap_cell_${day.toIso8601String()}'),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cellColorFor(heatmapData[day]),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        const Wrap(
          key: Key('heatmap_legend'),
          spacing: AppSpacing.s4,
          runSpacing: AppSpacing.s2,
          children: [
            _LegendItem(status: HabitLogStatus.onTime),
            _LegendItem(status: HabitLogStatus.late),
            _LegendItem(status: HabitLogStatus.missed),
            _LegendItem(status: null),
          ],
        ),
      ],
    );
  }
}

/// Pastille + label d'une entrée de légende.
class _LegendItem extends StatelessWidget {
  final HabitLogStatus? status;

  const _LegendItem({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Heatmap30.cellColorFor(status),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Text(
          Heatmap30._statusLabel(status),
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
