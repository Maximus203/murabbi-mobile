import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Statut d'une prière (Salat) — cycle : pending → onTime → late → missed → pending.
enum SalatStatus {
  /// Non priée — en attente de saisie.
  pending,

  /// Priée à l'heure.
  onTime,

  /// Priée en retard.
  late,

  /// Manquée.
  missed,
}

/// Bouton cyclestatut Salat — affiche l'icône + le label FR du statut en cours.
///
/// Un tap déclenche [onCycleNext] ; le parent est responsable de passer au
/// prochain statut dans l'ordre : pending → onTime → late → missed → pending.
///
/// Conforme au DS Murabbi (surface plate, bordure thin, radius button, aucune
/// ombre portée — règle P-5). Hauteur ≥ [kMinInteractiveDimension] (P-A11Y).
class SalatStatusButton extends StatelessWidget {
  /// Statut courant affiché.
  final SalatStatus status;

  /// Appelé quand l'utilisateur tape le bouton pour passer au statut suivant.
  final VoidCallback onCycleNext;

  const SalatStatusButton({
    super.key,
    required this.status,
    required this.onCycleNext,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(status);
    final radius = BorderRadius.circular(AppRadius.button);

    return Material(
      color: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: spec.color.withValues(alpha: 0.3),
          width: AppBorderWidth.thin,
        ),
        borderRadius: radius,
      ),
      child: InkWell(
        onTap: onCycleNext,
        borderRadius: radius,
        child: Container(
          height: kMinInteractiveDimension,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(spec.icon, size: 16, color: spec.color),
              const SizedBox(width: AppSpacing.s2),
              Text(
                spec.label,
                style: AppTypography.body.copyWith(color: spec.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _StatusSpec _specFor(SalatStatus status) {
    switch (status) {
      case SalatStatus.pending:
        return const _StatusSpec(
          icon: LucideIcons.clock,
          color: AppColors.textSecondary,
          label: 'Non priée',
        );
      case SalatStatus.onTime:
        return const _StatusSpec(
          icon: LucideIcons.circleCheck,
          color: AppColors.success,
          label: 'À l\'heure',
        );
      case SalatStatus.late:
        return const _StatusSpec(
          icon: LucideIcons.triangleAlert,
          color: AppColors.warning,
          label: 'En retard',
        );
      case SalatStatus.missed:
        return const _StatusSpec(
          icon: LucideIcons.circleX,
          color: AppColors.danger,
          label: 'Manquée',
        );
    }
  }
}

class _StatusSpec {
  final IconData icon;
  final Color color;
  final String label;

  const _StatusSpec({
    required this.icon,
    required this.color,
    required this.label,
  });
}
