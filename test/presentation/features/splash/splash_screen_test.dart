import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/splash/screens/splash_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

void main() {
  testWidgets('renders Murabbi wordmark + Bismillah + spinner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const SplashScreen()),
    );

    expect(find.text('Murabbi'), findsOneWidget);
    expect(find.text('Bismi-Llāh'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'splash spinner uses AppBorderWidth.indicatorStroke token (issue #28)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const SplashScreen()),
      );

      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(spinner.strokeWidth, AppBorderWidth.indicatorStroke);
    },
  );
}
