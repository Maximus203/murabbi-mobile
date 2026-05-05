import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration Supabase injectée au démarrage (`main.dart`).
///
/// Les valeurs sont lues via `--dart-define` (cf. CLAUDE.md mobile §11) :
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
///
/// Aucune valeur n'est commitée — `String.fromEnvironment` retourne une
/// chaîne vide à défaut, ce qui fait échouer `Supabase.initialize` côté
/// `main()` avec un message clair.
class SupabaseConfig {
  final String url;
  final String anonKey;

  const SupabaseConfig({required this.url, required this.anonKey});

  factory SupabaseConfig.fromEnvironment() {
    return const SupabaseConfig(
      url: String.fromEnvironment('SUPABASE_URL'),
      anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

/// Provider du client Supabase courant.
///
/// La couche `presentation/` ne doit JAMAIS importer `supabase_flutter`
/// directement (CLAUDE.md mobile § 4 — interdiction). L'unique point d'entrée
/// pour les datasources est ce provider.
///
/// L'initialisation effective (`Supabase.initialize`) est faite dans
/// `main.dart` AVANT `runApp`. Le provider expose simplement `Supabase.instance.client`.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
