/// École juridique pour le calcul de l'heure d'Asr (cf. ADR-013 §3).
///
/// Seule différence inter-madhab dans le calcul des horaires :
/// - [shafi] : Asr quand l'ombre = 1× la hauteur de l'objet (ratio 1).
/// - [hanafi] : Asr quand l'ombre = 2× la hauteur de l'objet (ratio 2).
///
/// Défaut V1 : [shafi] (majoritaire global). Pas de détection auto par pays
/// (cf. ADR-013 décision §3 — un musulman hanafi le sait, un toggle suffit).
enum Madhab {
  /// École Shafi (et Maliki / Hanbali pour le calcul d'Asr) — ratio 1.
  shafi,

  /// École Hanafi — ratio 2 (Asr plus tardive).
  hanafi,
}
