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
import 'package:murabbi_mobile/services/location/location_service.dart';

class _MockSettingsRepo extends Mock implements PrayerSettingsRepository {}

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

void main() {
  late _MockSettingsRepo repo;

  setUp(() {
    repo = _MockSettingsRepo();
    when(() => repo.get()).thenAnswer((_) async => null);
  });

  Widget pumpable(LocationService loc) {
    return ProviderScope(
      overrides: [
        locationServiceProvider.overrideWithValue(loc),
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

  testWidgets('GPS button success remplit lat/lng', (tester) async {
    final loc = _FakeLocationService(
      const LocationSuccess(latitude: 48.8566, longitude: 2.3522),
    );
    await tester.pumpWidget(pumpable(loc));
    await tester.pumpAndSettle();

    final btn = find.byKey(const Key('sa02-use-position-button'));
    expect(btn, findsOneWidget);
    await tester.tap(btn);
    await tester.pumpAndSettle();

    expect(loc.callCount, 1);
    // Les champs lat/lng sont pré-remplis (le service a retourné Paris).
    final latField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('sa02-latitude-input')),
        matching: find.byType(TextField),
      ),
    );
    expect(latField.controller!.text, contains('48.85'));
  });

  testWidgets('GPS button service disabled affiche snackbar', (tester) async {
    final loc = _FakeLocationService(const LocationServiceDisabled());
    await tester.pumpWidget(pumpable(loc));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sa02-use-position-button')));
    await tester.pump(); // snackbar animation
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Active la localisation'), findsOneWidget);
  });

  testWidgets(
    'GPS button permission denied forever affiche snackbar avec action Réglages',
    (tester) async {
      final loc = _FakeLocationService(
        const LocationPermissionDenied(deniedForever: true),
      );
      await tester.pumpWidget(pumpable(loc));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sa02-use-position-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Autorise la localisation'), findsOneWidget);
      expect(find.text('Réglages'), findsOneWidget);

      // Tap sur l'action -> openAppSettings appelé.
      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();
      expect(loc.openAppSettingsCount, 1);
    },
  );
}
