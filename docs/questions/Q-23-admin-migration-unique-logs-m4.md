# Q-23 — Migration admin requise : UNIQUE sur habit_logs et prayer_logs (M4)

**Status :** `closed` — prompt admin créé (2026-05-25) ; voir `docs/prompts/ADMIN-Q23-unique-logs.md`
**Lié à :** issue #198 (mob M4 — rate limiting), PR feat/errors-m4-rate-limit-serializer
**Repo concerné :** `murabbi-admin/supabase/migrations/` (PAS le mobile)

## Contexte

La PR mobile M4 ajoute :

- `ActionSerializer` côté Notifier (idempotence client) ;
- `HabitFailure.duplicate()` + mapping du code Postgres `23505` dans
  `SupabaseHabitDataSource` (idempotence backend, défense en profondeur).

Ces deux protections sont conçues pour fonctionner ensemble. La protection
backend n'a aucun effet tant que les contraintes UNIQUE n'existent pas
côté base — un double-tap qui arriverait à contourner le sérialiseur
(reload natif, multi-device, etc.) continuera à créer des doublons.

## Migration SQL requise (à exécuter côté admin)

```sql
-- supabase/migrations/YYYYMMDD_habit_prayer_logs_unique.sql

ALTER TABLE habit_logs
  ADD CONSTRAINT habit_logs_habit_id_logged_date_unique
  UNIQUE (habit_id, logged_date);

ALTER TABLE prayer_logs
  ADD CONSTRAINT prayer_logs_user_prayer_date_unique
  UNIQUE (user_id, prayer_name, prayer_date);
```

> **Important** — le nom de colonne exact (`logged_date` vs `date`) doit
> être confirmé sur le schéma admin avant `flyway/supabase db push`.
> Le datasource mobile utilise actuellement `date` côté `habit_logs`
> (`upsert(..., onConflict: 'habit_id,date')`). Si la contrainte UNIQUE
> backend doit cibler `logged_date`, l'on-conflict du datasource doit
> être aligné dans une PR mobile de suivi.

## Dépendances

- Préalable à **M2** (queue offline optimistic) — l'idempotence de la
  resynchronisation client dépend de ces contraintes.
- Une fois la migration appliquée, ouvrir une issue mobile de suivi pour :
  - tester end-to-end qu'un doublon remonte bien comme
    `HabitFailure.duplicate()` (et est traité comme no-op par l'UI) ;
  - aligner si nécessaire la clé `onConflict` côté datasource.

## Action attendue

PO ou ops admin :

1. Créer la migration SQL ci-dessus dans `murabbi-admin/supabase/migrations/`.
2. Vérifier les noms exacts des colonnes.
3. Appliquer sur les environnements `local`, `staging`, `prod`.
4. Notifier le mobile pour validation end-to-end.
