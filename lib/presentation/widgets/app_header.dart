import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Header — DS sheet § Headers. Deux variantes :
/// - [AppHeader.title] : titre large + action optionnelle à droite.
/// - [AppHeader.back]  : bouton retour à gauche + titre centré.
///
/// Bordure inférieure hairline 0.5px (P-5), pas d'ombre portée.
///
/// Layout (Copilot review #7) : en mode `back`, si `trailing` est `null`,
/// un placeholder de la largeur du back button (`_backButtonSlotWidth`) est
/// inséré à droite pour que le titre soit centré dans la largeur **totale**
/// du header — pas dans l'espace restant après le bouton retour.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  static const double height = 56;

  /// Largeur réservée pour le bouton retour (et son symétrique côté droit
  /// quand `trailing` est null).
  static const double _backButtonSlotWidth = 48;

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool _isBackVariant;

  const AppHeader.title({super.key, required this.title, this.trailing})
    : onBack = null,
      _isBackVariant = false;

  const AppHeader.back({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  }) : _isBackVariant = true;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      decoration: const Border(
        bottom: BorderSide(
          color: AppColors.borderDefault,
          width: AppBorderWidth.hairline,
        ),
      ).toBoxDecoration(),
      child: Row(
        children: [
          if (_isBackVariant)
            SizedBox(
              width: _backButtonSlotWidth,
              child: IconButton(
                onPressed: onBack,
                splashRadius: 18,
                icon: const Icon(
                  LucideIcons.chevronLeft,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          else
            const SizedBox(width: 0),
          Expanded(
            child: Text(
              title,
              textAlign: _isBackVariant ? TextAlign.center : TextAlign.start,
              style: _isBackVariant ? AppTypography.h3 : AppTypography.h2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            trailing!
          else if (_isBackVariant)
            // Placeholder symétrique au back button → garantit que le titre
            // soit centré dans la largeur totale du header (Copilot #7).
            const SizedBox(width: _backButtonSlotWidth)
          else
            const SizedBox(width: 0),
        ],
      ),
    );
  }
}

extension on Border {
  BoxDecoration toBoxDecoration() => BoxDecoration(border: this);
}
