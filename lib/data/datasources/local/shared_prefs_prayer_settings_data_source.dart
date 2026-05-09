import 'dart:convert';

import 'package:murabbi_mobile/data/datasources/prayer_settings_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implémentation locale via `SharedPreferences` (cf. ADR-013 décision §V1).
///
/// Cohérent avec ADR-012 (`onboarding_seen` également local). Migration vers
/// Supabase prévue V1.5 si le besoin de sync multi-device émerge.
class SharedPrefsPrayerSettingsDataSource implements PrayerSettingsDataSource {
  /// Clé unique du blob JSON. Versionnée pour permettre une migration douce
  /// si la forme JSON évolue (ex. `_v2`).
  static const String storageKey = 'murabbi_prayer_settings_v1';

  final SharedPreferences _prefs;

  const SharedPrefsPrayerSettingsDataSource(this._prefs);

  @override
  Future<Map<String, dynamic>?> read() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      // Blob corrompu / forme inattendue — on ignore pour ne pas bloquer
      // l'utilisateur. La couche au-dessus retombera sur les defaults.
      return null;
    }
    return decoded;
  }

  @override
  Future<void> write(Map<String, dynamic> json) async {
    await _prefs.setString(storageKey, jsonEncode(json));
  }
}
