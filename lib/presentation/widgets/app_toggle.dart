import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';

/// Toggle iOS-like 44×26, accent ocre quand `value=true`, borderDefault quand `false`.
/// DS sheet § Toggles. Bordure 0.5px thin (P-5).
///
/// Accessibilité (Copilot review #4) : `Semantics(button, toggled, label)` —
/// VoiceOver / TalkBack annoncent l'état (on/off) et le rôle bouton.
/// Le `GestureDetector` natif ne fournit pas ces semantics par défaut.
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final track = value ? AppColors.accent : AppColors.borderDefault;
    final border = value ? AppColors.accentHover : AppColors.borderEmphasis;
    return Semantics(
      button: true,
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: GestureDetector(
          onTap: enabled ? () => onChanged!(!value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: AppComponentSize.toggleWidth,
            height: AppComponentSize.toggleHeight,
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: border, width: AppBorderWidth.thin),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(AppRadius.drag),
                width: AppComponentSize.toggleThumb,
                height: AppComponentSize.toggleThumb,
                decoration: const BoxDecoration(
                  color: AppColors.bgSurface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
