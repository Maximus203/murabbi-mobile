import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo affiche un SvgPicture', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLogo())),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('AppWordmark affiche un SvgPicture', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppWordmark())),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('AppLogo respecte le paramètre size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLogo(size: 64))),
    );
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.width, 64.0);
  });
}
