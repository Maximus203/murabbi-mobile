import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';

/// Tests du SupabaseClientWrapper (BUG-001 — JWT auto-refresh).
///
/// Le wrapper est volontairement indépendant de `supabase_flutter` pour rester
/// 100% testable sans démarrer un client réel : il prend une `SessionTokenSource`
/// (lecture de l'expiration courante) et une `SessionRefresher` (action de
/// refresh) — deux abstractions étroites mockées ci-dessous.
class _MockTokenSource extends Mock implements SessionTokenSource {}

class _MockRefresher extends Mock implements SessionRefresher {}

class _MockSignOutSink extends Mock implements SignedOutSink {}

void main() {
  late _MockTokenSource tokens;
  late _MockRefresher refresher;
  late _MockSignOutSink signOut;
  late SupabaseClientWrapper wrapper;

  // Heure de référence : 2026-05-23 12:00:00 UTC
  final now = DateTime.utc(2026, 5, 23, 12);

  setUp(() {
    tokens = _MockTokenSource();
    refresher = _MockRefresher();
    signOut = _MockSignOutSink();
    wrapper = SupabaseClientWrapper(
      tokens: tokens,
      refresher: refresher,
      signOutSink: signOut,
      now: () => now,
      // Buffer de 5 minutes — cf. spec issue #181.
      refreshBuffer: const Duration(minutes: 5),
    );
  });

  group('expiry check', () {
    test('token_expiry_check_uses_5min_buffer — frontière exacte', () {
      // exp == now + 5min → considéré comme "à rafraîchir" (limite incluse).
      final exp = now.add(const Duration(minutes: 5));
      expect(wrapper.isExpiringSoon(exp), isTrue);

      // exp == now + 5min + 1s → encore frais.
      final fresh = now.add(const Duration(minutes: 5, seconds: 1));
      expect(wrapper.isExpiringSoon(fresh), isFalse);
    });

    test('isExpiringSoon retourne true si déjà expiré', () {
      expect(
        wrapper.isExpiringSoon(now.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('isExpiringSoon retourne false si session absente', () {
      expect(wrapper.isExpiringSoon(null), isFalse);
    });
  });

  group('ensureFreshSession', () {
    test('wrapper_refreshes_token_when_expiring_in_5min', () async {
      when(
        () => tokens.expiresAt,
      ).thenReturn(now.add(const Duration(minutes: 4)));
      when(() => refresher.refresh()).thenAnswer((_) async {});

      await wrapper.ensureFreshSession();

      verify(() => refresher.refresh()).called(1);
      verifyNever(() => signOut.signOut());
    });

    test('wrapper_does_not_refresh_if_token_fresh', () async {
      when(
        () => tokens.expiresAt,
      ).thenReturn(now.add(const Duration(hours: 1)));

      await wrapper.ensureFreshSession();

      verifyNever(() => refresher.refresh());
      verifyNever(() => signOut.signOut());
    });

    test('no-op si aucune session active (utilisateur non connecté)', () async {
      when(() => tokens.expiresAt).thenReturn(null);

      await wrapper.ensureFreshSession();

      verifyNever(() => refresher.refresh());
    });

    test(
      'wrapper_emits_signed_out_on_refresh_failure — AuthException → SignedOut',
      () async {
        when(
          () => tokens.expiresAt,
        ).thenReturn(now.add(const Duration(minutes: 1)));
        when(() => refresher.refresh()).thenThrow(
          const AuthFailure.invalidCredentials(
            message: 'refresh_token expired',
          ),
        );
        when(() => signOut.signOut()).thenAnswer((_) async {});

        await expectLater(
          wrapper.ensureFreshSession(),
          throwsA(isA<AuthFailure>()),
        );

        verify(() => signOut.signOut()).called(1);
      },
    );

    test('wrapper_throws_network_exception_offline — pas de signOut', () async {
      when(
        () => tokens.expiresAt,
      ).thenReturn(now.add(const Duration(minutes: 1)));
      when(
        () => refresher.refresh(),
      ).thenThrow(const SocketException('offline'));
      when(() => signOut.signOut()).thenAnswer((_) async {});

      await expectLater(
        wrapper.ensureFreshSession(),
        throwsA(isA<NetworkFailure>()),
      );

      // Offline : on garde la session, l'offline queue ré-essaiera plus tard.
      verifyNever(() => signOut.signOut());
    });

    test('concurrent_refresh_only_calls_refresh_once', () async {
      when(
        () => tokens.expiresAt,
      ).thenReturn(now.add(const Duration(minutes: 1)));

      final gate = Completer<void>();
      when(() => refresher.refresh()).thenAnswer((_) => gate.future);

      // Trois appels concurrents avant la résolution du refresh.
      final f1 = wrapper.ensureFreshSession();
      final f2 = wrapper.ensureFreshSession();
      final f3 = wrapper.ensureFreshSession();

      gate.complete();
      await Future.wait([f1, f2, f3]);

      verify(() => refresher.refresh()).called(1);
    });

    test(
      'après refresh réussi, un nouvel appel relit l\'expiration fraîche',
      () async {
        // 1er appel : token expirant → refresh.
        when(
          () => tokens.expiresAt,
        ).thenReturn(now.add(const Duration(minutes: 1)));
        when(() => refresher.refresh()).thenAnswer((_) async {
          // Simule la maj de session après refresh — exp repoussé à +1h.
          when(
            () => tokens.expiresAt,
          ).thenReturn(now.add(const Duration(hours: 1)));
        });

        await wrapper.ensureFreshSession();
        // 2e appel : token frais → pas de second refresh.
        await wrapper.ensureFreshSession();

        verify(() => refresher.refresh()).called(1);
      },
    );
  });
}
