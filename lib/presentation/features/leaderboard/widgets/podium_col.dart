import 'package:flutter/material.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Colonne de podium (top 3) pour LB-01.
///
/// Affiche avatar (initiale + couleur déterministe), nom complet, score
/// hebdomadaire brut et socle numéroté. Le socle du rang 1 est en
/// [AppColors.accent], les autres en [AppColors.bgInput].
class PodiumCol extends StatelessWidget {
  final UserScore score;

  /// Nom complet (pseudo Supabase) à afficher sous l'avatar.
  final String name;

  const PodiumCol({super.key, required this.score, required this.name});

  @override
  Widget build(BuildContext context) {
    final rank = score.weeklyRank;
    final pedestalHeight = switch (rank) {
      1 => 72.0,
      2 => 56.0,
      _ => 44.0,
    };
    final avatarSize = rank == 1 ? 56.0 : 48.0;
    final initial = name.isNotEmpty
        ? name.characters.first.toUpperCase()
        : '?';
    final avatarColor = _avatarColor(score.userId.value);

    return Semantics(
      label: 'Rang $rank, $name, ${score.weeklyPoints} points',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTypography.h3.copyWith(color: AppColors.bgSurface),
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          // Nom
          SizedBox(
            width: 72,
            child: Text(
              name,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          // Score brut (sans "pts")
          Text(
            '${score.weeklyPoints}',
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          // Socle numéroté
          Container(
            width: 72,
            height: pedestalHeight,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.accent : AppColors.bgInput,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.chip),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: AppTypography.h2.copyWith(
                color:
                    rank == 1 ? AppColors.bgSurface : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Couleur d'avatar déterministe — stable pour un même userId.
/// Cycle sur la palette catégorie (9 teintes terreuses).
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
