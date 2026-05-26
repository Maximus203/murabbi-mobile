import 'package:logger/logger.dart';
import 'package:murabbi_mobile/domain/entities/prayer_user_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_user_settings_repository.dart';

/// Service de synchronisation des préférences de prière utilisateur.
///
/// Implémente une stratégie **dual-write** :
/// - Lecture : cache local si age < [_cacheTtl], sinon fetch remote.
/// - Écriture : local immédiat + push remote asynchrone.
/// - Conflit : `remote wins` basé sur [PrayerUserSettings.updatedAt].
///
/// Cf. MOB-004 — ADR-018 §3.5 (source de vérité UTC).
class PrayerSettingsSyncService {
  final PrayerUserSettingsRepository _repository;
  final Logger _logger;

  /// TTL du cache local — 1 heure. Au-delà, un fetch remote est déclenché.
  static const _cacheTtl = Duration(hours: 1);

  PrayerSettingsSyncService({
    required PrayerUserSettingsRepository repository,
    Logger? logger,
  }) : _repository = repository,
       _logger = logger ?? Logger();

  /// Charge les settings pour [userId].
  ///
  /// - Si le cache local est frais (< [_cacheTtl]) : retourne le cache.
  /// - Si le cache est stale (>= [_cacheTtl]) : fetch remote, met à jour
  ///   le cache local, retourne le résultat remote.
  /// - Si offline et cache stale : retourne le cache stale (dégradé gracieux).
  /// - Si aucune donnée locale ni remote : retourne les [PrayerUserSettings.defaults].
  Future<PrayerUserSettings> loadSettings(String userId) async {
    final local = await _repository.loadLocal(userId);

    if (local != null && _isFresh(local)) {
      _logger.d('PrayerSettingsSyncService: cache hit (userId=$userId)');
      return local;
    }

    // Cache stale ou absent — fetch remote.
    try {
      final remote = await _repository.fetchRemote(userId);
      if (remote != null) {
        _logger.d(
          'PrayerSettingsSyncService: remote fetch OK (userId=$userId)',
        );
        await _repository.saveLocal(remote);
        return remote;
      }
    } catch (e, st) {
      _logger.w(
        'PrayerSettingsSyncService: remote fetch failed, '
        'falling back to local cache',
        error: e,
        stackTrace: st,
      );
      // Offline fallback : retourne cache stale si disponible.
      if (local != null) return local;
    }

    // Aucune donnée nulle part → defaults.
    _logger.i(
      'PrayerSettingsSyncService: no data found, using defaults '
      '(userId=$userId)',
    );
    return PrayerUserSettings.defaults(userId: userId);
  }

  /// Persiste [settings] pour [userId].
  ///
  /// Écrit localement de façon synchrone, puis pousse vers Supabase.
  /// L'échec du push remote est loggué mais ne lève pas d'exception —
  /// la donnée locale reste cohérente.
  Future<void> saveSettings(String userId, PrayerUserSettings settings) async {
    // Écriture locale immédiate.
    await _repository.saveLocal(settings);
    _logger.d('PrayerSettingsSyncService: local write OK (userId=$userId)');

    // Push remote (best-effort).
    try {
      await _repository.upsertRemote(settings);
      _logger.d('PrayerSettingsSyncService: remote upsert OK (userId=$userId)');
    } catch (e, st) {
      _logger.w(
        'PrayerSettingsSyncService: remote upsert failed — '
        'data saved locally, will sync on next load',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Force la synchronisation depuis Supabase.
  ///
  /// Stratégie `remote wins` : le remote est toujours sauvegardé localement
  /// sans comparaison d'horodatage — la méthode est appelée explicitement
  /// quand on veut forcer le refresh (ex : changement de device).
  ///
  /// Retourne les settings remote, ou les settings locaux si le fetch échoue.
  Future<PrayerUserSettings> syncFromRemote(String userId) async {
    final remote = await _repository.fetchRemote(userId);

    if (remote != null) {
      await _repository.saveLocal(remote);
      _logger.i(
        'PrayerSettingsSyncService: sync from remote OK (userId=$userId)',
      );
      return remote;
    }

    // Pas de données remote → retourne local ou defaults.
    final local = await _repository.loadLocal(userId);
    return local ?? PrayerUserSettings.defaults(userId: userId);
  }

  // ---------------------------------------------------------------------------
  // Helpers privés
  // ---------------------------------------------------------------------------

  /// Vérifie si le cache local est encore frais (age < [_cacheTtl]).
  bool _isFresh(PrayerUserSettings settings) {
    final age = DateTime.now().toUtc().difference(settings.updatedAt);
    return age < _cacheTtl;
  }
}
