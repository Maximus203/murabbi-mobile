import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/widgets/app_bottom_nav.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';
import 'package:murabbi_mobile/presentation/widgets/app_toggle.dart';

/// Tests structurels d'accessibilité + layout (Copilot review #2..#7).
/// Pas de goldens : on assert le DOM Flutter (Semantics, widgets attendus).
void main() {
  Widget wrap(Widget child, {EdgeInsets viewPadding = EdgeInsets.zero}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(viewPadding: viewPadding, padding: viewPadding),
        child: Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: child,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Copilot #2 — AppBottomNav respecte la safe area iOS (home indicator)
  // ---------------------------------------------------------------------------
  group('AppBottomNav — SafeArea (Copilot review #2)', () {
    testWidgets(
      'wraps content in SafeArea(top: false) so home indicator does not '
      'obscure labels on iPhone',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            AppBottomNav(
              active: AppBottomNavTab.home,
              onTabSelected: (_) {},
            ),
            viewPadding: const EdgeInsets.only(bottom: 34),
          ),
        );
        final safeAreas = find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.byType(SafeArea),
        );
        expect(safeAreas, findsAtLeastNWidgets(1));

        final safeArea = tester.widget<SafeArea>(safeAreas.first);
        expect(safeArea.top, isFalse, reason: 'top safe-area handled by AppBar');
        expect(safeArea.bottom, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Copilot #3 — Semantics(selected) sur chaque tab
  // ---------------------------------------------------------------------------
  group('AppBottomNav — Semantics (Copilot review #3)', () {
    testWidgets('exposes Semantics(selected: true) on the active tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          AppBottomNav(
            active: AppBottomNavTab.salat,
            onTabSelected: (_) {},
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Salat'),
        findsAtLeastNWidgets(1),
      );

      // Trouve un Semantics(selected: true) parmi les ancêtres du label "Salat".
      final selectedSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.selected == true &&
            w.properties.label == 'Salat',
      );
      expect(selectedSemantics, findsOneWidget);

      final unselectedSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.selected == false &&
            w.properties.label == 'Accueil',
      );
      expect(unselectedSemantics, findsOneWidget);
    });

    testWidgets('each tab is a button (semantic)', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppBottomNav(
            active: AppBottomNavTab.home,
            onTabSelected: (_) {},
          ),
        ),
      );
      // Au moins 5 Semantics(button: true) — 1 par tab.
      final buttons = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true,
      );
      expect(buttons, findsAtLeastNWidgets(5));
    });
  });

  // ---------------------------------------------------------------------------
  // Copilot #4 — AppToggle expose Semantics(toggled, button)
  // ---------------------------------------------------------------------------
  group('AppToggle — Semantics (Copilot review #4)', () {
    testWidgets('exposes toggled=true when value=true', (tester) async {
      await tester.pumpWidget(
        wrap(AppToggle(value: true, onChanged: (_) {})),
      );
      final s = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.toggled == true &&
            w.properties.button == true,
      );
      expect(s, findsAtLeastNWidgets(1));
    });

    testWidgets('exposes toggled=false when value=false', (tester) async {
      await tester.pumpWidget(
        wrap(AppToggle(value: false, onChanged: (_) {})),
      );
      final s = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.toggled == false &&
            w.properties.button == true,
      );
      expect(s, findsAtLeastNWidgets(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Copilot #5 + #6 — AppInput password tooltip + focus border
  // ---------------------------------------------------------------------------
  group('AppInput — password & focus a11y (Copilot review #5+#6)', () {
    testWidgets(
      'password eye button has a tooltip explaining the toggle action',
      (tester) async {
        await tester.pumpWidget(
          wrap(const AppInput(label: 'Password', isPassword: true)),
        );
        expect(find.byTooltip('Afficher le mot de passe'), findsOneWidget);
      },
    );

    testWidgets(
      'tooltip flips to "Masquer" once visibility is toggled on',
      (tester) async {
        await tester.pumpWidget(
          wrap(const AppInput(label: 'Password', isPassword: true)),
        );
        await tester.tap(find.byTooltip('Afficher le mot de passe'));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
      },
    );

    testWidgets(
      'shows accent focus border (1.5px) when the field is focused',
      (tester) async {
        await tester.pumpWidget(
          wrap(const AppInput(label: 'Email', placeholder: 'vous@x.com')),
        );
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        // Cherche un AnimatedContainer avec border accent (focus state).
        final container = find.descendant(
          of: find.byType(AppInput),
          matching: find.byWidgetPredicate(
            (w) =>
                w is AnimatedContainer &&
                w.decoration is BoxDecoration &&
                ((w.decoration! as BoxDecoration).border as Border?)
                        ?.top
                        .color ==
                    AppColors.accent,
          ),
        );
        expect(container, findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Copilot #7 — AppHeader.back centre stable du titre sans trailing
  // ---------------------------------------------------------------------------
  group('AppHeader — layout (Copilot review #7)', () {
    testWidgets(
      'AppHeader.back keeps title visually centered when trailing is null',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            SizedBox(
              width: 400,
              child: AppHeader.back(title: 'Nouvelle habitude', onBack: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final titleCenter = tester.getCenter(find.text('Nouvelle habitude'));
        // La fenêtre est 400px de large, le titre doit tomber dans
        // [180..220] (≈ centre 200 ± 20px) si compensation côté droit OK.
        expect(titleCenter.dx, greaterThan(180));
        expect(titleCenter.dx, lessThan(220));
      },
    );
  });
}
