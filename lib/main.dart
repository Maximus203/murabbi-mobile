import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/firebase_options.dart';
import 'package:murabbi_mobile/presentation/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Entry point Murabbi mobile.
///
/// Initialise Firebase puis Supabase **avant** `runApp`, puis monte la racine
/// de l'app dans un `ProviderScope` Riverpod.
///
/// Configuration Supabase : passer `--dart-define=SUPABASE_URL=...` et
/// `--dart-define=SUPABASE_ANON_KEY=...` au démarrage. À défaut, l'app démarre
/// quand même (mode design / smoke run) — toute requête Supabase échouera
/// proprement à l'usage. Aucune clé n'est jamais commitée (S-1).
///
/// Firebase est initialisé inconditionnellement via [DefaultFirebaseOptions]
/// (cf. Q-20 / issue #174 — `lib/firebase_options.dart` contient uniquement
/// les app IDs publics, sans secret).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final config = SupabaseConfig.fromEnvironment();
  if (config.isConfigured) {
    await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  } else {
    debugPrint(
      '[Murabbi] SUPABASE_URL/ANON_KEY non fournis — démarrage en mode '
      'design (aucune requête Supabase ne fonctionnera). '
      'Cf. lib/data/datasources/supabase/supabase_client_provider.dart.',
    );
  }

  runApp(const ProviderScope(child: MurabbiApp()));
}
