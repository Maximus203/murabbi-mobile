import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// Carte statistique compacte de HB-DETAIL (issue #153).
///
/// Affiche une valeur saillante ([value]) surmontée d'une icône et suivie
/// d'un label descriptif ([label]). Trois instances composent la section
/// stats : série actuelle, record, taux 30 jours.
class HabitStatCard extends StatelessWidget {
  /// Icône représentative de la statistique.
  final IconData icon;

  /// Valeur formatée (ex. "7 jours", "87 %").
  final String value;

  /// Libellé descriptif (ex. "Série actuelle").
  final String label;

  const HabitStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s4,
      ),
      child: Column(
        children: [
          Icon(icon, size: AppIconSize.rg, color: AppColors.accent),
          const SizedBox(height: AppSpacing.s2),
          Text(
            value,
            style: AppTypography.h3,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
