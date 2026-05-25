import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_badge.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_progress_ring.dart';

/// Score card du dashboard HM-01 (issue #6, Phase 5).
///
/// Quand [dailySummary] est fourni (données du jour disponibles) :
/// - l'anneau affiche le taux de complétion des habitudes du jour
/// - la valeur principale montre les points d'habitudes gagnés aujourd'hui
/// - le sous-texte indique l'objectif quotidien du niveau courant
///
/// Sans [dailySummary] (premier jour ou donnée indisponible) :
/// - l'anneau affiche la progression vers le palier suivant
/// - la valeur principale montre le total de points
class DashboardScoreCard extends StatelessWidget {
  final UserScore score;
  final DailySummary? dailySummary;

  const DashboardScoreCard({super.key, required this.score, this.dailySummary});

  @override
  Widget build(BuildContext context) {
    final level = score.currentLevel;

    final double ringProgress;
    final String centerLabel;
    final String mainValue;
    final String subText;

    if (dailySummary != null) {
      ringProgress = dailySummary!.completionRate / 100;
      centerLabel = '${dailySummary!.completionRate.round()}%';
      mainValue = '${dailySummary!.habitPointsToday} / ${level.dailyGoal} pts';
      subText = 'Score du jour · objectif ${level.dailyGoal} pts';
    } else {
      final progress = level.progressToNext(score.totalPoints);
      ringProgress = progress;
      centerLabel = '${(progress * 100).round()}%';
      mainValue = '${score.totalPoints} pts';
      final next = level.nextLevel;
      subText = next == null
          ? 'Niveau maximal atteint'
          : 'Prochain palier : ${next.label}';
    }

    final pct = (ringProgress * 100).round();

    return Semantics(
      label:
          'Niveau ${level.label}. $mainValue. '
          'Progression $pct pour cent.',
      excludeSemantics: true,
      child: AppCard(
        child: Row(
          children: [
            AnimatedProgressRing(
              progress: ringProgress,
              size: 88,
              strokeWidth: 7,
              centerLabel: centerLabel,
            ),
            const SizedBox(width: AppSpacing.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBadge(label: level.label, leadingIcon: LucideIcons.star),
                  const SizedBox(height: AppSpacing.s2),
                  Text(mainValue, style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    subText,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
