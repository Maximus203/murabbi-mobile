import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget makeApp({VoidCallback? onCompleted}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Setup01OnboardingScreen(onCompleted: onCompleted ?? () {}),
      ),
    );
  }

  testWidgets('renders first slide + Suivant + Passer', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.text('Localisation'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
    // Pas encore "Commencer".
    expect(find.text('Commencer'), findsNothing);
  });

  testWidgets(
    'tapping "Suivant" 3x reaches "Commencer" CTA on the last slide',
    (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Tout est prêt'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
    },
  );

  testWidgets('"Commencer" calls onCompleted', (tester) async {
    var called = 0;
    await tester.pumpWidget(makeApp(onCompleted: () => called++));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(called, 1);
  });

  testWidgets('"Passer" from slide 1 calls onCompleted (skip)', (tester) async {
    var called = 0;
    await tester.pumpWidget(makeApp(onCompleted: () => called++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(called, 1);
  });

  testWidgets(
    '"Passer" persists onboarding flag (read back via SharedPreferences)',
    (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      // Q3-A : nouveau flag onboarding_seen_v1 (pre-auth pédagogique).
      expect(prefs.getBool('onboarding_seen_v1'), isTrue);
    },
  );
}
