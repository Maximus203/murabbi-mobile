import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';
import 'package:murabbi_mobile/presentation/widgets/app_video_background.dart';
import 'package:murabbi_mobile/services/onboarding_flag_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub de [OnboardingFlagStorage] dont [markCompleted] échoue toujours —
/// sert à reproduire le bug #118 (loading bloqué quand la persistance jette).
class _FailingOnboardingFlagStorage extends OnboardingFlagStorage {
  @override
  Future<bool> isCompleted() async => false;

  @override
  Future<void> markCompleted() async {
    throw Exception('storage indisponible');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget makeApp({VoidCallback? onCompleted}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Setup01OnboardingScreen(onCompleted: onCompleted ?? () {}),
      ),
    );
  }

  testWidgets('renders first slide + Suivant + Passer', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.text('Localisation'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
    // Pas encore "Commencer".
    expect(find.text('Commencer'), findsNothing);
  });

  testWidgets(
    'tapping "Suivant" 3x reaches "Commencer" CTA on the last slide',
    (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Tout est prêt'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
    },
  );

  testWidgets('"Commencer" calls onCompleted', (tester) async {
    var called = 0;
    await tester.pumpWidget(makeApp(onCompleted: () => called++));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(called, 1);
  });

  testWidgets('"Passer" from slide 1 calls onCompleted (skip)', (tester) async {
    var called = 0;
    await tester.pumpWidget(makeApp(onCompleted: () => called++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(called, 1);
  });

  testWidgets(
    '"Passer" persists onboarding flag (read back via SharedPreferences)',
    (tester) async {
      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      // Q3-A : nouveau flag onboarding_seen_v1 (pre-auth pédagogique).
      expect(prefs.getBool('onboarding_seen_v1'), isTrue);
    },
  );

  testWidgets('slide 1 affiche AppVideoBackground (#70)', (tester) async {
    await tester.pumpWidget(makeApp());
    // pump() sans pumpAndSettle : la vidéo ne se "stabilise" jamais.
    await tester.pump();
    expect(find.byType(AppVideoBackground), findsOneWidget);
  });

  // #118 — régression : "Commencer" ne doit JAMAIS rester bloqué sur
  // "Enregistrement…". Même si la persistance du flag échoue, le handler
  // réinitialise l'état loading et navigue (onCompleted appelé).
  testWidgets(
    '#118 "Commencer" navigue et sort du loading même si le storage échoue',
    (tester) async {
      var called = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingFlagStorageProvider.overrideWithValue(
              _FailingOnboardingFlagStorage(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Setup01OnboardingScreen(onCompleted: () => called++),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      // Navigation déclenchée malgré l'échec du storage.
      expect(called, 1);
      // Le bouton n'est pas resté bloqué sur l'état loading.
      expect(find.text('Enregistrement…'), findsNothing);
      expect(find.text('Commencer'), findsOneWidget);
    },
  );

  // #121 — sur le dernier slide, "Passer" est masqué (CTA "Commencer"
  // couvre déjà l'action). Il reste visible sur les slides intermédiaires.
  testWidgets('#121 "Passer" masqué sur le dernier slide', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    // Slide 1 : "Passer" visible.
    expect(
      tester.widget<Visibility>(_passerVisibility(tester)).visible,
      isTrue,
    );

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }

    // Slide 4 : "Passer" masqué.
    expect(
      tester.widget<Visibility>(_passerVisibility(tester)).visible,
      isFalse,
    );
  });
}

/// Localise le [Visibility] qui enveloppe le bouton texte "Passer".
Finder _passerVisibility(WidgetTester tester) {
  return find.ancestor(
    of: find.text('Passer'),
    matching: find.byType(Visibility),
  );
}
