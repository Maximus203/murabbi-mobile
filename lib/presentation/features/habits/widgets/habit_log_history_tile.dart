import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Ligne d'historique d'un log d'habitude (issue #153 — HB-DETAIL).
///
/// Affiche la date formatée, une icône de statut colorée, et la valeur
/// atteinte si l'habitude a un objectif chiffré ([HabitLog.actualValue]).
class HabitLogHistoryTile extends StatelessWidget {
  final HabitLog log;

  const HabitLogHistoryTile({super.key, required this.log});

  static const List<String> _months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  String get _formattedDate => '${log.date.day} ${_months[log.date.month - 1]}';

  Color get _statusColor {
    switch (log.status) {
      case HabitLogStatus.onTime:
        return AppColors.success;
      case HabitLogStatus.late:
        return AppColors.warning;
      case HabitLogStatus.missed:
        return AppColors.danger;
    }
  }

  IconData get _statusIcon {
    switch (log.status) {
      case HabitLogStatus.onTime:
        return LucideIcons.circleCheck;
      case HabitLogStatus.late:
        return LucideIcons.clock;
      case HabitLogStatus.missed:
        return LucideIcons.circleX;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        children: [
          Icon(_statusIcon, size: 18, color: _statusColor),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              _formattedDate,
              style: AppTypography.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (log.actualValue != null)
            Text(
              '${log.actualValue}',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
