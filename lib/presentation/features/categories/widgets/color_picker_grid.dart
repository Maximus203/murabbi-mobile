import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';

/// Sélecteur de couleur HB-04 — 9 pastilles tirées de [AppColors.categoryPalette].
///
/// Sélection unique : la couleur active porte un checkmark. Aucune valeur hex
/// hardcodée — la palette vient exclusivement des tokens DS (issue #150).
class ColorPickerGrid extends StatelessWidget {
  /// Couleur actuellement sélectionnée.
  final Color selected;

  /// Callback déclenché au tap sur une pastille.
  final ValueChanged<Color> onSelected;

  const ColorPickerGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      children: [
        for (final color in AppColors.categoryPalette)
          _ColorSwatch(
            color: color,
            isSelected: color == selected,
            onTap: () => onSelected(color),
          ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: AppComponentSize.touchTarget,
          height: AppComponentSize.touchTarget,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.borderDefault,
              width: isSelected
                  ? AppBorderWidth.focusRing
                  : AppBorderWidth.thin,
            ),
          ),
          child: isSelected
              ? const Icon(
                  LucideIcons.check,
                  size: AppIconSize.rg,
                  color: AppColors.bgSurface,
                )
              : null,
        ),
      ),
    );
  }
}
