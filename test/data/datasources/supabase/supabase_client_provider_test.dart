import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';

/// Tests SupabaseConfig — Copilot review #10.
/// Le client Riverpod lui-même n'est pas testé unitairement (il dépend de
/// `Supabase.initialize` qui requiert un binding Flutter et un endpoint réel) ;
/// il sera couvert par des integration tests en Phase 2+.
void main() {
  group('SupabaseConfig', () {
    test('isConfigured = true when both fields are non-empty', () {
      const config = SupabaseConfig(
        url: 'https://abc.supabase.co',
        anonKey: 'eyJ.fake.token',
      );
      expect(config.isConfigured, isTrue);
    });

    test('isConfigured = false when url is empty', () {
      const config = SupabaseConfig(url: '', anonKey: 'eyJ.fake');
      expect(config.isConfigured, isFalse);
    });

    test('isConfigured = false when anonKey is empty', () {
      const config = SupabaseConfig(url: 'https://abc.co', anonKey: '');
      expect(config.isConfigured, isFalse);
    });

    test('isConfigured = false when both are empty (fromEnvironment default)', () {
      const config = SupabaseConfig(url: '', anonKey: '');
      expect(config.isConfigured, isFalse);
    });

    test('fromEnvironment defaults to empty values when no --dart-define', () {
      // Sans --dart-define, String.fromEnvironment retourne ''.
      // L'app démarre alors en mode design (cf. doc du provider).
      final config = SupabaseConfig.fromEnvironment();
      expect(config.url, isA<String>());
      expect(config.anonKey, isA<String>());
      expect(config.isConfigured, isFalse);
    });
  });
}
