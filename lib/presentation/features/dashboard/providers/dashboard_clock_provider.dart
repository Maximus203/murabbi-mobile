import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source d'horloge UTC injectable pour le Dashboard — testabilité (figer
/// `DateTime.now()` dans les widget/unit tests).
///
/// Convention : la couche presentation Dashboard convertit elle-même en
/// local pour l'affichage (cf. `PrayerTimes` invariant UTC).
final dashboardClockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});
