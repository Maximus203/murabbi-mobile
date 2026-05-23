// `SemanticsNode.hasFlag` est marqué `@Deprecated` à partir de Flutter 3.32,
// remplacé par `flagsCollection`. L'API `SemanticsFlags` introduite n'est pas
// encore stable côté nommage selon le canal (3.41 ici) ; on reste sur
// `hasFlag` — la suppression définitive est planifiée plus tard et un
// `ignore_for_file` regroupé garde `flutter analyze` à 0 issue.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';

/// Régression D-33 (issue #161) — l'ancien rework de `AppButton` (PR #160)
/// avait supprimé le wrapper `Semantics`, rendant le bouton invisible aux
/// lecteurs d'écran (VoiceOver / TalkBack ne voyaient plus le rôle bouton
/// ni l'état enabled/disabled).
///
/// Ces tests garantissent que :
///   1. `AppButton` expose toujours un nœud sémantique avec `isButton: true`
///      et le label fourni
///   2. `enabled` reflète l'état réel (`onPressed != null && !isLoading`)
///   3. Le state `disabled` (onPressed null ou isLoading) est correctement
///      annoncé
void main() {
  /// Récupère le `SemanticsNode` immédiatement attaché par le wrapper
  /// `Semantics(...)` au build de `AppButton`. On vise le widget `Semantics`
  /// le plus haut sous l'arbre `AppButton` — c'est celui que D-33 avait
  /// supprimé.
  SemanticsNode buttonSemantics(WidgetTester tester) {
    final finder = find
        .descendant(
          of: find.byType(AppButton),
          matching: find.byType(Semantics),
        )
        .first;
    return tester.getSemantics(finder);
  }

  group('AppButton — Semantics wrapper (D-33, issue #161)', () {
    testWidgets('exposes button semantics with label when enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(label: 'Continuer', onPressed: () {}),
          ),
        ),
      );

      final node = buttonSemantics(tester);
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(node.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(node.hasFlag(SemanticsFlag.isEnabled), isTrue);
      expect(node.label, contains('Continuer'));
    });

    testWidgets('marks button as disabled when onPressed is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppButton(label: 'Continuer', onPressed: null)),
        ),
      );

      final node = buttonSemantics(tester);
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(node.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(node.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });

    testWidgets('marks button as disabled when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Enregistrer',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      final node = buttonSemantics(tester);
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(node.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });
  });
}
