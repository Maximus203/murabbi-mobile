import 'package:flutter/material.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Ligne de classement (rangs 4+) pour LB-01.
///
/// Affiche `#rang`, avatar coloré avec initiale, nom (pseudo) et score
/// hebdomadaire brut. La ligne de l'utilisateur connecté est mise en
/// évidence ([isCurrentUser]).
class LeaderRow extends StatelessWidget {
  final UserScore score;

  /// Nom complet (pseudo Supabase) à afficher.
  final String name;
  final bool isCurrentUser;

  const LeaderRow({
    super.key,
    required this.score,
    required this.name,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty
        ? name.characters.first.toUpperCase()
        : '?';
    final avatarColor = _avatarColor(score.userId.value);

    return Semantics(
      label: 'Rang ${score.weeklyRank}, $name, ${score.weeklyPoints} points'
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
            // Rang préfixé d'un dièse
            SizedBox(
              width: 32,
              child: Text(
                '#${score.weeklyRank}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            // Avatar coloré
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: AppTypography.label.copyWith(
                  color: AppColors.bgSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            // Nom
            Expanded(
              child: Text(
                name,
                style: AppTypography.body.copyWith(
                  fontWeight:
                      isCurrentUser ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Score brut (sans "pts")
            Text(
              '${score.weeklyPoints}',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Couleur d'avatar déterministe — identique à [PodiumCol] pour cohérence.
Color _avatarColor(String seed) {
  const palette = [
    AppColors.categoryReligion,
    AppColors.categorySport,
    AppColors.categorySante,
    AppColors.categoryMental,
    AppColors.categorySocial,
    AppColors.categoryEtudes,
    AppColors.categoryFamille,
    AppColors.categoryFinance,
    AppColors.categoryCreatif,
  ];
  final hash = seed.codeUnits.fold(0, (a, b) => a + b);
  return palette[hash % palette.length];
}
