import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

void main() {
  group('AppHeader', () {
    testWidgets('renders using AppBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppHeader.title(title: 'Titre'),
            body: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Titre'), findsOneWidget);
    });

    testWidgets('back variant renders chevron and centers title', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppHeader.back(title: 'Retour', onBack: () {}),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      // Back button présent.
      expect(find.byIcon(lu(LucideIcons.chevronLeft)), findsOneWidget);

      // Titre centré : centerTitle = true sur l'AppBar sous-jacent.
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);
    });

    testWidgets('back variant fires onBack when chevron tapped', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppHeader.back(title: 'Retour', onBack: () => tapped++),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byIcon(lu(LucideIcons.chevronLeft)));
      expect(tapped, 1);
    });

    testWidgets('trailing widget is rendered when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppHeader.title(
              title: 'Titre',
              trailing: Icon(LucideIcons.settings, key: Key('trailing-icon')),
            ),
            body: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byKey(const Key('trailing-icon')), findsOneWidget);
    });
  });
}
