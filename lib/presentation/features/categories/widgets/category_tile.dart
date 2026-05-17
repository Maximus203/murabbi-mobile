import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/features/categories/widgets/category_icon.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Tuile catégorie — HB-03 (liste) et preview temps réel HB-04.
///
/// Affiche un badge icône coloré + le nom + (optionnel) un compteur
/// d'habitudes liées. Les catégories système portent un badge cadenas.
class CategoryTile extends StatelessWidget {
  /// Nom affiché.
  final String name;

  /// Couleur d'accent — token DS résolu (jamais un hex brut).
  final Color color;

  /// Nom d'icône Lucide (kebab-case).
  final String icon;

  /// Si vrai, affiche un cadenas (catégorie système non-modifiable).
  final bool isSystem;

  /// Nombre d'habitudes liées — masqué si `null`.
  final int? habitCount;

  /// Callback de tap — `null` désactive l'interaction (preview HB-04).
  final VoidCallback? onTap;

  const CategoryTile({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    this.isSystem = false,
    this.habitCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      child: Row(
        children: [
          // Badge icône coloré.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(categoryIconData(icon), size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (habitCount != null) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    '$habitCount habitude${habitCount! > 1 ? "s" : ""}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isSystem)
            const Icon(
              LucideIcons.lock,
              size: 16,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}
