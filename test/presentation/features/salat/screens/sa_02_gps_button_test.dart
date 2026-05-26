import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/save_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/location_service_provider.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_02_prayer_settings_screen.dart';
import 'package:murabbi_mobile/services/geocoding/geocoding_service.dart';
import 'package:murabbi_mobile/services/location/location_service.dart';

/// Tests du comportement GPS de SA-02 (cas d'erreur et succès).
///
/// Ces tests ont été mis à jour après la redesign SA-02 :
/// - L'ancien bouton clé `sa02-use-position-button` n'existe plus.
/// - Le déclencheur GPS est désormais le GestureDetector sur le champ
///   de localisation (texte "Appuyer pour détecter ma position").
class _MockSettingsRepo extends Mock implements PrayerSettingsRepository {}

/// Fake [LocationService] — retourne un [LocationResult] configurable
/// sans dépendance geolocator ou OS.
class _FakeLocationService implements LocationService {
  _FakeLocationService(this.result);
  final LocationResult result;
  int callCount = 0;
  int openAppSettingsCount = 0;
  int openLocationSettingsCount = 0;

  @override
  Future<LocationResult> getCurrentPosition() async {
    callCount++;
    return result;
  }

  @override
  Future<void> openAppSettings() async {
    openAppSettingsCount++;
  }

  @override
  Future<void> openLocationSettings() async {
    openLocationSettingsCount++;
  }
}

/// Stub [GeocodingService] — retourne le libellé donné sans HTTP.
class _StubGeo extends GeocodingService {
  final String label;
  _StubGeo(this.label);

  @override
  Future<GeocodingResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async =>
      GeocodingSuccess(label);
}

void main() {
  late _MockSettingsRepo repo;

  setUp(() {
    repo = _MockSettingsRepo();
    when(() => repo.get()).thenAnswer((_) async => null);
  });

  Widget pumpable(
    LocationService loc, {
    GeocodingService? geo,
  }) {
    return ProviderScope(
      overrides: [
        locationServiceProvider.overrideWithValue(loc),
        geocodingServiceProvider.overrideWithValue(
          geo ?? _StubGeo('Paris, France'),
        ),
        getPrayerSettingsUseCaseProvider.overrideWith(
          (ref) async => GetPrayerSettingsUseCase(repo),
        ),
        savePrayerSettingsUseCaseProvider.overrideWith(
          (ref) async => SavePrayerSettingsUseCase(repo),
        ),
      ],
      child: MaterialApp(
        home: Sa02PrayerSettingsScreen(onSaved: () {}, onBack: () {}),
      ),
    );
  }

  /// Finder du déclencheur GPS — le GestureDetector sur le champ de
  /// localisation (plus de clé `sa02-use-position-button` dans la UI courante).
  final gpsField = find.text('Appuyer pour détecter ma position');

  testWidgets(
    'GPS success : getCurrentPosition appelé + libellé ville affiché',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final loc = _FakeLocationService(
        const LocationSuccess(latitude: 48.8566, longitude: 2.3522),
      );
      await tester.pumpWidget(pumpable(loc, geo: _StubGeo('Paris, France')));
      await tester.pumpAndSettle();

      expect(gpsField, findsOneWidget);
      await tester.tap(gpsField);
      await tester.pumpAndSettle();

      // getCurrentPosition a bien été appelé.
      expect(loc.callCount, 1);
      // Après géocodage, le label de ville remplace le placeholder.
      expect(find.text('Paris, France'), findsOneWidget);
      expect(gpsField, findsNothing); // placeholder disparu
    },
  );

  testWidgets('GPS service disabled affiche snackbar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final loc = _FakeLocationService(const LocationServiceDisabled());
    await tester.pumpWidget(pumpable(loc));
    await tester.pumpAndSettle();

    await tester.tap(gpsField);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Active la localisation'), findsOneWidget);
  });

  testWidgets(
    'GPS permission denied forever affiche snackbar avec action Réglages',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final loc = _FakeLocationService(
        const LocationPermissionDenied(deniedForever: true),
      );
      await tester.pumpWidget(pumpable(loc));
      await tester.pumpAndSettle();

      await tester.tap(gpsField);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Autorise la localisation'), findsOneWidget);
      expect(find.text('Réglages'), findsOneWidget);

      // Tap sur l'action → openAppSettings appelé.
      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();
      expect(loc.openAppSettingsCount, 1);
    },
  );
}
