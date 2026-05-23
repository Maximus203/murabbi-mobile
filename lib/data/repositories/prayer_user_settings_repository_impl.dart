import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:murabbi_mobile/domain/entities/prayer_user_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_user_settings_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implémentation production de [PrayerUserSettingsRepository].
///
/// Couche locale : `flutter_secure_storage` — clé composite par userId.
/// Couche remote : Supabase table `prayer_user_settings` (cf. ADM-006).
///
/// **Règle d'import** : seule cette classe (data layer) peut importer
/// `supabase_flutter` — jamais `domain/` ni `presentation/` (cf. ADR-001).
class PrayerUserSettingsRepositoryImpl implements PrayerUserSettingsRepository {
  final FlutterSecureStorage _secureStorage;
  final SupabaseClient _supabase;
  final Logger _logger;

  static const _storageKeyPrefix = 'prayer_user_settings_';
  static const _tableName = 'prayer_user_settings';

  PrayerUserSettingsRepositoryImpl({
    required FlutterSecureStorage secureStorage,
    required SupabaseClient supabase,
    Logger? logger,
  }) : _secureStorage = secureStorage,
       _supabase = supabase,
       _logger = logger ?? Logger();

  String _storageKey(String userId) => '$_storageKeyPrefix$userId';

  @override
  Future<PrayerUserSettings?> loadLocal(String userId) async {
    final raw = await _secureStorage.read(key: _storageKey(userId));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PrayerUserSettings.fromJson(json);
    } catch (e, st) {
      _logger.w(
        'PrayerUserSettingsRepositoryImpl: corrupt local data — discarding',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Future<void> saveLocal(PrayerUserSettings settings) async {
    final json = jsonEncode(settings.toJson());
    await _secureStorage.write(key: _storageKey(settings.userId), value: json);
  }

  @override
  Future<PrayerUserSettings?> fetchRemote(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return PrayerUserSettings.fromJson(response);
    } on PostgrestException catch (e) {
      _logger.e(
        'PrayerUserSettingsRepositoryImpl: remote fetch failed',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> upsertRemote(PrayerUserSettings settings) async {
    try {
      await _supabase
          .from(_tableName)
          .upsert(settings.toJson(), onConflict: 'user_id');
    } on PostgrestException catch (e) {
      _logger.e(
        'PrayerUserSettingsRepositoryImpl: remote upsert failed',
        error: e,
      );
      rethrow;
    }
  }
}
