import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Dialog de confirmation Murabbi — DS D-25.
///
/// Remplace [AlertDialog] Material pour respecter le Design System.
/// Usage :
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (_) => AppDialog(
///     title: 'Se déconnecter ?',
///     body: "Vous devrez vous reconnecter pour accéder à l'application.",
///     confirmLabel: 'Se déconnecter',
///     cancelLabel: 'Annuler',
///     isDangerous: true,
///     onConfirm: () => Navigator.pop(context, true),
///     onCancel: () => Navigator.pop(context, false),
///   ),
/// );
/// ```
class AppDialog extends StatelessWidget {
  /// Titre du dialog (style [AppTypography.h3]).
  final String title;

  /// Corps optionnel — phrase d'explication (style [AppTypography.body]).
  final String? body;

  /// Label du bouton de confirmation.
  final String confirmLabel;

  /// Label du bouton d'annulation.
  final String cancelLabel;

  /// Callback déclenché quand l'utilisateur confirme.
  final VoidCallback onConfirm;

  /// Callback déclenché quand l'utilisateur annule.
  final VoidCallback onCancel;

  /// Si true, le label de confirmation s'affiche en [AppColors.danger].
  final bool isDangerous;

  const AppDialog({
    super.key,
    required this.title,
    this.body,
    this.confirmLabel = 'Confirmer',
    this.cancelLabel = 'Annuler',
    required this.onConfirm,
    required this.onCancel,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDangerous ? AppColors.danger : AppColors.accent;

    return Dialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h3),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.s3),
              Text(
                body!,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    cancelLabel,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                TextButton(
                  onPressed: onConfirm,
                  child: Text(
                    confirmLabel,
                    style: AppTypography.body.copyWith(color: confirmColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
