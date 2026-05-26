import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Grille 2×2 de statistiques du dashboard HM-01 (issue #6, Phase 5) :
/// Série / Salat du jour / Habitudes du jour / Classement hebdo.
///
/// Les [subLabel] optionnels affichent une métrique secondaire sous la valeur
/// principale (ex. "+3 pts", "80%", "↗ 2 places"). Masqués si null.
class DashboardStatsGrid extends StatelessWidget {
  final int streakDays;
  final String salatLabel;
  final String habitsLabel;
  final int weeklyRank;

  final String? streakSubLabel;
  final String? salatSubLabel;
  final String? habitsSubLabel;
  final String? rankSubLabel;

  const DashboardStatsGrid({
    super.key,
    required this.streakDays,
    required this.salatLabel,
    required this.habitsLabel,
    required this.weeklyRank,
    this.streakSubLabel,
    this.salatSubLabel,
    this.habitsSubLabel,
    this.rankSubLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        icon: LucideIcons.flame,
        label: 'STREAK',
        value: '$streakDays j',
        subLabel: streakSubLabel,
      ),
      _StatTile(
        icon: LucideIcons.moonStar,
        label: 'SALAT',
        value: salatLabel,
        subLabel: salatSubLabel,
      ),
      _StatTile(
        icon: LucideIcons.listChecks,
        label: 'HABITUDES',
        value: habitsLabel,
        subLabel: habitsSubLabel,
      ),
      _StatTile(
        icon: LucideIcons.trophy,
        label: 'CLASSEMENT',
        value: '#$weeklyRank',
        subLabel: rankSubLabel,
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
  final String? subLabel;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: subLabel != null ? '$label : $value · $subLabel' : '$label : $value',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppComponentSize.statTile),
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: AppIconSize.sm, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    label,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(value, style: AppTypography.h1),
              const SizedBox(height: AppSpacing.s1),
              // Toujours rendu pour garantir une hauteur de tuile constante.
              Text(
                subLabel ?? '',
                style: AppTypography.caption.copyWith(
                  color: subLabel != null
                      ? AppColors.success
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
