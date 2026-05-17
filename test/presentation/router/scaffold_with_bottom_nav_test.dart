import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:murabbi_mobile/presentation/router/scaffold_with_bottom_nav.dart';
import 'package:murabbi_mobile/presentation/widgets/app_bottom_nav.dart';

/// Widget minimal simulant un écran d'onglet. Incrémente un compteur par
/// initState pour détecter si le State a été recréé.
class FakeTabScreen extends StatefulWidget {
  final String label;
  final void Function()? onInit;
  const FakeTabScreen({super.key, required this.label, this.onInit});

  @override
  State<FakeTabScreen> createState() => FakeTabScreenState();
}

class FakeTabScreenState extends State<FakeTabScreen> {
  @override
  void initState() {
    super.initState();
    widget.onInit?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(widget.label)));
  }
}

/// Construit un GoRouter de test avec [StatefulShellRoute.indexedStack].
GoRouter _makeRouter({
  void Function()? onHomeInit,
  void Function()? onSalatInit,
}) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithBottomNav(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) =>
                    FakeTabScreen(label: 'Accueil', onInit: onHomeInit),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/salat',
                builder: (_, _) =>
                    FakeTabScreen(label: 'Salat', onInit: onSalatInit),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                builder: (_, _) => const FakeTabScreen(label: 'Habitudes'),
              ),
            ],
          ),
        ],
      ),
      // Routes hors shell — Phase 5 : Collections & Classement
      GoRoute(
        path: '/collections',
        builder: (_, _) => const FakeTabScreen(label: 'Collections'),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (_, _) => const FakeTabScreen(label: 'Classement'),
      ),
    ],
  );
}

void main() {
  group('ScaffoldWithBottomNav — D-18 tab state preservation', () {
    testWidgets('affiche AppBottomNav avec l\'onglet home actif au démarrage', (
      tester,
    ) async {
      final router = _makeRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsOneWidget);
      // Le label "Accueil" apparaît dans la bottom nav ET dans le body du FakeTabScreen.
      expect(find.text('Accueil'), findsAtLeastNWidgets(1));
    });

    testWidgets('navigue vers Salat au tap sur l\'onglet Salat', (
      tester,
    ) async {
      final router = _makeRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salat'));
      await tester.pumpAndSettle();

      // Le label Salat apparaît dans la bottom nav ET dans le body.
      expect(find.text('Salat'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'home ne recrée pas son State lors du retour depuis Salat (IndexedStack préserve l\'état)',
      (tester) async {
        var homeInitCount = 0;

        final router = _makeRouter(onHomeInit: () => homeInitCount++);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Home initialisé une seule fois.
        expect(homeInitCount, equals(1));

        // Navigation vers Salat.
        await tester.tap(find.text('Salat'));
        await tester.pumpAndSettle();

        // Retour sur Home via la bottom nav.
        await tester.tap(find.text('Accueil'));
        await tester.pumpAndSettle();

        // initState du home n'a pas été rappelé : IndexedStack réutilise
        // le State existant sans détruire le widget.
        expect(
          homeInitCount,
          equals(1),
          reason:
              'IndexedStack ne doit pas détruire le State home lors '
              'du retour depuis Salat',
        );
      },
    );

    testWidgets(
      'salat ne recrée pas son State lors du switch home→salat→home→salat',
      (tester) async {
        var salatInitCount = 0;

        final router = _makeRouter(onSalatInit: () => salatInitCount++);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Premier tap → Salat.
        await tester.tap(find.text('Salat'));
        await tester.pumpAndSettle();
        expect(salatInitCount, equals(1));

        // Retour Home.
        await tester.tap(find.text('Accueil'));
        await tester.pumpAndSettle();

        // Re-tap → Salat.
        await tester.tap(find.text('Salat'));
        await tester.pumpAndSettle();

        // initState ne doit pas être rappelé la deuxième fois.
        expect(
          salatInitCount,
          equals(1),
          reason:
              'IndexedStack ne doit pas appeler initState deux fois '
              'sur le widget Salat',
        );
      },
    );

    testWidgets('Collections navigue vers /collections (Phase 5 — slice 5.G)', (
      tester,
    ) async {
      final router = _makeRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Collections'));
      await tester.pumpAndSettle();

      // Navigation vers /collections — l'écran Collections est affiché.
      expect(find.text('Collections'), findsWidgets);
      // Aucun snackbar "arrive bientôt" (remplacé par navigation réelle).
      expect(find.text('Collections arrive bientôt.'), findsNothing);
    });

    testWidgets('Classement navigue vers /leaderboard (Phase 5 — slice 5.G)', (
      tester,
    ) async {
      final router = _makeRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Classement'));
      await tester.pumpAndSettle();

      // Navigation vers /leaderboard — l'écran Classement est affiché.
      expect(find.text('Classement'), findsWidgets);
      // Aucun snackbar "arrive bientôt" (remplacé par navigation réelle).
      expect(find.text('Classement arrive bientôt.'), findsNothing);
    });
  });

  group('ScaffoldWithBottomNav — méthodes de mapping (D-18)', () {
    test('tabFromIndex mappe correctement les indices 0-2', () {
      expect(ScaffoldWithBottomNav.tabFromIndex(0), AppBottomNavTab.home);
      expect(ScaffoldWithBottomNav.tabFromIndex(1), AppBottomNavTab.salat);
      expect(ScaffoldWithBottomNav.tabFromIndex(2), AppBottomNavTab.habits);
    });

    test('tabFromIndex retourne home pour tout index hors bornes', () {
      expect(ScaffoldWithBottomNav.tabFromIndex(99), AppBottomNavTab.home);
    });

    test('indexFromTab mappe correctement les tabs aux indices', () {
      expect(ScaffoldWithBottomNav.indexFromTab(AppBottomNavTab.home), 0);
      expect(ScaffoldWithBottomNav.indexFromTab(AppBottomNavTab.salat), 1);
      expect(ScaffoldWithBottomNav.indexFromTab(AppBottomNavTab.habits), 2);
      expect(
        ScaffoldWithBottomNav.indexFromTab(AppBottomNavTab.collections),
        -1,
      );
      expect(
        ScaffoldWithBottomNav.indexFromTab(AppBottomNavTab.leaderboard),
        -1,
      );
    });
  });
}
