import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Bandeau d'erreur typé partagé entre les écrans Auth (AU-01/02/03/04).
///
/// Switch exhaustif sur le sealed [AuthFailure] — toute nouvelle variante doit
/// être ajoutée ici (et donc dans toutes les surfaces UI).
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
            size: 18,
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

  /// Mapping FR exhaustif sur le sealed [AuthFailure].
  /// `Object?` toléré pour absorber `state.error` non typé d'Riverpod.
  static String messageFor(Object? f) {
    if (f is! AuthFailure) {
      return 'Erreur inattendue. Réessaie dans un instant.';
    }
    return switch (f) {
      // "email not confirmed" → message distinct qui invite à valider l'inbox.
      InvalidCredentialsFailure(message: final msg)
          when msg != null &&
              msg.toLowerCase().contains('email not confirmed') =>
        'Confirme ton email avant de te connecter.',
      InvalidCredentialsFailure() => 'Email ou mot de passe incorrect.',
      EmailAlreadyInUseFailure() => 'Cet email est déjà utilisé.',
      WeakPasswordFailure() =>
        'Mot de passe trop faible (8 caractères minimum).',
      NetworkFailure() => 'Connexion impossible — vérifie ta connexion.',
      AccountDeletedFailure() =>
        'Ce compte a été supprimé. Contacte le support pour le restaurer.',
      UnknownAuthFailure() => 'Erreur inattendue. Réessaie dans un instant.',
    };
  }
}
