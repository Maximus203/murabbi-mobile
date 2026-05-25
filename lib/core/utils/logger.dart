import 'package:logger/logger.dart';

/// Singleton logger — utiliser dans tous les fichiers du projet.
///
/// Remplace `dart:developer` (règle §6 CLAUDE.md).
/// Niveaux disponibles : `.d()` debug · `.i()` info · `.w()` warning · `.e()` error.
final appLog = Logger(
  printer: PrettyPrinter(methodCount: 2, errorMethodCount: 8),
);
