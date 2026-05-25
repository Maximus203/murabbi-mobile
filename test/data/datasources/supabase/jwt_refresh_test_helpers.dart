// Helpers partagés pour les tests "ensureFreshSession is called first" sur
// les Supabase*DataSource (#190).
//
// Stratégie : on construit un vrai [SupabaseClientWrapper] avec des fakes
// d'I/O (token expiré, refresher qui throw). Si le datasource appelle bien
// `ensureFreshSession()` en première ligne, l'exception sentinelle remonte
// **avant** tout accès au client Supabase — donc le test prouve l'ordre
// sans avoir à mocker la fluent API Supabase (cf. convention repo : "fluent
// API Supabase trop fragile à mocker", voir commentaire des datasources).

import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';

/// Exception sentinelle levée par [SessionRefresher.refresh] dans les tests.
/// Volontairement non-`PostgrestException` pour ne pas être interceptée par
/// les traductions d'erreur des datasources (ex. `toggleHabitLog`).
class JwtRefreshSentinelException implements Exception {
  const JwtRefreshSentinelException();
  @override
  String toString() => 'JwtRefreshSentinelException';
}

class MockSessionTokenSource extends Mock implements SessionTokenSource {}

class MockSessionRefresher extends Mock implements SessionRefresher {}

class MockSignedOutSink extends Mock implements SignedOutSink {}

/// Bundle de mocks + wrapper prêt à l'emploi.
class JwtRefreshHarness {
  final MockSessionTokenSource tokens;
  final MockSessionRefresher refresher;
  final MockSignedOutSink signOutSink;
  final SupabaseClientWrapper wrapper;

  JwtRefreshHarness._(
    this.tokens,
    this.refresher,
    this.signOutSink,
    this.wrapper,
  );

  /// Construit un harness où :
  /// - le token est toujours expiré (force le refresh),
  /// - `refresh()` lève [JwtRefreshSentinelException],
  /// - `signOut()` est observable mais ne fait rien.
  ///
  /// Toute méthode de datasource qui appelle `wrapper.ensureFreshSession()`
  /// en première ligne lèvera donc la sentinelle avant toute requête réelle.
  factory JwtRefreshHarness.refreshThrows() {
    final tokens = MockSessionTokenSource();
    final refresher = MockSessionRefresher();
    final signOut = MockSignedOutSink();
    final now = DateTime.utc(2026, 5, 23, 12);

    when(
      () => tokens.expiresAt,
    ).thenReturn(now.subtract(const Duration(minutes: 1)));
    when(
      () => refresher.refresh(),
    ).thenThrow(const JwtRefreshSentinelException());
    when(() => signOut.signOut()).thenAnswer((_) async {});

    final wrapper = SupabaseClientWrapper(
      tokens: tokens,
      refresher: refresher,
      signOutSink: signOut,
      now: () => now,
    );
    return JwtRefreshHarness._(tokens, refresher, signOut, wrapper);
  }
}
