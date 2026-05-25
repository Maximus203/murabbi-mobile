import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Carte de collection pour CO-01 (issue #6, Phase 5).
///
/// Affiche l'icône, le nom, la description, les badges catégorie / habitudes /
/// pts/jour et le statut d'activation. Selon le contexte :
///
/// - [onActivate] non null → bouton "Activer" (collection inactive proposée).
/// - [onActivate] null + [collection.isActive] → badge "✓ Activée" vert.
///
/// Tap sur la carte → [onTap] (navigation CO-DETAIL).
class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  /// Nom de la catégorie principale (depuis [categoriesNotifierProvider]).
  /// `null` → badge catégorie masqué (Q-23 migration en attente).
  final String? categoryName;

  /// Couleur de la catégorie (HexColor converti en Color côté appelant).
  /// Ignorée si [categoryName] est null.
  final Color? categoryColor;

  /// Points par jour calculés côté client (Q-24). Null pendant le chargement.
  final int? ptsPerDay;

  /// Callback activation — si null, la carte est en mode "active" (badge ✓).
  final VoidCallback? onActivate;

  /// Vrai pendant le chargement de l'activation (spinner dans le bouton).
  final bool isActivating;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    this.categoryName,
    this.categoryColor,
    this.ptsPerDay,
    this.onActivate,
    this.isActivating = false,
  });

  @override
  Widget build(BuildContext context) {
    final habitCount = collection.habitIds.length;
    final iconData = _iconForCollection(collection.icon);

    return Semantics(
      button: true,
      label:
          '${collection.name.value}, $habitCount habitudes, '
          '${collection.isActive ? "activée" : "inactive"}',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête : icône + nom + description ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppComponentSize.iconTile,
                  height: AppComponentSize.iconTile,
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Icon(
                    lu(iconData),
                    size: AppIconSize.rg,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.name.value,
                        style: AppTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        collection.description.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),

            // ── Badges ────────────────────────────────────────────────────
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                if (categoryName != null)
                  _BadgeChip(
                    label: categoryName!.toUpperCase(),
                    dotColor: categoryColor,
                  ),
                _BadgeChip(
                  label: '$habitCount HABITUDES',
                ),
                if (ptsPerDay != null)
                  _BadgeChip(label: '$ptsPerDay PTS/JOUR'),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),

            // ── Action : Activer ou badge Activée ─────────────────────────
            if (onActivate != null)
              AppButton(
                label: 'Activer',
                onPressed: isActivating ? null : onActivate,
                isLoading: isActivating,
              )
            else if (collection.isActive)
              _ActivatedBadge(),
          ],
        ),
      ),
    );
  }
}

/// Badge "✓ Activée" — collection active, pas d'action disponible dans la liste.
class _ActivatedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.success, width: AppBorderWidth.thin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.circleCheck,
            size: AppIconSize.xs,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.s1),
          Text(
            'Activée',
            style: AppTypography.caption.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

/// Chip badge texte — catégorie, habitudes, pts/jour.
class _BadgeChip extends StatelessWidget {
  final String label;
  final Color? dotColor;

  const _BadgeChip({required this.label, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.s1),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mappe le nom d'icône kebab-case de la collection vers un [LucideIcons].
IconData _iconForCollection(String? iconName) {
  return switch (iconName) {
    'heart' => LucideIcons.heart,
    'heart-pulse' => LucideIcons.heartPulse,
    'brain' => LucideIcons.brain,
    'dumbbell' => LucideIcons.dumbbell,
    'book-open' => LucideIcons.bookOpen,
    'moon' => LucideIcons.moon,
    'moon-star' => LucideIcons.moonStar,
    'sun' => LucideIcons.sun,
    'leaf' => LucideIcons.leaf,
    'zap' => LucideIcons.zap,
    'target' => LucideIcons.target,
    'star' => LucideIcons.star,
    'layers' => LucideIcons.layers,
    'flame' => LucideIcons.flame,
    'layout-grid' => LucideIcons.layoutGrid,
    _ => LucideIcons.layers,
  };
}
