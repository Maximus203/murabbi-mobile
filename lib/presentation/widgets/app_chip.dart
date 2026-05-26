import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_opacity.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Chip filtre Murabbi — actif/inactif, hauteur 32px, radius pill.
///
/// Conforme au DS Murabbi (règles P-2, P-5) :
/// - `selected = false` : fond [AppColors.bgInput], bordure [AppColors.borderDefault].
/// - `selected = true`  : fond [AppColors.accent] × 0.15, bordure [AppColors.accent].
///
/// Un widget [leading] optionnel (icône, dot couleur...) peut précéder le label.
class AppChip extends StatelessWidget {
  /// Label affiché dans le chip.
  final String label;

  /// Indique si le chip est dans l'état sélectionné.
  final bool selected;

  /// Callback déclenché au tap.
  final VoidCallback onTap;

  /// Widget optionnel affiché à gauche du label (icône, dot...).
  final Widget? leading;

  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? AppColors.accent.withValues(alpha: AppOpacity.tint)
        : AppColors.bgInput;
    final borderColor = selected ? AppColors.accent : AppColors.borderDefault;
    final textColor = selected ? AppColors.accent : AppColors.textPrimary;

    final radius = BorderRadius.circular(AppRadius.pill);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 32),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: radius,
          border: Border.all(color: borderColor, width: AppBorderWidth.thin),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.s2),
            ],
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: textColor,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
