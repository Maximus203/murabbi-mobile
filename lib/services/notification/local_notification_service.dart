import 'dart:async';
import 'dart:convert';

import 'package:murabbi_mobile/domain/entities/notification_action.dart';
import 'package:murabbi_mobile/domain/entities/scheduled_notification.dart';
import 'package:murabbi_mobile/domain/services/notification_service.dart';
import 'package:murabbi_mobile/services/notification/notification_platform.dart';

/// Implémentation de `NotificationService` basée sur `NotificationPlatform`
/// (cf. ADR-018 §4.1).
///
/// Responsabilités :
/// - hashage `occurrenceId` → int32 stable et sans collision pratique
/// - sérialisation payload (occurrenceId + metadata) en JSON
/// - garantie d'idempotence (`cancel` implicite avant re-schedule)
/// - exposition d'un `actionStream` broadcast alimenté par le callback
///   natif
///
/// Le mapping vers `flutter_local_notifications` (channels Android,
/// catégories iOS, zonedSchedule en TZDateTime local) vit dans
/// `FlutterLocalNotificationPlatform` — seul module autorisé à importer
/// le plugin natif (règle ADR-018 §2.2).
class LocalNotificationService implements NotificationService {
  final NotificationPlatform _platform;
  final StreamController<NotificationAction> _controller =
      StreamController<NotificationAction>.broadcast();

  /// Cache id natif → permet `cancel(occurrenceId)` sans re-hasher.
  /// Optionnel : on hash de toute façon `occurrenceId` pour fallback.
  final Map<String, int> _idCache = {};

  LocalNotificationService({required NotificationPlatform platform})
    : _platform = platform;

  @override
  Future<void> initialize() async {
    await _platform.initialize(onActionReceived: _controller.add);
  }

  @override
  Future<bool> requestPermission() => _platform.requestPermission();

  @override
  Future<NotificationPermissionStatus> permissionStatus() =>
      _platform.permissionStatus();

  @override
  Future<void> schedule(ScheduledNotification spec) async {
    final id = _notificationIdFor(spec.occurrenceId);
    _idCache[spec.occurrenceId] = id;

    // Idempotence : on annule défensivement la précédente (ADR-018 §4.1).
    await _platform.cancel(id);

    final payload = <String, String>{
      'occurrenceId': spec.occurrenceId,
      ...spec.payload,
    };

    await _platform.schedule(
      PlatformScheduleRequest(
        notificationId: id,
        title: spec.title,
        body: spec.body,
        scheduledAt: spec.scheduledAt,
        actions: spec.actions,
        payload: jsonEncode(payload),
      ),
    );
  }

  @override
  Future<void> cancel(String occurrenceId) async {
    final id = _idCache[occurrenceId] ?? _notificationIdFor(occurrenceId);
    _idCache.remove(occurrenceId);
    await _platform.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    _idCache.clear();
    await _platform.cancelAll();
  }

  @override
  Stream<NotificationAction> get actionStream => _controller.stream;

  /// Hash stable de `occurrenceId` (UUID v4 typique) vers un int32 positif.
  ///
  /// Algorithme : FNV-1a 32-bit, masqué sur 31 bits pour garantir une
  /// valeur ≤ `0x7FFFFFFF` (compat iOS `userNotificationIdentifier` et
  /// Android `NotificationManager.notify`).
  ///
  /// Collisions : 2^31 buckets. Pour quelques milliers d'occurrences
  /// vivantes par device, probabilité de collision ≪ 10⁻⁴. Acceptable
  /// pour V1.
  int _notificationIdFor(String occurrenceId) {
    const int fnvPrime = 0x01000193;
    const int fnvOffset = 0x811c9dc5;
    var hash = fnvOffset;
    for (final byte in utf8.encode(occurrenceId)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}
