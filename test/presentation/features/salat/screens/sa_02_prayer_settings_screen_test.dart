import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/save_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_02_prayer_settings_screen.dart';

class _MockPrayerSettingsRepository extends Mock
    implements PrayerSettingsRepository {}

class _FakePrayerSettings extends Fake implements PrayerSettings {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePrayerSettings());
  });

  late _MockPrayerSettingsRepository repo;

  setUp(() {
    repo = _MockPrayerSettingsRepository();
    when(() => repo.get()).thenAnswer((_) async => null);
  });

  Widget pumpableScreen({VoidCallback? onSaved, VoidCallback? onBack}) {
    return ProviderScope(
      overrides: [
        getPrayerSettingsUseCaseProvider.overrideWith(
          (ref) async => GetPrayerSettingsUseCase(repo),
        ),
        savePrayerSettingsUseCaseProvider.overrideWith(
          (ref) async => SavePrayerSettingsUseCase(repo),
        ),
      ],
      child: MaterialApp(
        home: Sa02PrayerSettingsScreen(
          onSaved: onSaved ?? () {},
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  testWidgets('rend les champs latitude / longitude et le bouton Enregistrer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(pumpableScreen());
    await tester.pumpAndSettle();

    expect(find.text('LATITUDE'), findsOneWidget);
    expect(find.text('LONGITUDE'), findsOneWidget);
    expect(find.byKey(const Key('sa02-save-button')), findsOneWidget);
  });

  testWidgets(
    'Enregistrer sans coordonnées affiche un message d\'erreur explicite',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(pumpableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sa02-save-button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'latitude',
          findRichText: false,
          skipOffstage: false,
        ),
        findsWidgets,
      );
      verifyNever(() => repo.save(any()));
    },
  );

  testWidgets('saisie de coordonnées valides puis sauvegarde appelle onSaved', (
    tester,
  ) async {
    when(() => repo.save(any())).thenAnswer((_) async {});

    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var savedCalled = false;
    await tester.pumpWidget(pumpableScreen(onSaved: () => savedCalled = true));
    await tester.pumpAndSettle();

    // Lat = 48.8566 (Paris)
    final latField = find.byKey(const Key('sa02-latitude-input'));
    final lngField = find.byKey(const Key('sa02-longitude-input'));
    await tester.enterText(latField, '48.8566');
    await tester.enterText(lngField, '2.3522');
    await tester.pumpAndSettle();

    final saveBtn = find.byKey(const Key('sa02-save-button'));
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    verify(() => repo.save(any())).called(1);
    expect(savedCalled, isTrue);
  });

  testWidgets('la section hautes latitudes apparaît quand latitude > 48', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(pumpableScreen());
    await tester.pumpAndSettle();

    // Au boot pas de lat → pas de section
    expect(find.text('Hautes latitudes'), findsNothing);

    final latField = find.byKey(const Key('sa02-latitude-input'));
    await tester.enterText(latField, '60.0');
    await tester.pumpAndSettle();

    expect(find.text('Hautes latitudes'), findsOneWidget);
  });
}
