import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/widgets/app_progress_ring.dart';

void main() {
  testWidgets('AppProgressRing renders without error at 0%', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AppProgressRing(progress: 0))),
    );
    expect(find.byType(AppProgressRing), findsOneWidget);
  });

  testWidgets('AppProgressRing renders without error at 100%', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppProgressRing(progress: 1, centerLabel: '100'),
        ),
      ),
    );
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('AppProgressRing clamps progress above 1 to 1', (tester) async {
    final ring = AppProgressRing(progress: 2.0);
    expect(ring.progress, 1.0);
  });

  testWidgets('AnimatedProgressRing renders and settles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedProgressRing(
            progress: 0.75,
            duration: const Duration(milliseconds: 200),
            centerLabel: '75',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedProgressRing), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
  });
}
