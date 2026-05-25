import 'package:flutter/material.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Variantes de badge — DS sheet § Badges & Chips.
enum AppBadgeVariant {
  /// Badge "Système" — ocre clair, bord ocre.
  system,

  /// Chip catégorie au repos — fond clair, dot couleur, label normal.
  chip,

  /// Chip catégorie active — fond ocre clair, label medium.
  chipActive,
}

/// Badge / chip Murabbi — surface plate, radius `chip` 6px, bordure thin.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;

  /// Couleur du dot (categories) — requis pour `chip`/`chipActive`.
  final Color? dotColor;

  /// Icône optionnelle (ex: étoile pour badge-level).
  final IconData? leadingIcon;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.system,
    this.dotColor,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _spec(variant);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1 + 2,
      ),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: spec.border, width: AppBorderWidth.thin),
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
            const SizedBox(width: AppSpacing.s2),
          ],
          if (leadingIcon != null) ...[
            Icon(lu(leadingIcon!), size: 11, color: spec.foreground),
            const SizedBox(width: AppSpacing.s1 + 2),
          ],
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: spec.foreground,
              fontWeight: spec.fontWeight,
            ),
          ),
        ],
      ),
    );
  }

  static _BadgeSpec _spec(AppBadgeVariant v) {
    switch (v) {
      case AppBadgeVariant.system:
        return const _BadgeSpec(
          background: AppColors.bgSurface,
          foreground: AppColors.accent,
          border: AppColors.borderEmphasis,
          fontWeight: FontWeight.w500,
        );
      case AppBadgeVariant.chip:
        return const _BadgeSpec(
          background: AppColors.bgSurface,
          foreground: AppColors.textSecondary,
          border: AppColors.borderEmphasis,
          fontWeight: FontWeight.w400,
        );
      case AppBadgeVariant.chipActive:
        // D-10: chip sélectionné — fond accent ocre, texte blanc surface.
        return const _BadgeSpec(
          background: AppColors.accent,
          foreground: AppColors.bgSurface,
          border: AppColors.accent,
          fontWeight: FontWeight.w500,
        );
    }
  }
}

class _BadgeSpec {
  final Color background;
  final Color foreground;
  final Color border;
  final FontWeight fontWeight;
  const _BadgeSpec({
    required this.background,
    required this.foreground,
    required this.border,
    required this.fontWeight,
  });
}
