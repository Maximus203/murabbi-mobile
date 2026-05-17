import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Input texte Murabbi — DS sheet § Inputs.
/// 3 modes : texte simple, avec icône leading, password (eye toggle).
///
/// Paramètres étendus (issues #95) :
/// - [enabled] : quand false, champ grisé (opacity 0.5) et non interactif.
/// - [errorText] : si non-null, affiche un libellé d'erreur en rouge sous le
///   champ et la bordure passe en [AppColors.danger].
/// - [maxLength] : si fourni, affiche un compteur "n/max" en caption sous le
///   champ (côté droit).
/// - [textInputAction] : transmis directement au [TextField].
/// - [onSubmitted] : callback déclenché à la validation clavier.
///
/// Accessibilité (Copilot review #5 + #6) :
/// - Le bouton eye/eye-off du mode password porte un `tooltip` ("Afficher/
///   Masquer le mot de passe") — VoiceOver/TalkBack annoncent l'action.
/// - Au focus clavier, la bordure passe à `accent` 1.5px (`focusRing` token)
///   pour donner aux utilisateurs clavier une indication visuelle claire.
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

  /// Quand false, le champ est grisé (opacity 0.5) et non interactif.
  final bool enabled;

  /// Si non-null, affiche un texte d'erreur rouge sous le champ et la bordure
  /// devient [AppColors.danger].
  final String? errorText;

  /// Si fourni, affiche un compteur "n/[maxLength]" en caption sous le champ.
  final int? maxLength;

  /// Transmis directement au [TextField] sous-jacent.
  final TextInputAction? textInputAction;

  /// Appelé quand l'utilisateur valide avec le clavier.
  final VoidCallback? onSubmitted;

  const AppInput({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.leadingIcon,
    this.isPassword = false,
    this.keyboardType,
    this.onChanged,
    this.enabled = true,
    this.errorText,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _obscured = true;
  late final FocusNode _focusNode;
  bool _focused = false;

  /// Suivi interne du nb de caractères — nécessaire quand maxLength est fourni
  /// sans controller externe.
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    if (widget.controller != null) {
      _currentLength = widget.controller!.text.length;
      widget.controller!.addListener(_onControllerChanged);
    }
  }

  @override
  void didUpdateWidget(AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      if (widget.controller != null) {
        _currentLength = widget.controller!.text.length;
        widget.controller!.addListener(_onControllerChanged);
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  void _onControllerChanged() {
    if (widget.maxLength != null) {
      final newLen = widget.controller!.text.length;
      if (newLen != _currentLength) {
        setState(() => _currentLength = newLen);
      }
    }
  }

  Color get _borderColor {
    if (widget.errorText != null) return AppColors.danger;
    if (_focused) return AppColors.accent;
    return AppColors.borderEmphasis;
  }

  double get _borderWidth {
    if (_focused) return AppBorderWidth.focusRing;
    return AppBorderWidth.thin;
  }

  @override
  Widget build(BuildContext context) {
    final hasLeading = widget.leadingIcon != null;
    final hasTrailing = widget.isPassword;
    final hasFooter = widget.errorText != null || widget.maxLength != null;

    final inputField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!.toUpperCase(), style: AppTypography.label),
          const SizedBox(height: AppSpacing.s2),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: _borderColor, width: _borderWidth),
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
                    focusNode: _focusNode,
                    obscureText: widget.isPassword && _obscured,
                    keyboardType: widget.keyboardType,
                    enabled: widget.enabled,
                    textInputAction: widget.textInputAction,
                    onChanged: (value) {
                      if (widget.maxLength != null) {
                        setState(() => _currentLength = value.length);
                      }
                      widget.onChanged?.call(value);
                    },
                    onSubmitted: widget.onSubmitted == null
                        ? null
                        : (_) => widget.onSubmitted!(),
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
                  tooltip: _obscured
                      ? 'Afficher le mot de passe'
                      : 'Masquer le mot de passe',
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
        if (hasFooter) ...[
          const SizedBox(height: AppSpacing.s1),
          Row(
            children: [
              if (widget.errorText != null)
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (widget.maxLength != null)
                Text(
                  '$_currentLength/${widget.maxLength}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ],
      ],
    );

    // Wrap dans Opacity si désactivé pour l'indication visuelle.
    if (!widget.enabled) {
      return Opacity(opacity: 0.5, child: inputField);
    }
    return inputField;
  }
}
