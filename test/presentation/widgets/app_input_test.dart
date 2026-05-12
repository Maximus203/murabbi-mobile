import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

void main() {
  testWidgets('AppInput respects minimum tap target height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppInput(
                placeholder: 'Email',
              ),
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(AppInput));
    expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
  });
}
