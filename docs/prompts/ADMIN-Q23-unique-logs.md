# Besoin admin — Q-23 : contraintes UNIQUE sur les logs + alignement schéma

**Priorité** : Haute — M4 côté mobile est complet, la protection backend est inactive
**Repo concerné** : `murabbi-admin/supabase/migrations/`
**Référence mobile** : Q-23, issue #198, PR feat/errors-m4-rate-limit-serializer

---

## Contexte

La PR mobile M4 a livré deux niveaux de protection contre les doubles validations :

1. **`ActionSerializer`** (côté client) — bloque les taps concurrents dans le Notifier.
2. **`HabitFailure.duplicate()`** + mapping du code Postgres `23505` (côté datasource)
   — gère proprement les erreurs d'unicité backend comme un no-op UI.

**La protection (2) n'a aucun effet tant que les contraintes UNIQUE n'existent
pas en base.** Un double-tap passant le sérialiseur (reload natif, multi-device,
perte réseau, etc.) créera des doublons sans erreur.

---

## Analyse du schéma actuel (source : `database_schema.md` v1.0.0)

### `habit_logs` est maintenant une VIEW (read-only)

> La table physique a été renommée `habit_logs_v1_legacy` (migration #130, ADR-016
> §3.5 D-5). `habit_logs` est une compat VIEW read-only sur `habit_occurrences`.

**Impact sur le mobile** : le datasource mobile (`SupabaseHabitDataSource`) appelle
encore `upsert` sur `habit_logs` avec `onConflict: 'habit_id,date'`. Cette
opération cible la VIEW, ce qui est probablement invalide (INSERT/UPSERT sur VIEW
read-only = erreur Supabase silencieuse ou exception).

**Questions urgentes pour l'admin :**

1. **L'upsert sur la VIEW `habit_logs` fonctionne-t-il actuellement ?**
   (Y a-t-il un INSTEAD OF trigger sur la VIEW pour rediriger les écritures ?)

2. **La colonne `onConflict` cible `habit_id,date` — est-ce correct ?**
   La VIEW expose `day` (alias de `validated_at::date`), pas une colonne `date`
   au sens strict. Le datasource doit-il passer à `habit_id,day` ?

3. **Les nouvelles écritures doivent-elles passer par `rpc_validate_occurrence` ?**
   (Le datasource mobile a déjà `toggleHabitLog` via RPC — faut-il migrer
   `upsertHabitLog` vers la même RPC ou une variante ?)

---

## Contraintes UNIQUE à créer (si la table physique reste accessible)

### Sur `habit_logs_v1_legacy` (déjà présente selon le schéma)

```sql
-- Contrainte existante sur habit_logs_v1_legacy :
-- habit_logs_user_habit_day_unique UNIQUE (user_id, habit_id, day)
-- → À CONFIRMER : cette contrainte est-elle active en prod ?
```

### Sur `habit_occurrences` (nouvelle table physique)

```sql
-- Vérifier si habit_occurrences_unique_slot couvre le cas des doubles logs :
-- UNIQUE (user_habit_id, scheduled_at) — déjà présente dans le schéma.
-- Si oui, M4 est déjà protégé côté backend via cette contrainte.
```

---

## Actions attendues

1. Confirmer si `upsert` sur la VIEW `habit_logs` est valide ou si le datasource
   doit switcher vers `rpc_validate_occurrence`.
2. Confirmer l'état des contraintes UNIQUE sur `habit_occurrences`.
3. Si une migration est nécessaire, la créer dans `murabbi-admin/supabase/migrations/`
   et notifier le mobile pour test end-to-end de `HabitFailure.duplicate()`.
4. Confirmer le nom exact de la colonne pour `onConflict` dans le datasource mobile
   (actuellement `'habit_id,date'` — à aligner avec `'habit_id,day'` si besoin).
