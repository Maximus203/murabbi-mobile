import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Input texte Murabbi — DS sheet § Inputs.
/// 3 modes : texte simple, avec icône leading, password (eye toggle).
class AppInput extends StatefulWidget {
  /// Label affiché au-dessus du champ (style label uppercase).
  final String? label;
  final String? placeholder;
  final TextEditingController? controller;
  final IconData? leadingIcon;

  /// Si vrai, traite l'input comme mot de passe (obscure + eye toggle).
  final bool isPassword;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AppInput({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.leadingIcon,
    this.isPassword = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final hasLeading = widget.leadingIcon != null;
    final hasTrailing = widget.isPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: AppTypography.label,
          ),
          const SizedBox(height: AppSpacing.s2),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: AppColors.borderEmphasis,
              width: AppBorderWidth.hairline,
            ),
          ),
          child: Row(
            children: [
              if (hasLeading)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.s3),
                  child: Icon(
                    widget.leadingIcon,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hasLeading ? AppSpacing.s2 : AppSpacing.s3,
                    vertical: AppSpacing.s3,
                  ),
                  child: TextField(
                    controller: widget.controller,
                    obscureText: widget.isPassword && _obscured,
                    keyboardType: widget.keyboardType,
                    onChanged: widget.onChanged,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.placeholder,
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              if (hasTrailing)
                IconButton(
                  splashRadius: 16,
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
