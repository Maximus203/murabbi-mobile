import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Barre de navigation principale (5 onglets) — DS v1.5.
///
/// Hauteur : [AppComponentSize.bottomNavHeight] (76 dp).
/// Icônes : [AppIconSize.nav] (24 dp).
/// Labels : [AppTypography.navLabel] (10 dp, weight 500).
/// Actif : [AppColors.accent].
/// Inactif : [AppColors.textTertiary].
///
/// Utilise [BottomNavigationBar] avec [BottomNavigationBarType.fixed]
/// pour que les 5 onglets soient toujours visibles et de taille égale.
/// Bordure supérieure thin 0.5px [AppColors.borderDefault].
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderDefault,
            width: AppBorderWidth.thin,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.bgPrimary,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: AppTypography.navLabel.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: AppTypography.navLabel.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w400,
        ),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(lu(LucideIcons.house), size: AppIconSize.nav),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(lu(LucideIcons.moonStar), size: AppIconSize.nav),
            label: 'Salat',
          ),
          BottomNavigationBarItem(
            icon: Icon(lu(LucideIcons.listChecks), size: AppIconSize.nav),
            label: 'Habitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(lu(LucideIcons.layers), size: AppIconSize.nav),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: Icon(lu(LucideIcons.trophy), size: AppIconSize.nav),
            label: 'Classement',
          ),
        ],
      ),
    );
  }
}
