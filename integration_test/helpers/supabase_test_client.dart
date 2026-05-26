// Helper pour les integration tests nécessitant un projet Supabase de test.
//
// Les tests qui appellent directement Supabase (datasources, repositories)
// doivent utiliser [skipIfNoTestSupabase] en tête de test. Si les variables
// d'env ne sont pas fournies, le test est marqué skippé proprement plutôt
// qu'échoué — la CI ne pénalise pas l'absence d'un projet staging.
//
// Usage :
//   test('mon test Supabase', () async {
//     skipIfNoTestSupabase();
//     final client = buildTestSupabaseClient();
//     // ...
//   });
//
// En CI avec projet staging configuré :
//   flutter test integration_test/... \
//     --dart-define=SUPABASE_URL_TEST=https://xxx.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY_TEST=eyJxxx...
//
// Sans les variables → test skippé, pas d'erreur.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kTestUrl = String.fromEnvironment('SUPABASE_URL_TEST');
const _kTestAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY_TEST');

/// `true` si les deux variables `--dart-define` de test sont fournies.
bool get isSupabaseTestConfigured =>
    _kTestUrl.isNotEmpty && _kTestAnonKey.isNotEmpty;

/// À appeler en tête de tout test qui a besoin d'un vrai projet Supabase.
/// Marque le test comme skippé si la configuration est absente.
void skipIfNoTestSupabase() {
  if (!isSupabaseTestConfigured) {
    markTestSkipped(
      'Supabase test project not configured — '
      'pass --dart-define=SUPABASE_URL_TEST and --dart-define=SUPABASE_ANON_KEY_TEST to run.',
    );
  }
}

/// Construit un [SupabaseClient] pointant vers le projet de test.
/// Doit être appelé APRÈS [skipIfNoTestSupabase] (garantit que les variables
/// sont définies).
SupabaseClient buildTestSupabaseClient() {
  assert(
    isSupabaseTestConfigured,
    'buildTestSupabaseClient() appelé sans projet de test configuré. '
    'Appelle skipIfNoTestSupabase() en tête de test.',
  );
  return SupabaseClient(_kTestUrl, _kTestAnonKey);
}
