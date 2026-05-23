import 'package:flutter/widgets.dart';

/// Type d'horloge injectable — permet aux tests de contrôler "maintenant"
/// sans dépendre de [DateTime.now] réel.
typedef Clock = DateTime Function();

/// Détecte un retour de l'app après une pause longue, et déclenche un
/// callback (typiquement : invalider les providers de données fraîches —
/// leaderboard, dashboard) — issue #197 (M5).
///
/// Implémenté hors `WidgetsBindingObserver` pour être testable sans
/// `WidgetsBinding` réel. La classe hôte (`MurabbiApp`) délègue ses
/// `didChangeAppLifecycleState` ici.
class AppResumeInvalidator {
  AppResumeInvalidator({
    required this.threshold,
    required this.onResumeAfterLongPause,
    Clock? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Durée minimale de pause au-delà de laquelle on invalide au resume.
  final Duration threshold;

  /// Callback exécuté lors d'un resume après une pause `> threshold`.
  final VoidCallback onResumeAfterLongPause;

  final Clock _clock;

  DateTime? _pausedAt;

  /// À appeler depuis le [WidgetsBindingObserver] hôte.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = _clock();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final paused = _pausedAt;
      // Reset systématique : pas de double-déclenchement sur 2 resume
      // consécutifs (cas Android où l'OS peut renvoyer resumed sans pause).
      _pausedAt = null;
      if (paused == null) return;
      if (_clock().difference(paused) > threshold) {
        onResumeAfterLongPause();
      }
    }
    // inactive / detached / hidden → no-op
  }
}
