import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Variantes du bouton — DS sheet § Boutons.
/// Une variante `primary` par écran (P-6).
enum AppButtonVariant { primary, secondary, ghost, destructive, link }

/// Bouton Murabbi — surface plate, bordure 0.5px, radius 10 (button), aucune
/// ombre portée (P-5).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? leadingIcon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
  });

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(variant, enabled: _enabled);
    final radius = BorderRadius.circular(AppRadius.button);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 16, color: spec.foreground),
          const SizedBox(width: AppSpacing.s2),
        ],
        Text(label, style: AppTypography.body.copyWith(color: spec.foreground)),
      ],
    );

    return Material(
      color: spec.background,
      shape: RoundedRectangleBorder(
        side: spec.border == null
            ? BorderSide.none
            : BorderSide(color: spec.border!, width: AppBorderWidth.thin),
        borderRadius: radius,
      ),
      child: InkWell(
        onTap: _enabled ? onPressed : null,
        borderRadius: radius,
        child: Container(
          height: kMinInteractiveDimension,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }

  static _ButtonSpec _spec(AppButtonVariant v, {required bool enabled}) {
    switch (v) {
      case AppButtonVariant.primary:
        return _ButtonSpec(
          background: enabled ? AppColors.accent : AppColors.bgInput,
          foreground: enabled ? AppColors.bgSurface : AppColors.textTertiary,
          border: null,
        );
      case AppButtonVariant.secondary:
        // D-12: fond légèrement teinté + bordure visible — lisible au-dessus du bgPrimary.
        return const _ButtonSpec(
          background: AppColors.bgInput,
          foreground: AppColors.textPrimary,
          border: AppColors.borderEmphasis,
        );
      case AppButtonVariant.ghost:
        // D-12: texte seul — ni fond ni bordure, pour les actions secondaires discrètes.
        return const _ButtonSpec(
          background: AppColors.transparent,
          foreground: AppColors.textPrimary,
          border: null,
        );
      case AppButtonVariant.destructive:
        return const _ButtonSpec(
          background: AppColors.bgSurface,
          foreground: AppColors.danger,
          border: AppColors.danger,
        );
      case AppButtonVariant.link:
        return const _ButtonSpec(
          background: AppColors.transparent,
          foreground: AppColors.accent,
          border: null,
        );
    }
  }
}

class _ButtonSpec {
  final Color background;
  final Color foreground;
  final Color? border;
  const _ButtonSpec({
    required this.background,
    required this.foreground,
    required this.border,
  });
}
