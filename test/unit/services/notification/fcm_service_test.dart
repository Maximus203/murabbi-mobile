// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/services/notification/fcm_service.dart';

/// Mocks des interfaces définies dans fcm_service.dart.
class _MockFirebaseMessagingAdapter extends Mock
    implements FirebaseMessagingAdapter {}

class _MockSecureTokenStorage extends Mock implements SecureTokenStorage {}

class _MockFcmTokenRepository extends Mock implements FcmTokenRepository {}

void main() {
  late _MockFirebaseMessagingAdapter messaging;
  late _MockSecureTokenStorage storage;
  late _MockFcmTokenRepository tokenRepo;
  late FcmService sut;

  const userId = 'user-001';
  const fakeToken = 'fcm-token-abc123';

  setUp(() {
    messaging = _MockFirebaseMessagingAdapter();
    storage = _MockSecureTokenStorage();
    tokenRepo = _MockFcmTokenRepository();

    when(() => messaging.requestPermission()).thenAnswer((_) async {});
    when(() => messaging.getToken()).thenAnswer((_) async => fakeToken);
    when(
      () => messaging.onTokenRefresh,
    ).thenAnswer((_) => const Stream<String>.empty());
    when(
      () => messaging.onMessage,
    ).thenAnswer((_) => const Stream<FcmMessage>.empty());
    when(() => storage.writeToken(any())).thenAnswer((_) async {});
    when(() => storage.readToken()).thenAnswer((_) async => fakeToken);
    when(
      () => tokenRepo.updateFcmToken(
        userId: any(named: 'userId'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});

    sut = FcmService(
      messaging: messaging,
      storage: storage,
      tokenRepository: tokenRepo,
    );
  });

  // ------------------------------------------------------------------
  // Test 1 — initialize demande la permission
  // ------------------------------------------------------------------
  test('initialize_requests_notification_permission', () async {
    await sut.initialize();

    verify(() => messaging.requestPermission()).called(1);
  });

  // ------------------------------------------------------------------
  // Test 2 — getToken retourne un string non-null
  // ------------------------------------------------------------------
  test('get_token_returns_string', () async {
    final token = await sut.getToken();

    expect(token, isNotNull);
    expect(token, fakeToken);
  });

  // ------------------------------------------------------------------
  // Test 3 — syncTokenToSupabase appelle repository.updateFcmToken
  // ------------------------------------------------------------------
  test('sync_token_calls_supabase_update', () async {
    await sut.syncTokenToSupabase(userId, fakeToken);

    verify(
      () => tokenRepo.updateFcmToken(userId: userId, token: fakeToken),
    ).called(1);
  });

  // ------------------------------------------------------------------
  // Test 4 — foregroundMessages stream émet les messages reçus
  // ------------------------------------------------------------------
  test('foreground_message_emitted_on_receive', () async {
    const msg = FcmMessage(
      messageId: 'msg-001',
      data: {'type': 'global_broadcast', 'title': 'Test'},
    );
    when(() => messaging.onMessage).thenAnswer((_) => Stream.value(msg));

    final received = await sut.foregroundMessages.first;

    expect(received.messageId, 'msg-001');
  });

  // ------------------------------------------------------------------
  // Test 5 — background handler log le message (vérifié via interface)
  // ------------------------------------------------------------------
  test('background_handler_logs_message', () async {
    // Le background handler est une top-level function — on vérifie
    // qu'elle s'exécute sans lever d'exception avec un message valide.
    const msg = FcmMessage(messageId: 'bg-msg-001', data: {});

    // Doit compléter sans exception.
    await expectLater(
      Future(() => FcmService.handleBackgroundMessage(msg)),
      completes,
    );
  });

  // ------------------------------------------------------------------
  // Test 6 — token refresh → syncTokenToSupabase appelé
  // ------------------------------------------------------------------
  test('token_refresh_triggers_sync', () async {
    when(
      () => messaging.onTokenRefresh,
    ).thenAnswer((_) => Stream.value('new-fcm-token'));

    await sut.initialize(userId: userId);

    // Attend la propagation du stream.
    await Future<void>.delayed(Duration.zero);

    verify(
      () => tokenRepo.updateFcmToken(userId: userId, token: 'new-fcm-token'),
    ).called(1);
  });

  // ------------------------------------------------------------------
  // Test 7 — type inconnu → log warning, pas de crash
  // ------------------------------------------------------------------
  test('unknown_notification_type_logged_and_ignored', () async {
    const msg = FcmMessage(
      messageId: 'msg-unknown',
      data: {'type': 'totally_unknown_type'},
    );

    // Doit compléter sans exception.
    await expectLater(
      Future(() => sut.handleForegroundMessage(msg)),
      completes,
    );
  });

  // ------------------------------------------------------------------
  // Test 8 — token stocké dans flutter_secure_storage
  // ------------------------------------------------------------------
  test('fcm_token_stored_in_secure_storage', () async {
    await sut.syncTokenToSupabase(userId, fakeToken);

    verify(() => storage.writeToken(fakeToken)).called(1);
  });
}
