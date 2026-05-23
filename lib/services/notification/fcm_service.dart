import 'package:logger/logger.dart';

/// DTO représentant un message FCM reçu.
///
/// Isole le type natif `firebase_messaging.RemoteMessage` de la couche
/// service — permet les tests sans plugin natif Firebase.
class FcmMessage {
  /// Identifiant unique du message FCM.
  final String? messageId;

  /// Données arbitraires du payload FCM (champ `data`).
  final Map<String, dynamic> data;

  const FcmMessage({this.messageId, this.data = const {}});
}

/// Abstraction sur Firebase Messaging — isole le plugin natif des tests
/// et des autres couches.
///
/// Seule l'implémentation production (`FcmMessagingAdapterImpl`) importe
/// `firebase_messaging`. Les tests utilisent un mock.
abstract class FirebaseMessagingAdapter {
  /// Demande la permission de notification à l'OS.
  Future<void> requestPermission();

  /// Retourne le token FCM courant du device.
  Future<String?> getToken();

  /// Stream des nouveaux tokens FCM (rafraîchissement automatique).
  Stream<String> get onTokenRefresh;

  /// Stream des messages reçus en foreground.
  Stream<FcmMessage> get onMessage;
}

/// Abstraction sur le stockage sécurisé du token FCM.
///
/// Implémentation production : `flutter_secure_storage`.
abstract class SecureTokenStorage {
  /// Écrit le token FCM dans le stockage sécurisé.
  Future<void> writeToken(String token);

  /// Lit le token FCM depuis le stockage sécurisé.
  Future<String?> readToken();
}

/// Abstraction sur la persistance du token FCM côté backend.
abstract class FcmTokenRepository {
  /// Persiste le token FCM de l'utilisateur dans Supabase.
  Future<void> updateFcmToken({
    required String userId,
    required String token,
  });
}

/// Service d'intégration FCM pour les notifications admin broadcast.
///
/// **Périmètre (ADR-018 §5)** : uniquement les messages admin → utilisateurs
/// (global_broadcast, streak_alert, weekly_report). Les alertes habitude et
/// prière sont 100% on-device (flutter_local_notifications — MOB-002).
///
/// **Flux de tokens** :
/// 1. `initialize()` demande la permission + récupère le token initial.
/// 2. Le token est stocké dans `flutter_secure_storage` (jamais SharedPrefs).
/// 3. Si `userId` fourni, le token est aussi pushé en Supabase.
/// 4. `onTokenRefresh` est écouté pour détecter les rotations de token.
///
/// **Types de notification routés** :
/// - `global_broadcast` → notif locale via `flutter_local_notifications`.
/// - `streak_alert` → notif locale.
/// - `weekly_report` → notif locale.
/// - Inconnu → log warning, ignoré.
class FcmService {
  final FirebaseMessagingAdapter _messaging;
  final SecureTokenStorage _storage;
  final FcmTokenRepository _tokenRepository;
  final Logger _logger;

  static const _knownTypes = {
    'global_broadcast',
    'streak_alert',
    'weekly_report',
  };

  FcmService({
    required FirebaseMessagingAdapter messaging,
    required SecureTokenStorage storage,
    required FcmTokenRepository tokenRepository,
    Logger? logger,
  })  : _messaging = messaging,
        _storage = storage,
        _tokenRepository = tokenRepository,
        _logger = logger ?? Logger();

  /// Initialise FCM : demande permission, stocke le token initial.
  ///
  /// Si [userId] est fourni, le token est aussi synchronisé en Supabase.
  /// L'écoute de [onTokenRefresh] est démarrée si [userId] est fourni.
  Future<void> initialize({String? userId}) async {
    await _messaging.requestPermission();
    _logger.d('FcmService: permission requested');

    final token = await _messaging.getToken();
    if (token != null) {
      await _storage.writeToken(token);
      _logger.i('FcmService: initial token stored');
      if (userId != null) {
        await _tokenRepository.updateFcmToken(userId: userId, token: token);
      }
    }

    // Écoute des rotations de token.
    if (userId != null) {
      _messaging.onTokenRefresh.listen((newToken) async {
        _logger.i('FcmService: token refreshed');
        await _storage.writeToken(newToken);
        await _tokenRepository.updateFcmToken(userId: userId, token: newToken);
      });
    }
  }

  /// Retourne le token FCM courant.
  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  /// Synchronise le token FCM en Supabase et dans le stockage local.
  Future<void> syncTokenToSupabase(String userId, String token) async {
    await _storage.writeToken(token);
    await _tokenRepository.updateFcmToken(userId: userId, token: token);
    _logger.d('FcmService: token synced for user $userId');
  }

  /// Stream des messages FCM reçus en foreground.
  Stream<FcmMessage> get foregroundMessages => _messaging.onMessage;

  /// Traite un message FCM reçu en foreground.
  ///
  /// Route selon le type (champ `data.type`) vers la notif locale appropriée.
  /// Les types inconnus sont ignorés avec un log warning.
  Future<void> handleForegroundMessage(FcmMessage message) async {
    final type = message.data['type'] as String?;

    if (type == null || !_knownTypes.contains(type)) {
      _logger.w(
        'FcmService: unknown notification type "$type" — ignoring '
        '(messageId=${message.messageId})',
      );
      return;
    }

    _logger.i(
      'FcmService: routing foreground message type="$type" '
      '(messageId=${message.messageId})',
    );

    // En V1, on log l'intention — la connexion à flutter_local_notifications
    // sera faite dans MOB-006 natif (nécessite firebase_options.dart +
    // google-services.json fournis par le PO).
    // Cf. docs/questions/Q-21-fcm-credentials.md.
  }

  /// Handler de messages FCM en background/terminated.
  ///
  /// **Top-level function requise par Firebase Messaging.**
  /// L'annotation `@pragma('vm:entry-point')` empêche le tree-shaker de
  /// supprimer cette fonction dans les builds release.
  ///
  /// S'exécute dans un isolat séparé — pas d'accès aux providers Riverpod.
  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(FcmMessage message) async {
    // Logger minimal (pas d'accès au container DI de l'app principale).
    final logger = Logger();
    logger.i(
      'FcmService[background]: received message '
      '(messageId=${message.messageId})',
    );
    // En V1 : stub. La logique complète sera ajoutée lors de l'intégration
    // native avec firebase_options.dart disponible.
  }
}
