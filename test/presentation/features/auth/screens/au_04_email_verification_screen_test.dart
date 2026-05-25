import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_04_email_verification_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

void main() {
  Widget makeApp({
    String email = 'cherif@example.com',
    Future<void> Function()? onResend,
    VoidCallback? onContinue,
    VoidCallback? onChangeEmail,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Au04EmailVerificationScreen(
        email: email,
        onResend: onResend ?? () async {},
        onContinue: onContinue ?? () {},
        onChangeEmail: onChangeEmail ?? () {},
      ),
    );
  }

  testWidgets('renders header, email, primary + secondary CTAs', (
    tester,
  ) async {
    await tester.pumpWidget(makeApp(email: 'cherif@example.com'));
    await tester.pumpAndSettle();

    expect(find.text('Vérifie ton email'), findsOneWidget);
    expect(find.textContaining('cherif@example.com'), findsOneWidget);
    expect(find.text('J\'ai vérifié mon email'), findsOneWidget);
    expect(find.text('Renvoyer l\'email'), findsOneWidget);
    expect(find.text('Changer d\'adresse'), findsOneWidget);
  });

  testWidgets('"J\'ai vérifié mon email" calls onContinue', (tester) async {
    var called = 0;
    await tester.pumpWidget(makeApp(onContinue: () => called++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('J\'ai vérifié mon email'));
    await tester.pumpAndSettle();
    expect(called, 1);
  });

  testWidgets('"Renvoyer l\'email" calls onResend and shows confirmation', (
    tester,
  ) async {
    var called = 0;
    await tester.pumpWidget(
      makeApp(
        onResend: () async {
          called++;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renvoyer l\'email'));
    await tester.pumpAndSettle();

    expect(called, 1);
    expect(find.textContaining('Email renvoyé'), findsOneWidget);
  });

  testWidgets('"Changer d\'adresse" calls onChangeEmail', (tester) async {
    var called = 0;
    await tester.pumpWidget(makeApp(onChangeEmail: () => called++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Changer d\'adresse'));
    await tester.pump();
    expect(called, 1);
  });

  testWidgets('"Renvoyer l\'email" disables CTA while in flight', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(makeApp(onResend: () => completer.future));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renvoyer l\'email'));
    await tester.pump();

    // While pending, the label switches to 'Envoi…'.
    expect(find.text('Envoi…'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Email renvoyé'), findsOneWidget);
  });
}
