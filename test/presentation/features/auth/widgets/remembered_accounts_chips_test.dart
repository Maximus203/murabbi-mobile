import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/remembered_accounts_chips.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget pumpable({
    required List<String> initialEmails,
    required ValueChanged<String> onTap,
  }) {
    SharedPreferences.setMockInitialValues({
      'remembered_emails_v1': initialEmails,
    });
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: RememberedAccountsChips(onTap: onTap)),
      ),
    );
  }

  testWidgets('empty state : rien rendu quand aucun email', (tester) async {
    await tester.pumpWidget(pumpable(initialEmails: const [], onTap: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('COMPTES RÉCENTS'), findsNothing);
    expect(find.byType(RememberedAccountsChips), findsOneWidget);
  });

  testWidgets('non-empty : header + chips avec emails complets', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpable(
        initialEmails: const ['cherif@example.com', 'bob@example.com'],
        onTap: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('COMPTES RÉCENTS'), findsOneWidget);
    // Audit TL : email complet (pas la troncature local-part).
    expect(find.text('cherif@example.com'), findsOneWidget);
    expect(find.text('bob@example.com'), findsOneWidget);
  });

  testWidgets('tap sur un chip déclenche onTap avec l\'email complet', (
    tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(
      pumpable(
        initialEmails: const ['cherif@example.com'],
        onTap: (e) => tapped = e,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('cherif@example.com'));
    await tester.pumpAndSettle();
    expect(tapped, 'cherif@example.com');
  });

  testWidgets('bouton x (affordance visible) ouvre la bottom sheet "oublier"', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpable(initialEmails: const ['cherif@example.com'], onTap: (_) {}),
    );
    await tester.pumpAndSettle();

    // Audit TL : affordance "x" doit être visible (Semantics button avec
    // label "Oublier ...").
    final forgetBtn = find.bySemanticsLabel('Oublier cherif@example.com');
    expect(forgetBtn, findsOneWidget);
    await tester.tap(forgetBtn);
    await tester.pumpAndSettle();

    expect(find.text('Oublier ce compte'), findsOneWidget);
  });
}
