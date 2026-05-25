import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_badge.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Carte collection pour CO-01 (issue #6, Phase 5 / Q-24).
///
/// Affiche le nom, la description, un badge "Système" le cas échéant, le
/// nombre d'habitudes, le statut actif/inactif et les pts/jour si disponibles.
/// Tap → CO-DETAIL.
class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  /// Points par jour calculés côté client (Q-24). Null pendant le loading
  /// des habitudes — la ligne est masquée dans ce cas.
  final int? ptsPerDay;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    this.ptsPerDay,
  });

  @override
  Widget build(BuildContext context) {
    final habitCount = collection.habitIds.length;
    return Semantics(
      button: true,
      label:
          '${collection.name.value}, $habitCount habitudes, '
          '${collection.isActive ? "active" : "inactive"}',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(collection.name.value, style: AppTypography.h3),
                ),
                if (collection.isSystem)
                  const AppBadge(label: 'Système')
                else if (collection.isActive)
                  const Icon(
                    LucideIcons.circleCheck,
                    size: AppIconSize.md,
                    color: AppColors.success,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              collection.description.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                const Icon(
                  LucideIcons.listChecks,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.s1),
                Text(
                  '$habitCount habitude${habitCount > 1 ? "s" : ""}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                if (ptsPerDay != null) ...[
                  const SizedBox(width: AppSpacing.s3),
                  Icon(lu(LucideIcons.zap), size: AppIconSize.xs, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.s1),
                  Text(
                    '$ptsPerDay pts/jour',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  collection.isActive ? 'Active' : 'Inactive',
                  style: AppTypography.caption.copyWith(
                    color: collection.isActive
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
