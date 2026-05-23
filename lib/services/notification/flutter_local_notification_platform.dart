import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:murabbi_mobile/domain/entities/notification_action.dart';
import 'package:murabbi_mobile/services/notification/notification_platform.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Implémentation de [NotificationPlatform] basée sur
/// `flutter_local_notifications` (ADR-018 §4.1).
///
/// **Seul fichier autorisé à importer `flutter_local_notifications`**
/// (cf. ADR-018 §2.2 — règle d'isolation d'import).
///
/// Tests unitaires : non couverts directement — le plugin natif demande un
/// device pour `zonedSchedule`. Couvert manuellement en integration test
/// (cf. issue MOB-002 DoD : « planifier une occurrence à +30s, vérifier
/// que la notif part avec les 3 boutons »).
class FlutterLocalNotificationPlatform implements NotificationPlatform {
  final FlutterLocalNotificationsPlugin _plugin;
  final Logger _logger;

  /// Channel Android dédié aux alertes habitudes + prière (ADR-018 §4.1).
  static const String channelIdHabit = 'habit_alerts';
  static const String channelIdPrayer = 'prayer_alerts';

  /// Catégorie iOS unique — les actions affichées dépendent du payload.
  static const String iosCategoryHabit = 'habit_alert';
  static const String iosCategoryPrayer = 'prayer_alert';

  /// Callback bufferisé tant que `initialize()` n'a pas été appelé.
  void Function(NotificationAction)? _onActionReceived;

  FlutterLocalNotificationPlatform({
    FlutterLocalNotificationsPlugin? plugin,
    Logger? logger,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _logger = logger ?? Logger();

  @override
  Future<void> initialize({
    required void Function(NotificationAction action) onActionReceived,
  }) async {
    _onActionReceived = onActionReceived;

    // Timezone — requis par `zonedSchedule` (ADR-018 §9).
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleResponse,
      // backgroundHandler optionnel — V1 traite l'action en foreground next
      // launch via le replay de `pendingNotificationRequests`. À renforcer
      // dans MOB-006 si besoin (top-level function obligatoire).
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    if (Platform.isAndroid) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      if (enabled == null) return NotificationPermissionStatus.notDetermined;
      return enabled
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    }
    // iOS : le plugin n'expose pas un getter direct ; on retourne
    // notDetermined par défaut, le `requestPermission` rafraîchira l'état.
    return NotificationPermissionStatus.notDetermined;
  }

  @override
  Future<void> schedule(PlatformScheduleRequest request) async {
    final tzScheduled = tz.TZDateTime.from(request.scheduledAt, tz.local);

    final androidActions = request.actions
        .map(
          (a) => AndroidNotificationAction(
            a.name,
            _actionLabel(a),
            showsUserInterface: false,
            cancelNotification: true,
          ),
        )
        .toList(growable: false);

    final androidDetails = AndroidNotificationDetails(
      channelIdHabit,
      'Rappels d\'habitudes & prières',
      channelDescription: 'Notifications planifiées par Murabbi (ADR-018)',
      importance: Importance.high,
      priority: Priority.high,
      actions: androidActions,
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: iosCategoryHabit,
    );

    await _plugin.zonedSchedule(
      request.notificationId,
      request.title,
      request.body,
      tzScheduled,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: request.payload,
    );
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Callback unifié pour les taps OS. Reconstruit une [NotificationAction]
  /// à partir du payload JSON et de l'`actionId` natif, puis la dispatch
  /// sur le callback fourni à `initialize`.
  void _handleResponse(NotificationResponse response) {
    final cb = _onActionReceived;
    if (cb == null) {
      _logger.w(
        'NotificationResponse reçu avant initialize() — drop ${response.id}',
      );
      return;
    }

    final payloadStr = response.payload ?? '{}';
    Map<String, String> payload;
    try {
      final raw = jsonDecode(payloadStr) as Map<String, dynamic>;
      payload = raw.map((k, v) => MapEntry(k, v.toString()));
    } on FormatException catch (e, st) {
      _logger.e(
        'Notification payload invalide: $payloadStr',
        error: e,
        stackTrace: st,
      );
      return;
    }

    final occurrenceId = payload['occurrenceId'];
    if (occurrenceId == null) {
      _logger.w('Notification sans occurrenceId — drop');
      return;
    }

    final actionId = _parseActionId(response.actionId);
    cb(
      NotificationAction(
        occurrenceId: occurrenceId,
        actionId: actionId,
        receivedAt: DateTime.now().toUtc(),
        payload: payload,
      ),
    );
  }

  NotificationActionId _parseActionId(String? raw) {
    // Tap sur body (sans action explicite) → traité comme `done` (action
    // par défaut, cf. ADR-018 §4.1 — l'utilisateur ouvre la notif = valide).
    if (raw == null || raw.isEmpty) return NotificationActionId.done;
    return NotificationActionId.values.firstWhere(
      (a) => a.name == raw,
      orElse: () => NotificationActionId.done,
    );
  }

  String _actionLabel(NotificationActionId action) {
    switch (action) {
      case NotificationActionId.done:
        return 'Fait';
      case NotificationActionId.later:
        return 'Plus tard';
      case NotificationActionId.dismiss:
        return 'Ignorer';
    }
  }
}
