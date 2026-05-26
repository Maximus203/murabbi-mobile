/// Petit contrat utilisé par les repositories pour récupérer l'`userId`
/// de la session courante côté Supabase, sans dépendre directement de
/// `supabase_flutter` (couche `data` → `domain` reste isolée).
///
/// Créé pour l'issue #202 (M3) — `OwnershipGuard.assertOwnership` a besoin
/// de comparer le `userId` demandé à celui de l'utilisateur authentifié
/// avant toute requête réseau.
abstract interface class CurrentUserIdResolver {
  /// Renvoie l'`id` Supabase de l'utilisateur authentifié, `null` si
  /// pas de session.
  Future<String?> currentUserId();
}
