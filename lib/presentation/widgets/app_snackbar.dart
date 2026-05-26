import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Affiche une [SnackBar] thémée Murabbi — issue #146.
///
/// Les SnackBars affichées via le `ScaffoldMessenger` brut héritaient du
/// thème dark Material par défaut (fond noir), en rupture avec la palette
/// sable/ocre de l'app. Ce helper centralise une SnackBar cohérente avec le
/// design system : fond `textPrimary` (anthracite-brun) et texte clair Geist.
///
/// Usage :
/// ```dart
/// showAppSnackBar(context, 'Collections arrive bientôt.');
/// ```
///
/// [actionLabel] / [onAction] ajoutent une action optionnelle (teinte accent).
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        content: Text(
          message,
          style: AppTypography.body.copyWith(color: AppColors.bgSurface),
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.accent,
                onPressed: onAction,
              )
            : null,
      ),
    );
}
