import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/widgets/app_toggle.dart';

void main() {
  Widget pump(bool value, {ValueChanged<bool>? onChanged}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: AppToggle(value: value, onChanged: onChanged ?? (v) {}),
      ),
    ),
  );

  testWidgets('AppToggle — fond accent quand value=true', (tester) async {
    await tester.pumpWidget(pump(true));
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.accent);
  });

  testWidgets('AppToggle — fond borderDefault quand value=false', (
    tester,
  ) async {
    await tester.pumpWidget(pump(false));
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.borderDefault);
  });

  testWidgets('AppToggle — onChanged appelé au tap', (tester) async {
    bool? received;
    await tester.pumpWidget(pump(false, onChanged: (v) => received = v));
    await tester.tap(find.byType(AppToggle));
    expect(received, isTrue);
  });

  testWidgets('AppToggle — Semantics toggled reflète value', (tester) async {
    await tester.pumpWidget(pump(true));
    final toggled = find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          w.properties.toggled == true &&
          w.properties.button == true,
    );
    expect(toggled, findsAtLeastNWidgets(1));
  });
}
