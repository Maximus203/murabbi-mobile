import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/category_form_notifier.dart';
import 'package:murabbi_mobile/presentation/features/categories/widgets/category_icon.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';

/// Sélecteur d'icône HB-04 — 10 icônes Lucide ([kCategoryIconNames]).
///
/// Sélection unique : l'icône active est mise en évidence (fond accent +
/// bordure). La couleur passée colore les icônes pour une preview cohérente.
class IconSelectorGrid extends StatelessWidget {
  /// Nom d'icône Lucide actuellement sélectionné (kebab-case).
  final String selected;

  /// Callback déclenché au tap sur une icône.
  final ValueChanged<String> onSelected;

  /// Couleur d'accent utilisée pour teinter les icônes (suit la sélection
  /// couleur du formulaire — preview cohérente).
  final Color accentColor;

  const IconSelectorGrid({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      children: [
        for (final name in kCategoryIconNames)
          _IconCell(
            name: name,
            isSelected: name == selected,
            accentColor: accentColor,
            onTap: () => onSelected(name),
          ),
      ],
    );
  }
}

class _IconCell extends StatelessWidget {
  final String name;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _IconCell({
    required this.name,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          width: AppComponentSize.iconSelectorCell,
          height: AppComponentSize.iconSelectorCell,
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.16)
                : AppColors.bgInput,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: isSelected ? accentColor : AppColors.borderDefault,
              width: isSelected
                  ? AppBorderWidth.focusRing
                  : AppBorderWidth.thin,
            ),
          ),
          child: Icon(
            categoryIconData(name),
            size: AppIconSize.nav,
            color: isSelected ? accentColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
