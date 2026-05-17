import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_badge.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Carte collection pour CO-01 (issue #6, Phase 5).
///
/// Affiche le nom, la description, un badge "Système" le cas échéant, le
/// nombre d'habitudes et le statut actif/inactif. Tap → CO-DETAIL.
class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
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
                    size: 18,
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
