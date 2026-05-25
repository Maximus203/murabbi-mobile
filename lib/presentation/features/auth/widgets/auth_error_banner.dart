import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/errors/failure_message.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Bandeau d'erreur typé partagé entre les écrans Auth (AU-01/02/03/04).
///
/// Le mapping `Failure → message FR` est centralisé dans [FailureMessage]
/// depuis #201 (M9). Ce widget ne fait plus que présenter la décoration
/// (icône + couleur + radius) ; toute nouvelle variante d'`AuthFailure`
/// doit être ajoutée dans [FailureMessage._fromAuth].
class AuthErrorBanner extends StatelessWidget {
  final Object? failure;
  const AuthErrorBanner({super.key, required this.failure});

  @override
  Widget build(BuildContext context) {
    final message = messageFor(failure);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
          width: AppBorderWidth.thin,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: AppIconSize.md,
            color: AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  /// Libellé FR pour le contexte Auth. Délègue à [FailureMessage.from] pour
  /// tout `AuthFailure` ; les objets non-AuthFailure (et `null`) retombent
  /// sur le fallback historique du banner, formulé pour le contexte Auth
  /// ("Erreur inattendue. Réessaie dans un instant.").
  static String messageFor(Object? f) {
    const authFallback = 'Erreur inattendue. Réessaie dans un instant.';
    if (f is! AuthFailure) return authFallback;
    return FailureMessage.from(f);
  }
}
