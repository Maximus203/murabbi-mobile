import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale (SharedPreferences) des emails déjà connectés sur cet
/// appareil — UX d'auto-suggestion sur l'écran de connexion.
///
/// **Pas de mot de passe**, pas de token : juste la liste des emails pour
/// remplir le champ d'un tap. Aucune fuite de données sensibles (l'utilisateur
/// doit toujours retaper son mot de passe).
///
/// La liste est plafonnée à [maxAccounts] entrées, ordonnée du plus récent
/// au plus ancien (LRU). Si l'utilisateur reconnecte un email déjà présent
/// dans la liste, il remonte en tête.
class RememberedAccountsStorage {
  /// Clé SharedPreferences — versionnée pour permettre une migration future.
  static const String storageKey = 'remembered_emails_v1';

  /// Nombre maximum d'emails mémorisés. Au-delà, les plus anciens sont
  /// évincés (LRU). Garde l'UI compact (5 chips max à l'écran).
  static const int maxAccounts = 5;

  final SharedPreferences _prefs;

  const RememberedAccountsStorage(this._prefs);

  /// Retourne la liste persistée (la plus récente en premier).
  List<String> getAll() {
    final raw = _prefs.getStringList(storageKey);
    if (raw == null) return const [];
    return List<String>.from(raw);
  }

  /// Ajoute (ou remonte) un email en tête. Trim à [maxAccounts].
  Future<void> remember(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;

    final current = List<String>.from(getAll())..remove(normalized);
    current.insert(0, normalized);
    final trimmed = current.take(maxAccounts).toList();
    await _prefs.setStringList(storageKey, trimmed);
  }

  /// Retire un email de la liste (ex: utilisateur veut nettoyer ce poste).
  Future<void> forget(String email) async {
    final normalized = email.trim().toLowerCase();
    final current = List<String>.from(getAll())..remove(normalized);
    await _prefs.setStringList(storageKey, current);
  }

  /// Vide complètement la liste (debug / "Effacer toutes les suggestions").
  Future<void> clear() async {
    await _prefs.remove(storageKey);
  }
}
