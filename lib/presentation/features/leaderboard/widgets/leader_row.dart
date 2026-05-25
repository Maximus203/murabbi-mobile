import 'package:flutter/material.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Ligne de classement (rangs 4+) pour LB-01 (issue #6, Phase 5).
///
/// Affiche rang, initiales, niveau et score hebdomadaire. La ligne de
/// l'utilisateur connecté est mise en évidence ([isCurrentUser]).
class LeaderRow extends StatelessWidget {
  final UserScore score;
  final String initials;
  final bool isCurrentUser;

  const LeaderRow({
    super.key,
    required this.score,
    required this.initials,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Rang ${score.weeklyRank}, ${score.weeklyPoints} points'
          '${isCurrentUser ? ", votre position" : ""}',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        background: isCurrentUser ? AppColors.bgInput : null,
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${score.weeklyRank}',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.bgInput,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(initials, style: AppTypography.label),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                score.currentLevel.label,
                style: AppTypography.body.copyWith(
                  fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Text(
              '${score.weeklyPoints} pts',
              style: AppTypography.body.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
