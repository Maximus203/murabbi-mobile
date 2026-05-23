# Q-22 — BUG-004 : Migration SQL colonne `users.timezone`

**Statut** : En attente de validation PO  
**Lié à** : BUG-004 (issue #184), ADR-018 §timezone  
**Branche** : `fix/alert-system-bug-002-003-004`

---

## Contexte

BUG-004 corrige la gestion du fuseau horaire côté mobile (Flutter) en utilisant
`TZHelper` (package `timezone`) pour toutes les comparaisons de dates. La classe
`Occurrence` expose désormais un champ `deviceTimezone` (IANA, ex. `"Africa/Dakar"`)
utilisé pour calculer la grace window en heure locale de l'utilisateur.

Le champ `deviceTimezone` côté Dart correspond à une colonne `device_timezone`
dans la table `occurrences` côté Supabase — **et** idéalement à une colonne
`timezone` dans la table `users` pour stocker le fuseau au moment de l'inscription.

---

## Migration SQL requise (hors scope mobile, à appliquer côté admin/Supabase)

```sql
-- Migration : ajouter le fuseau horaire de l'utilisateur
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS timezone text NOT NULL DEFAULT 'UTC';

-- Commentaire pour la lisibilité dans l'outil Supabase
COMMENT ON COLUMN users.timezone IS
  'Fuseau horaire IANA de l''utilisateur (ex. Africa/Dakar). '
  'Capturé au moment du signup via flutter_timezone. '
  'Utilisé pour calculer les grace windows des occurrences (BUG-004 / ADR-018).';

-- Index pour requêtes analytiques par timezone (facultatif mais recommandé)
CREATE INDEX IF NOT EXISTS idx_users_timezone ON users(timezone);

-- Migration : ajouter device_timezone sur occurrences (si pas encore présent)
ALTER TABLE occurrences
  ADD COLUMN IF NOT EXISTS device_timezone text;

COMMENT ON COLUMN occurrences.device_timezone IS
  'Fuseau horaire IANA du device au moment de l''action (BUG-004). '
  'Peut différer de users.timezone si l''utilisateur voyage.';
```

---

## Question pour le PO

1. **La table `users` possède-t-elle déjà une colonne `timezone` ou équivalent ?**  
   Si oui, quel est le nom exact ? (pour que le mobile lise/écrive la bonne colonne)

2. **La table `occurrences` possède-t-elle déjà `device_timezone` ?**  
   Si non, faut-il appliquer la migration ci-dessus dans `murabbi-admin/supabase/migrations/` ?

3. **Au signup**, faut-il envoyer le timezone capturé par `flutter_timezone` vers Supabase
   dès l'inscription, ou uniquement lors de la première validation d'occurrence ?  
   (décision produit — l'implémentation dans le signup flow est en attente de ta réponse)

---

## Non-bloquant pour la PR

La PR `fix/alert-system-bug-002-003-004` n'est pas bloquée par cette migration :  
- Le champ `deviceTimezone` dans `Occurrence` est nullable côté Dart (`String?`).  
- Le use case `ValidateOccurrenceUseCase` utilise `windowEndsAt` (calculé en UTC)
  comme source de vérité principale — le timezone est un enrichissement pour le log status.  
- La migration SQL est à appliquer côté admin avant Phase 3 complète (sign-up flow).

**Référence** : ADR-018 §10 (Q-OPEN-B / Q-OPEN-C), issue #184.
