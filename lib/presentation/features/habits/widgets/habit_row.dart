import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Ligne d'habitude réutilisable (issue #151).
///
/// Extrait de HA-01 — utilisé dans la liste HA-01 et (à venir) HB-DETAIL.
///
/// - Tap sur toute la ligne → [onTap] (navigation détail).
/// - Tap sur le checkmark seul → [onToggle] (cycle done/late/missed).
/// - Le checkmark change de couleur selon [todayStatus] :
///   done = vert, late = orange, missed = rouge, null = gris.
class HabitRow extends StatelessWidget {
  final Habit habit;

  /// Statut du log d'aujourd'hui — `null` si aucun log.
  final HabitLogStatus? todayStatus;

  /// Tap sur la ligne (hors checkmark).
  final VoidCallback onTap;

  /// Tap sur le checkmark.
  final VoidCallback onToggle;

  const HabitRow({
    super.key,
    required this.habit,
    required this.todayStatus,
    required this.onTap,
    required this.onToggle,
  });

  String _frequencyLabel() {
    switch (habit.frequencyType) {
      case HabitFrequencyType.daily:
        return 'Tous les jours';
      case HabitFrequencyType.perDay:
        return '${habit.frequency}× par jour';
      case HabitFrequencyType.perWeek:
        return '${habit.frequency}× par semaine';
      case HabitFrequencyType.weekly:
        return '${habit.activeDays.length} jour(s) / semaine';
      case HabitFrequencyType.monthly:
        return 'Le ${habit.monthlyDay} de chaque mois';
      case HabitFrequencyType.custom:
        return 'Personnalisée';
    }
  }

  /// Couleur du checkmark selon le statut du jour.
  Color get _checkColor {
    switch (todayStatus) {
      case null:
        return AppColors.textTertiary;
      case HabitLogStatus.onTime:
        return AppColors.success;
      case HabitLogStatus.late:
        return AppColors.warning;
      case HabitLogStatus.missed:
        return AppColors.danger;
    }
  }

  IconData get _checkIcon {
    switch (todayStatus) {
      case null:
        return LucideIcons.circle;
      case HabitLogStatus.onTime:
        return LucideIcons.circleCheck;
      case HabitLogStatus.late:
        return LucideIcons.clock;
      case HabitLogStatus.missed:
        return LucideIcons.circleX;
    }
  }

  String get _statusSemanticLabel {
    switch (todayStatus) {
      case null:
        return 'Non validée';
      case HabitLogStatus.onTime:
        return 'Validée à temps';
      case HabitLogStatus.late:
        return 'Validée en retard';
      case HabitLogStatus.missed:
        return 'Manquée';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            // ── Checkmark — toggle du statut ────────────────────────
            Semantics(
              button: true,
              label: _statusSemanticLabel,
              child: InkResponse(
                key: const Key('habit_row_checkmark'),
                onTap: onToggle,
                radius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s2),
                  child: Icon(
                    _checkIcon,
                    key: const Key('habit_row_checkmark_icon'),
                    size: 24,
                    color: _checkColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name.value,
                    style: AppTypography.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    _frequencyLabel(),
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // #163 : points nullable — on n'affiche le badge que si défini.
            if (habit.points != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s2,
                  vertical: AppSpacing.s1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  '+${habit.points!.value} pts',
                  style: AppTypography.label.copyWith(color: AppColors.accent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
