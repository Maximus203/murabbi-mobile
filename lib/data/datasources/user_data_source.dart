/// Interface fine au-dessus de la table `users` (Q-18) pour les écritures
/// de profil hors auth (ST-02 — modification du pseudo).
///
/// Suit le pattern [AuthDataSource] : retourne des `Map<String, dynamic>`
/// bruts, aucune logique métier, aucune traduction d'erreur (déléguée au
/// repository).
abstract interface class UserDataSource {
  /// Met à jour le pseudo public de l'utilisateur et renvoie la row
  /// `users` rafraîchie.
  Future<Map<String, dynamic>> updatePseudo({
    required String userId,
    required String pseudo,
  });
}
