/// Constantes pour les médias vidéo de l'application.
///
/// Stratégie de livraison — ADR-017 :
/// - Vidéos onboarding : **bundlées** dans l'APK (`assets/videos/`).
///   Disponibles hors-ligne dès le premier lancement.
/// - Vidéos in-app : **Supabase Storage** (bucket [mediaBucket]).
///   Chargées après authentification via [VideoService].
abstract class AppMedia {
  // ── Vidéos bundlées (assets/videos/) — onboarding uniquement ──────────────

  /// OB-01 Splash — fond plein écran.
  static const String splashVideo = 'assets/videos/02_murabbi.mp4';

  /// OB-02 — fond plein écran (slide 1 de configuration).
  static const String onboarding02Video = 'assets/videos/06_murabbi.mp4';

  /// OB-03 — fond plein écran (slide 2 de configuration).
  static const String onboarding03Video = 'assets/videos/04_murabbi.mp4';

  /// OB-04 — fond plein écran (slide 3 de configuration).
  static const String onboarding04Video = 'assets/videos/03_murabbi.mp4';

  // ── Clés Supabase Storage — bucket [mediaBucket] ──────────────────────────

  /// HM-01 Niyyah card — asset bundlé (bandeau 120 px).
  static const String niyyahLocalVideo = 'assets/media/01.mp4';

  /// HM-01 Niyyah card — clé Supabase Storage (fallback réseau).
  static const String niyyahVideoKey = '01_murabbi.mp4';

  /// SA-03 SL-DETAIL — bandeau 200 px.
  static const String salatDetailVideoKey = '07_murabbi.mp4';

  /// LEVEL-UP — plein écran.
  static const String levelUpVideoKey = '08_murabbi.mp4';

  /// SA-01 header — bandeau 130 px.
  static const String salatHeaderVideoKey = '09_murabbi.mp4';

  /// CO-01 thumbnail (première collection).
  static const String collection10VideoKey = '10_murabbi.mp4';

  /// CO-01 thumbnail (deuxième collection).
  static const String collection11VideoKey = '11_murabbi.mp4';

  // ── Bucket Supabase ────────────────────────────────────────────────────────

  /// Nom du bucket Supabase Storage contenant les vidéos in-app.
  /// À créer manuellement dans la console Supabase (public en lecture).
  static const String mediaBucket = 'app-media';
}
