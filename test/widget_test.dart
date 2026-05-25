import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/app.dart';

/// Smoke test Phase 1 — vérifie que l'app boot sans crash et affiche
/// le placeholder DS. Sera étendu en Phase 2 (auth, navigation).
void main() {
  testWidgets('MurabbiApp boots without crashing (Phase 1 smoke)', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MurabbiApp()));
    await tester.pump();
    expect(find.text('Murabbi'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
