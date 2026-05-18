import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Grille 2×2 de statistiques du dashboard HM-01 (issue #6, Phase 5) :
/// Série / Salat du jour / Habitudes du jour / Classement hebdo.
class DashboardStatsGrid extends StatelessWidget {
  final int streakDays;
  final String salatLabel;
  final String habitsLabel;
  final int weeklyRank;

  const DashboardStatsGrid({
    super.key,
    required this.streakDays,
    required this.salatLabel,
    required this.habitsLabel,
    required this.weeklyRank,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        icon: LucideIcons.flame,
        label: 'Série',
        value: '$streakDays j',
      ),
      _StatTile(icon: LucideIcons.moonStar, label: 'Salat', value: salatLabel),
      _StatTile(
        icon: LucideIcons.listChecks,
        label: 'Habitudes',
        value: habitsLabel,
      ),
      _StatTile(
        icon: LucideIcons.trophy,
        label: 'Classement',
        value: '#$weeklyRank',
      ),
    ];

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              tiles[0],
              const SizedBox(height: AppSpacing.s3),
              tiles[2],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: Column(
            children: [
              tiles[1],
              const SizedBox(height: AppSpacing.s3),
              tiles[3],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label : $value',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(height: AppSpacing.s2),
            Text(value, style: AppTypography.h3),
            const SizedBox(height: AppSpacing.s1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
