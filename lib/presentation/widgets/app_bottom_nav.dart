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
/// label 11px sous l'icône Lucide 22px.
///
/// Accessibilité (Copilot review #2 + #3) :
/// - Wrappée dans `SafeArea(top: false, bottom: true)` — le home indicator
///   iOS et la nav-gesture-bar Android ne masquent plus les labels.
/// - Chaque onglet est exposé via `Semantics(button, selected, label)` —
///   VoiceOver / TalkBack annoncent l'état actif et le rôle bouton.
class AppBottomNav extends StatelessWidget {
  static const double height = 72;

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
              icon: LucideIcons.compass,
            ),
            _NavItem(
              tab: AppBottomNavTab.habits,
              label: 'Habitudes',
              icon: LucideIcons.activity,
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
    final color = isActive ? AppColors.accent : AppColors.textTertiary;

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
            Icon(lu(icon), size: 22, color: color),
            const SizedBox(height: AppSpacing.s1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
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
