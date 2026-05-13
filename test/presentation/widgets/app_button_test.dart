import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';

void main() {
  testWidgets('AppButton respects minimum tap target height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton(label: 'Continuer', onPressed: () {}),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(AppButton));
    expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
  });
}
