import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:murabbi_mobile/presentation/router/auth_redirect.dart';
import 'package:murabbi_mobile/presentation/widgets/app_bottom_nav.dart';

/// Shell de navigation principal — enveloppe les 3 onglets actifs avec un
/// [AppBottomNav] persistant et utilise [StatefulNavigationShell] (fourni par
/// [StatefulShellRoute.indexedStack] de go_router) pour conserver l'état de
/// chaque onglet en mémoire (D-18 — issue #103).
///
/// Le passage d'onglet ne reconstruit plus l'écran depuis zéro :
/// go_router maintient un [Navigator] séparé par branche.
class ScaffoldWithBottomNav extends StatelessWidget {
  /// Shell fourni par [StatefulShellRoute.indexedStack].
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  /// Mappe l'index de branche (0=home, 1=salat, 2=habits) vers [AppBottomNavTab].
  ///
  /// Exposé en public pour faciliter les tests unitaires.
  static AppBottomNavTab tabFromIndex(int index) {
    switch (index) {
      case 0:
        return AppBottomNavTab.home;
      case 1:
        return AppBottomNavTab.salat;
      case 2:
        return AppBottomNavTab.habits;
      default:
        return AppBottomNavTab.home;
    }
  }

  /// Mappe [AppBottomNavTab] vers l'index de branche.
  ///
  /// Retourne -1 pour les onglets non encore implémentés (Collections / Classement).
  /// Exposé en public pour faciliter les tests unitaires.
  static int indexFromTab(AppBottomNavTab tab) {
    switch (tab) {
      case AppBottomNavTab.home:
        return 0;
      case AppBottomNavTab.salat:
        return 1;
      case AppBottomNavTab.habits:
        return 2;
      case AppBottomNavTab.collections:
      case AppBottomNavTab.leaderboard:
        return -1; // non implémenté
    }
  }

  void _onTabSelected(BuildContext context, AppBottomNavTab tab) {
    final index = indexFromTab(tab);
    if (index == -1) {
      // Collections / Classement pas encore implémentés.
      final label = tab == AppBottomNavTab.collections
          ? 'Collections'
          : 'Classement';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label arrive bientôt.')));
      return;
    }
    // [initialLocation: true] revient à la racine de la branche si déjà
    // dessus, ce qui correspond au comportement natif iOS/Android bottom nav.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        active: tabFromIndex(navigationShell.currentIndex),
        onTabSelected: (tab) => _onTabSelected(context, tab),
      ),
    );
  }
}

/// Routes de l'application qui font partie du shell de navigation par onglets.
/// Utilisé dans [appRouterProvider] comme ensemble de chemins appartenant au shell.
abstract class AppShellRoutes {
  /// Chemins inclus dans le [StatefulShellRoute] (avec [AppBottomNav]).
  static const Set<String> paths = {
    AppRoutes.home,
    AppRoutes.salat,
    AppRoutes.salatSettings,
    AppRoutes.habits,
    AppRoutes.habitsCreate,
  };
}
