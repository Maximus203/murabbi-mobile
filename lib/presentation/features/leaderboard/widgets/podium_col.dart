import 'package:flutter/material.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Colonne de podium (top 3) pour LB-01 (issue #6, Phase 5).
///
/// Affiche un avatar à initiales, le rang et le score hebdomadaire. La
/// hauteur du socle varie avec le rang (1er plus haut).
class PodiumCol extends StatelessWidget {
  final UserScore score;

  /// Initiales affichées dans l'avatar (dérivées du pseudo en amont).
  final String initials;

  const PodiumCol({super.key, required this.score, required this.initials});

  @override
  Widget build(BuildContext context) {
    final rank = score.weeklyRank;
    final pedestalHeight = switch (rank) {
      1 => 72.0,
      2 => 56.0,
      _ => 44.0,
    };
    final avatarSize = rank == 1 ? 56.0 : 48.0;

    return Semantics(
      label: 'Rang $rank, ${score.weeklyPoints} points',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.accent : AppColors.bgInput,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderEmphasis,
                width: AppBorderWidth.thin,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTypography.h3.copyWith(
                color: rank == 1 ? AppColors.bgSurface : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text('${score.weeklyPoints} pts', style: AppTypography.label),
          const SizedBox(height: AppSpacing.s1),
          Container(
            width: AppComponentSize.podiumCol,
            height: pedestalHeight,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.chip),
              ),
              border: Border.all(
                color: AppColors.borderDefault,
                width: AppBorderWidth.thin,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: AppTypography.h2.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
