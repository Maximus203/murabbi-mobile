import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// Tests widget pour les nouvelles fonctionnalités AppInput :
/// `enabled`, `errorText`, `maxLength`, `textInputAction`, `onSubmitted`.
///
/// Cycle TDD : ces tests sont écrits avant l'implémentation (phase RED).
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // enabled = false
  // ---------------------------------------------------------------------------
  group('AppInput — disabled state (enabled: false)', () {
    testWidgets('TextField is not enabled when enabled=false', (tester) async {
      await tester.pumpWidget(
        wrap(const AppInput(label: 'Email', enabled: false)),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.enabled, isFalse);
    });

    testWidgets('renders with reduced opacity when disabled', (tester) async {
      await tester.pumpWidget(
        wrap(const AppInput(label: 'Email', enabled: false)),
      );
      // L'opacité doit être < 1.0 pour indiquer visuellement l'état désactivé.
      final opacity = find.byWidgetPredicate(
        (w) => w is Opacity && w.opacity < 1.0,
      );
      expect(opacity, findsAtLeastNWidgets(1));
    });

    testWidgets('TextField is enabled by default (no enabled param)', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const AppInput(label: 'Email')));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.enabled, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // errorText
  // ---------------------------------------------------------------------------
  group('AppInput — error state (errorText)', () {
    testWidgets('shows errorText message below the field', (tester) async {
      await tester.pumpWidget(
        wrap(const AppInput(label: 'Email', errorText: 'Email invalide')),
      );
      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('no error text shown when errorText is null', (tester) async {
      await tester.pumpWidget(wrap(const AppInput(label: 'Email')));
      // Aucun texte d'erreur par défaut.
      expect(find.text('Email invalide'), findsNothing);
    });

    testWidgets('border becomes danger color when errorText is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AppInput(label: 'Email', errorText: 'Requis')),
      );
      // Cherche un AnimatedContainer dont la border est AppColors.danger.
      final errorBorder = find.byWidgetPredicate(
        (w) =>
            w is AnimatedContainer &&
            w.decoration is BoxDecoration &&
            ((w.decoration! as BoxDecoration).border as Border?)?.top.color ==
                AppColors.danger,
      );
      expect(errorBorder, findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // maxLength
  // ---------------------------------------------------------------------------
  group('AppInput — character counter (maxLength)', () {
    testWidgets('shows "0/50" counter when maxLength=50 and field is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AppInput(label: 'Bio', maxLength: 50)),
      );
      expect(find.text('0/50'), findsOneWidget);
    });

    testWidgets('counter updates as user types', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        wrap(AppInput(label: 'Bio', maxLength: 50, controller: controller)),
      );
      await tester.enterText(find.byType(TextField), 'Salut');
      await tester.pump();
      expect(find.text('5/50'), findsOneWidget);
    });

    testWidgets('no counter shown when maxLength is null', (tester) async {
      await tester.pumpWidget(wrap(const AppInput(label: 'Email')));
      // Aucun pattern "X/Y" dans le widget.
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').contains('/'),
        ),
        findsNothing,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // textInputAction
  // ---------------------------------------------------------------------------
  group('AppInput — textInputAction', () {
    testWidgets('passes textInputAction to underlying TextField', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const AppInput(label: 'Email', textInputAction: TextInputAction.next),
        ),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.textInputAction, TextInputAction.next);
    });

    testWidgets('textInputAction is null by default', (tester) async {
      await tester.pumpWidget(wrap(const AppInput(label: 'Email')));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.textInputAction, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // onSubmitted
  // ---------------------------------------------------------------------------
  group('AppInput — onSubmitted', () {
    testWidgets('onSubmitted is called when user submits the field', (
      tester,
    ) async {
      var submitted = false;
      await tester.pumpWidget(
        wrap(
          AppInput(
            label: 'Email',
            textInputAction: TextInputAction.done,
            onSubmitted: () => submitted = true,
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submitted, isTrue);
    });

    testWidgets('onSubmitted is null by default (no crash)', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppInput(label: 'Email', textInputAction: TextInputAction.done),
        ),
      );
      await tester.tap(find.byType(TextField));
      // Doit s'exécuter sans exception même si onSubmitted est null.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    });
  });
}
