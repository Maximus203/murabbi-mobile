import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/save_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/location_service_provider.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_02_prayer_settings_screen.dart';
import 'package:murabbi_mobile/services/geocoding/geocoding_service.dart';
import 'package:murabbi_mobile/services/location/location_service.dart';

/// Tests widget SA-02 (écran réglages prières — GPS-only UI).
///
/// La screen a été redesignée pour utiliser exclusivement le bouton GPS
/// (plus de champs texte lat/lng exposés à l'utilisateur). Ces 4 tests
/// remplacent les 4 tests stales qui ciblaient `sa02-latitude-input` /
/// `sa02-longitude-input` qui n'existent plus dans la UI courante.
///
/// Pattern :
/// - [LocationService] est une `abstract interface class` → mock mocktail.
/// - [GeocodingService] est une classe concrète → stub via sous-classe.
class _MockPrayerSettingsRepository extends Mock
    implements PrayerSettingsRepository {}

class _FakePrayerSettings extends Fake implements PrayerSettings {}

class _MockLocationService extends Mock implements LocationService {}

/// Stub [GeocodingService] — retourne un libellé fixe sans requête HTTP
/// Nominatim (impossible en test widget sans serveur externe).
class _StubGeocodingService extends GeocodingService {
  final String stubbedLabel;

  _StubGeocodingService(this.stubbedLabel);

  @override
  Future<GeocodingResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async =>
      GeocodingSuccess(stubbedLabel);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePrayerSettings());
  });

  late _MockPrayerSettingsRepository repo;
  late _MockLocationService locationService;

  setUp(() {
    repo = _MockPrayerSettingsRepository();
    locationService = _MockLocationService();
    when(() => repo.get()).thenAnswer((_) async => null);
  });

  /// Construit le widget SA-02 avec toutes les dépendances overridées.
  ///
  /// [locationResult] : si fourni, configure [getCurrentPosition()] pour
  /// retourner ce résultat. Ne pas passer si le test ne tape pas le bouton GPS.
  Widget pumpableScreen({
    VoidCallback? onSaved,
    VoidCallback? onBack,
    LocationResult? locationResult,
    String geoLabel = 'Paris, France',
  }) {
    if (locationResult != null) {
      when(
        () => locationService.getCurrentPosition(),
      ).thenAnswer((_) async => locationResult);
    }
    return ProviderScope(
      overrides: [
        getPrayerSettingsUseCaseProvider.overrideWith(
          (ref) async => GetPrayerSettingsUseCase(repo),
        ),
        savePrayerSettingsUseCaseProvider.overrideWith(
          (ref) async => SavePrayerSettingsUseCase(repo),
        ),
        locationServiceProvider.overrideWithValue(locationService),
        geocodingServiceProvider.overrideWithValue(
          _StubGeocodingService(geoLabel),
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

  // ── Test 1 ─────────────────────────────────────────────────────────────────
  testWidgets(
    'affiche le titre "Vos prières.", le champ GPS et le bouton Continuer',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(pumpableScreen());
      await tester.pumpAndSettle();

      // Grand titre SA-02 (maquette "Vos prières.").
      expect(find.text('Vos prières.'), findsOneWidget);
      // Placeholder du champ GPS (pas de saisie manuelle dans la UI courante).
      expect(
        find.text('Appuyer pour détecter ma position'),
        findsOneWidget,
      );
      // CTA principal.
      expect(find.byKey(const Key('sa02-save-button')), findsOneWidget);
    },
  );

  // ── Test 2 ─────────────────────────────────────────────────────────────────
  testWidgets(
    'Continuer sans coordonnées affiche l\'erreur GPS requise et n\'appelle pas save',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(pumpableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sa02-save-button')));
      await tester.pumpAndSettle();

      // PrayerSettingsFormError.missingCoordinates → message GPS.
      expect(
        find.text('Utilise le bouton GPS pour détecter ta position.'),
        findsOneWidget,
      );
      verifyNever(() => repo.save(any()));
    },
  );

  // ── Test 3 ─────────────────────────────────────────────────────────────────
  testWidgets(
    'tap GPS → coordonnées Paris injectées → Continuer appelle onSaved',
    (tester) async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      await tester.binding.setSurfaceSize(const Size(400, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var savedCalled = false;
      await tester.pumpWidget(
        pumpableScreen(
          onSaved: () => savedCalled = true,
          locationResult: const LocationSuccess(
            latitude: 48.8566,
            longitude: 2.3522,
          ),
          geoLabel: 'Paris, France',
        ),
      );
      await tester.pumpAndSettle();

      // Tap sur le placeholder → déclenche getCurrentPosition().
      await tester.tap(find.text('Appuyer pour détecter ma position'));
      await tester.pumpAndSettle();

      // Après géocodage inverse, le libellé "Paris, France" remplace le placeholder.
      expect(find.text('Paris, France'), findsOneWidget);

      // Continuer — les coordonnées sont présentes → save doit être appelé.
      await tester.tap(find.byKey(const Key('sa02-save-button')));
      await tester.pumpAndSettle();

      verify(() => repo.save(any())).called(1);
      expect(savedCalled, isTrue);
    },
  );

  // ── Test 4 ─────────────────────────────────────────────────────────────────
  testWidgets(
    'GPS avec latitude > 48 fait apparaître la section "Hautes latitudes"',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        pumpableScreen(
          locationResult: const LocationSuccess(
            // Helsinki — |lat| = 60 > 48 → PrayerSettingsFormState.needsHighLatitudeRule = true
            latitude: 60.0,
            longitude: 24.94,
          ),
          geoLabel: 'Helsinki, Finlande',
        ),
      );
      await tester.pumpAndSettle();

      // Sans position détectée la section est cachée.
      expect(find.text('Hautes latitudes'), findsNothing);

      // Tap GPS → lat = 60 > 48.
      await tester.tap(find.text('Appuyer pour détecter ma position'));
      await tester.pumpAndSettle();

      // La section hautes latitudes doit maintenant être visible.
      expect(find.text('Hautes latitudes'), findsOneWidget);
    },
  );
}
