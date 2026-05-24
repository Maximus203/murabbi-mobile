import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wifiOff, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Hors ligne',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
