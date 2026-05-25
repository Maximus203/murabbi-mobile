# Besoin admin — Q-22 : colonnes timezone sur `users` et `occurrences`

**Priorité** : Moyenne — requise avant Phase 3 complète (signup flow avec timezone)
**Repo concerné** : `murabbi-admin/supabase/migrations/`
**Référence mobile** : Q-22, BUG-004, ADR-018 §timezone, issue #184

---

## Contexte

BUG-004 (côté mobile) corrige la gestion des fuseaux horaires : la classe
`Occurrence` expose un champ `deviceTimezone` (IANA, ex. `"Africa/Dakar"`)
utilisé pour calculer les grace windows en heure locale.

**Côté Dart** : le fix est livré et testé.
**Côté Supabase** : deux colonnes sont nécessaires pour persister cette information.

---

## Questions à répondre avant migration

1. **La table `users` possède-t-elle déjà une colonne `timezone` ou équivalent ?**
   Si oui, quel est le nom exact — pour que le mobile lise/écrive la bonne colonne.

2. **La table `occurrences` (ou `habit_occurrences`) possède-t-elle déjà `device_timezone` ?**
   Si non, la migration ci-dessous est à appliquer.

3. **Au signup**, faut-il envoyer le timezone capturé par `flutter_timezone` vers
   Supabase dès l'inscription, ou uniquement lors de la première validation
   d'occurrence ? *(décision produit — l'implémentation du signup flow attend
   cette réponse)*

---

## Migration SQL à appliquer (si colonnes absentes)

```sql
-- murabbi-admin/supabase/migrations/YYYYMMDD_users_add_timezone.sql

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS timezone text NOT NULL DEFAULT 'UTC';

COMMENT ON COLUMN users.timezone IS
  'Fuseau horaire IANA de l''utilisateur (ex. Africa/Dakar). '
  'Capturé au moment du signup via flutter_timezone. '
  'Utilisé pour calculer les grace windows des occurrences (BUG-004 / ADR-018).';

CREATE INDEX IF NOT EXISTS idx_users_timezone ON users(timezone);

-- Sur habit_occurrences (si device_timezone absent)
ALTER TABLE habit_occurrences
  ADD COLUMN IF NOT EXISTS device_timezone text;

COMMENT ON COLUMN habit_occurrences.device_timezone IS
  'Fuseau horaire IANA du device au moment de l''action (BUG-004). '
  'Peut différer de users.timezone si l''utilisateur voyage.';
```

---

## Ce que le mobile attend

- Confirmation des noms exacts des colonnes (pour aligner les mappers Dart).
- Notification quand la migration est déployée sur `staging`.
- Réponse à la question n°3 (timing du signup flow).
