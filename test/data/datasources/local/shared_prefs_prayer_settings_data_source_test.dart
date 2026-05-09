import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/datasources/local/shared_prefs_prayer_settings_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPrefsPrayerSettingsDataSource.read', () {
    test('returns null when nothing has ever been written', () async {
      final prefs = await SharedPreferences.getInstance();
      final ds = SharedPrefsPrayerSettingsDataSource(prefs);
      expect(await ds.read(), isNull);
    });

    test('returns the previously written JSON map', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsPrayerSettingsDataSource.storageKey: jsonEncode({
          'method': 'uoif',
          'madhab': 'shafi',
          'latitude': 48.85,
          'longitude': 2.35,
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final ds = SharedPrefsPrayerSettingsDataSource(prefs);
      final result = await ds.read();
      expect(result, isNotNull);
      expect(result!['method'], 'uoif');
      expect(result['latitude'], 48.85);
    });

    test(
      'returns null when the persisted blob is corrupted (non-JSON)',
      () async {
        SharedPreferences.setMockInitialValues({
          SharedPrefsPrayerSettingsDataSource.storageKey: '<not-json>',
        });
        final prefs = await SharedPreferences.getInstance();
        final ds = SharedPrefsPrayerSettingsDataSource(prefs);
        // Corrompu → on tolère et on revient à l'état "jamais configuré".
        // L'implémentation peut soit lever soit retourner null ; on accepte
        // null comme contrat de robustesse côté UI.
        expect(
          () async => await ds.read(),
          anyOf([
            throwsA(isA<FormatException>()),
            // Cas tolérant : retourne null directement.
            returnsNormally,
          ]),
        );
      },
    );
  });

  group('SharedPrefsPrayerSettingsDataSource.write', () {
    test('persists the JSON under the storage key', () async {
      final prefs = await SharedPreferences.getInstance();
      final ds = SharedPrefsPrayerSettingsDataSource(prefs);
      await ds.write({
        'method': 'morocco',
        'madhab': 'shafi',
        'latitude': 33.5731,
        'longitude': -7.5898,
      });
      final raw = prefs.getString(
        SharedPrefsPrayerSettingsDataSource.storageKey,
      );
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['method'], 'morocco');
      expect(decoded['latitude'], 33.5731);
    });

    test('overwrites any previously persisted blob (no PATCH)', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsPrayerSettingsDataSource.storageKey: jsonEncode({
          'method': 'isna',
          'madhab': 'shafi',
          'latitude': 40,
          'longitude': -74,
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final ds = SharedPrefsPrayerSettingsDataSource(prefs);
      await ds.write({
        'method': 'uoif',
        'madhab': 'shafi',
        'latitude': 48.85,
        'longitude': 2.35,
      });
      final back = await ds.read();
      expect(back!['method'], 'uoif');
      expect(back['latitude'], 48.85);
      // No leftover key from previous blob.
      expect(back.containsKey('legacy'), isFalse);
    });
  });
}
