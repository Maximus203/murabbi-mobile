import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Onglet de la barre de navigation principale.
/// 5 destinations imposées (DS sheet) : Accueil, Salat, Habitudes,
/// Collections, Classement.
enum AppBottomNavTab { home, salat, habits, collections, leaderboard }

/// Barre de navigation Murabbi — bordure top thin 0.5px, fond `bgPrimary`,
/// hauteur 76 dp (DS v1.5), icônes 24 dp, labels 10 dp.
///
/// Accessibilité (Copilot review #2 + #3) :
/// - Wrappée dans `SafeArea(top: false, bottom: true)` — le home indicator
///   iOS et la nav-gesture-bar Android ne masquent plus les labels.
/// - Chaque onglet est exposé via `Semantics(button, selected, label)` —
///   VoiceOver / TalkBack annoncent l'état actif et le rôle bouton.
class AppBottomNav extends StatelessWidget {
  /// Hauteur contractuelle DS v1.5 : 76 dp.
  static const double height = AppComponentSize.bottomNavHeight;

  final AppBottomNavTab active;
  final ValueChanged<AppBottomNavTab> onTabSelected;

  const AppBottomNav({
    super.key,
    required this.active,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border(
            top: BorderSide(
              color: AppColors.borderDefault,
              width: AppBorderWidth.thin,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
        child: Row(
          children: const [
            _NavItem(
              tab: AppBottomNavTab.home,
              label: 'Accueil',
              icon: LucideIcons.house,
            ),
            _NavItem(
              tab: AppBottomNavTab.salat,
              label: 'Salat',
              icon: LucideIcons.moonStar,
            ),
            _NavItem(
              tab: AppBottomNavTab.habits,
              label: 'Habitudes',
              icon: LucideIcons.listChecks,
            ),
            _NavItem(
              tab: AppBottomNavTab.collections,
              label: 'Collections',
              icon: LucideIcons.layers,
            ),
            _NavItem(
              tab: AppBottomNavTab.leaderboard,
              label: 'Classement',
              icon: LucideIcons.trophy,
            ),
          ].map((e) => Expanded(child: e._withParent(this))).toList(),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppBottomNavTab tab;
  final String label;
  final IconData icon;
  final AppBottomNav? _parent;

  const _NavItem({
    required this.tab,
    required this.label,
    required this.icon,
    AppBottomNav? parent,
  }) : _parent = parent;

  _NavItem _withParent(AppBottomNav parent) =>
      _NavItem(tab: tab, label: label, icon: icon, parent: parent);

  @override
  Widget build(BuildContext context) {
    final parent = _parent!;
    final isActive = parent.active == tab;
    // textSecondary (#6B6155) = contraste ~5.6:1 sur bgPrimary (WCAG AA ✓).
    // textTertiary (#A89880) ne passait que ~2.4:1 — insuffisant.
    final color = isActive ? AppColors.accent : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => parent.onTabSelected(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(lu(icon), size: AppIconSize.nav, color: color),
            const SizedBox(height: AppSpacing.s1),
            Text(
              label,
              style: AppTypography.navLabel.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
