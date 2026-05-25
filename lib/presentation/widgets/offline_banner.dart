import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Bannière fine affichée en haut du shell quand l'appareil perd la
/// connectivité (issue #195 — M11). Hauteur 32 px, fond
/// [AppColors.warning], icône `wifiOff` + libellé court.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('offline-banner-container'),
      height: 32,
      width: double.infinity,
      color: AppColors.warning,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.wifiOff, color: Colors.white, size: AppIconSize.sm),
          const SizedBox(width: AppSpacing.s2),
          Text(
            'Hors ligne',
            style: AppTypography.micro.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
