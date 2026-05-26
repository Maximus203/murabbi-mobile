import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';

/// Q-10 verrouillée — modération via banlist côté admin.
///
/// Le mobile expose un contrat abstrait que la couche data implémentera en
/// interrogeant un endpoint admin (Server Action ou RPC Supabase) qui consulte
/// la table `pseudo_blocklist` (regex FR + AR). L'unicité n'est PAS vérifiée
/// (collision tolérée — l'UI affiche `pseudo · #1234` si nécessaire).
abstract interface class PseudonymRepository {
  /// `true` si le pseudo n'est pas dans la banlist côté admin.
  Future<bool> isAllowed(Pseudonym pseudo);
}
