import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_badge.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_progress_ring.dart';

/// Score card du dashboard HM-01 (issue #6, Phase 5).
///
/// Affiche l'anneau de progression vers le palier suivant, le niveau
/// courant et les points totaux. [dailyCompletionRate] affiche l'objectif
/// journalier 80% (Q-A) si la valeur est > 0.
class DashboardScoreCard extends StatelessWidget {
  final UserScore score;

  /// Taux de complétion journalier (0.0 à 100.0). 0.0 = non disponible.
  final double dailyCompletionRate;

  const DashboardScoreCard({
    super.key,
    required this.score,
    this.dailyCompletionRate = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final level = score.currentLevel;
    final progress = level.progressToNext(score.totalPoints);
    final next = level.nextLevel;
    final pct = (progress * 100).round();

    return Semantics(
      label:
          'Niveau ${level.label}. ${score.totalPoints} points. '
          'Progression $pct pour cent vers le palier suivant.',
      excludeSemantics: true,
      child: AppCard(
        child: Row(
          children: [
            AnimatedProgressRing(
              progress: progress,
              size: 88,
              strokeWidth: 7,
              centerLabel: '$pct%',
            ),
            const SizedBox(width: AppSpacing.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBadge(label: level.label, leadingIcon: LucideIcons.star),
                  const SizedBox(height: AppSpacing.s2),
                  Text('${score.totalPoints} pts', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    next == null
                        ? 'Niveau maximal atteint'
                        : 'Prochain palier : ${next.label}',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (dailyCompletionRate > 0) ...[
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      'Objectif du jour : ${dailyCompletionRate.toStringAsFixed(0)}%'
                      ' ${dailyCompletionRate >= 80 ? '✓' : '/ 80%'}',
                      style: AppTypography.body.copyWith(
                        color: dailyCompletionRate >= 80
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
