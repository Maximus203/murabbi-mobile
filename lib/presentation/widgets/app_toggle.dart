import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';

/// Toggle iOS-like 44×26, accent ocre quand `value=true`.
/// DS sheet § Toggles. Bordure 0.5px hairline (P-5).
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final track = value ? AppColors.accent : AppColors.bgInput;
    final border = value ? AppColors.accentHover : AppColors.borderEmphasis;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 26,
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: border, width: AppBorderWidth.hairline),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.all(2),
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.bgSurface,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
