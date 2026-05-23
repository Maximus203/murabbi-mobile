// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/prayer_user_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_user_settings_repository.dart';
import 'package:murabbi_mobile/services/prayer/prayer_settings_sync_service.dart';

/// Mock du repository — simule local + remote séparément.
class _MockPrayerUserSettingsRepository extends Mock
    implements PrayerUserSettingsRepository {}

void main() {
  late _MockPrayerUserSettingsRepository repo;
  late PrayerSettingsSyncService sut;

  const userId = 'user-001';

  final defaultSettings = PrayerUserSettings.defaults(userId: userId);

  final freshSettings = PrayerUserSettings(
    userId: userId,
    latitude: 48.85,
    longitude: 2.35,
    locationMode: LocationMode.manual,
    calculationMethod: PrayerCalculationMethod.muslimWorldLeague,
    madhab: PrayerMadhab.shafi,
    highLatitudeRule: PrayerHighLatitudeRule.middleOfTheNight,
    autoDst: true,
    adjustments: PrayerUserSettings.zeroAdjustments(),
    updatedAt: DateTime.utc(2026, 5, 23, 8, 0),
  );

  final staleSettings = PrayerUserSettings(
    userId: userId,
    latitude: 48.85,
    longitude: 2.35,
    locationMode: LocationMode.manual,
    calculationMethod: PrayerCalculationMethod.muslimWorldLeague,
    madhab: PrayerMadhab.shafi,
    highLatitudeRule: PrayerHighLatitudeRule.middleOfTheNight,
    autoDst: true,
    adjustments: PrayerUserSettings.zeroAdjustments(),
    // Vieux de plus d'1 heure → stale.
    updatedAt: DateTime.utc(2026, 5, 23, 6, 0),
  );

  final remoteSettings = PrayerUserSettings(
    userId: userId,
    latitude: 51.5,
    longitude: -0.1,
    locationMode: LocationMode.manual,
    calculationMethod: PrayerCalculationMethod.muslimWorldLeague,
    madhab: PrayerMadhab.hanafi,
    highLatitudeRule: PrayerHighLatitudeRule.seventhOfTheNight,
    autoDst: false,
    adjustments: PrayerUserSettings.zeroAdjustments(),
    updatedAt: DateTime.utc(2026, 5, 23, 9, 0), // plus récent que staleSettings
  );

  setUp(() {
    repo = _MockPrayerUserSettingsRepository();
    sut = PrayerSettingsSyncService(repository: repo);
  });

  // ------------------------------------------------------------------
  // Test 1 — load retourne le cache local si age < 1h
  // ------------------------------------------------------------------
  test('load_returns_local_if_fresh', () async {
    when(() => repo.loadLocal(userId)).thenAnswer((_) async => freshSettings);

    final result = await sut.loadSettings(userId);

    expect(result.latitude, freshSettings.latitude);
    // Pas d'appel réseau si cache frais.
    verifyNever(() => repo.fetchRemote(userId));
  });

  // ------------------------------------------------------------------
  // Test 2 — load fetch remote si cache >= 1h
  // ------------------------------------------------------------------
  test('load_fetches_remote_if_stale', () async {
    when(() => repo.loadLocal(userId)).thenAnswer((_) async => staleSettings);
    when(
      () => repo.fetchRemote(userId),
    ).thenAnswer((_) async => remoteSettings);
    when(
      () => repo.saveLocal(any()),
    ).thenAnswer((_) async {});

    final result = await sut.loadSettings(userId);

    expect(result.latitude, remoteSettings.latitude);
    verify(() => repo.fetchRemote(userId)).called(1);
  });

  // ------------------------------------------------------------------
  // Test 3 — save écrit local immédiatement
  // ------------------------------------------------------------------
  test('save_writes_local_immediately', () async {
    when(() => repo.saveLocal(any())).thenAnswer((_) async {});
    when(
      () => repo.upsertRemote(any()),
    ).thenAnswer((_) async {});

    await sut.saveSettings(userId, freshSettings);

    verify(() => repo.saveLocal(freshSettings)).called(1);
  });

  // ------------------------------------------------------------------
  // Test 4 — save pousse vers Supabase
  // ------------------------------------------------------------------
  test('save_pushes_to_supabase', () async {
    when(() => repo.saveLocal(any())).thenAnswer((_) async {});
    when(
      () => repo.upsertRemote(any()),
    ).thenAnswer((_) async {});

    await sut.saveSettings(userId, freshSettings);

    verify(() => repo.upsertRemote(freshSettings)).called(1);
  });

  // ------------------------------------------------------------------
  // Test 5 — sync: remote wins si remote.updatedAt > local.updatedAt
  // ------------------------------------------------------------------
  test('sync_remote_wins_on_conflict', () async {
    when(
      () => repo.fetchRemote(userId),
    ).thenAnswer((_) async => remoteSettings);
    when(
      () => repo.saveLocal(any()),
    ).thenAnswer((_) async {});

    final result = await sut.syncFromRemote(userId);

    // remoteSettings.updatedAt (09:00) > staleSettings.updatedAt (06:00)
    expect(result.updatedAt, remoteSettings.updatedAt);
    verify(() => repo.saveLocal(remoteSettings)).called(1);
  });

  // ------------------------------------------------------------------
  // Test 6 — load offline retourne le cache même si réseau KO
  // ------------------------------------------------------------------
  test('load_offline_returns_cached', () async {
    when(
      () => repo.loadLocal(userId),
    ).thenAnswer((_) async => staleSettings);
    when(() => repo.fetchRemote(userId)).thenThrow(Exception('Network error'));

    // Doit retourner le cache stale sans lever d'exception.
    final result = await sut.loadSettings(userId);

    expect(result.latitude, staleSettings.latitude);
  });

  // ------------------------------------------------------------------
  // Test 7 — premier load sans données → defaults
  // ------------------------------------------------------------------
  test('default_settings_created_if_none', () async {
    when(() => repo.loadLocal(userId)).thenAnswer((_) async => null);
    when(
      () => repo.fetchRemote(userId),
    ).thenAnswer((_) async => null);

    final result = await sut.loadSettings(userId);

    expect(result.userId, userId);
    expect(result.calculationMethod, PrayerCalculationMethod.muslimWorldLeague);
    expect(result.madhab, PrayerMadhab.shafi);
  });

  // ------------------------------------------------------------------
  // Test 8 — adjustments contient bien les 5 prières
  // ------------------------------------------------------------------
  test('adjustments_map_5_prayers', () {
    final adjustments = PrayerUserSettings.zeroAdjustments();

    expect(adjustments.length, 5);
    expect(adjustments.containsKey(PrayerName.fajr), isTrue);
    expect(adjustments.containsKey(PrayerName.dhuhr), isTrue);
    expect(adjustments.containsKey(PrayerName.asr), isTrue);
    expect(adjustments.containsKey(PrayerName.maghrib), isTrue);
    expect(adjustments.containsKey(PrayerName.isha), isTrue);
  });

  // ------------------------------------------------------------------
  // Test 9 — madhab roundtrip JSON correct
  // ------------------------------------------------------------------
  test('madhab_roundtrips_correctly', () {
    final settings = PrayerUserSettings(
      userId: userId,
      latitude: 0,
      longitude: 0,
      locationMode: LocationMode.automatic,
      calculationMethod: PrayerCalculationMethod.muslimWorldLeague,
      madhab: PrayerMadhab.hanafi,
      highLatitudeRule: PrayerHighLatitudeRule.middleOfTheNight,
      autoDst: true,
      adjustments: PrayerUserSettings.zeroAdjustments(),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    final json = settings.toJson();
    final restored = PrayerUserSettings.fromJson(json);

    expect(restored.madhab, PrayerMadhab.hanafi);
  });

  // ------------------------------------------------------------------
  // Test 10 — calculationMethod roundtrip JSON correct
  // ------------------------------------------------------------------
  test('calculation_method_roundtrips', () {
    final settings = PrayerUserSettings(
      userId: userId,
      latitude: 0,
      longitude: 0,
      locationMode: LocationMode.automatic,
      calculationMethod: PrayerCalculationMethod.egyptian,
      madhab: PrayerMadhab.shafi,
      highLatitudeRule: PrayerHighLatitudeRule.twilightAngle,
      autoDst: false,
      adjustments: PrayerUserSettings.zeroAdjustments(),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    final json = settings.toJson();
    final restored = PrayerUserSettings.fromJson(json);

    expect(restored.calculationMethod, PrayerCalculationMethod.egyptian);
    expect(restored.highLatitudeRule, PrayerHighLatitudeRule.twilightAngle);
  });
}
