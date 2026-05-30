# Q-25 — RPC `get_user_score` manquante + colonne `previous_week_rank` absente

**Date** : 2026-05-26
**Branch** : `feat/dashboard-rank-movement`
**Statut** : 🟡 EN ATTENTE réponse PO

---

## Contexte

Dans le cadre de la feature Q-F (affichage du mouvement de rang sur le dashboard),
j'ai vérifié l'état de la base Supabase `murabbi-prod` pour valider la faisabilité
end-to-end.

### Ce que le code mobile attend

`SupabaseScoreDataSource.getUserScore()` appelle :

```dart
_client.rpc('get_user_score', params: {'p_user_id': userId}).single()
```

Le mapper `UserScoreMapper.fromRow()` attend une row plate avec :
- `user_id` / `id` — identifiant utilisateur
- `total_points` — points cumulés (depuis `user_scores`)
- `weekly_score` — points de la semaine (depuis `weekly_leaderboard`)
- `rank` — rang hebdomadaire (depuis `weekly_leaderboard`)
- `previous_week_rank` — rang de la semaine précédente (depuis `user_scores`)
- `pseudo` — pseudo affiché (depuis `users`)

### Ce qui existe en prod (audit 2026-05-26)

| Objet Supabase | Statut |
|---|---|
| Fonction RPC `get_user_score(p_user_id)` | ❌ **n'existe pas** |
| Table `user_scores`.`previous_week_rank` | ❌ **colonne absente** |
| Table `user_scores` (autres colonnes) | ✅ existe — `id, user_id, total_points, weekly_points, current_level, weekly_rank, updated_at` |
| Table `users`.`pseudo` | ✅ confirmé via `profileColumns` |
| Vue `weekly_leaderboard` | ❓ non vérifiée (requête SQL incomplète) |

### Impact actuel

Chaque appel à `userScoreProvider` lève une `PostgrestException`
(function `get_user_score` does not exist).
Le catch dans `DashboardNotifier._loadScore()` absorbe silencieusement l'erreur →
la carte de score du dashboard affiche les valeurs par défaut (0 pts, niveau Aspirant,
aucun badge de mouvement de rang). L'utilisateur ne voit aucune erreur, mais
**les données de score sont complètement vides**.

---

## Options envisagées

### Option A — Patch rapide : bypass RPC, requête directe

Réécrire `SupabaseScoreDataSource.getUserScore()` pour interroger `user_scores`
directement (+ JOIN `users` pour `pseudo`), sans créer de RPC.

- ✅ Aucune migration Supabase requise
- ✅ Débloque l'affichage du score (total_points, niveau, rang hebdomadaire)
- ❌ `previous_week_rank` reste null → pas de mouvement de rang affiché
- ❌ Dévie de l'architecture prévue (ADR RPC atomique #199)
- ❌ `weekly_leaderboard` vue peut-être absente → `getLeaderboard()` aussi cassé

### Option B — Migration complète

Dans `murabbi-admin` :
1. `ALTER TABLE user_scores ADD COLUMN previous_week_rank INT NULL`
2. Créer la fonction RPC `get_user_score(p_user_id UUID)` qui joint
   `users` + `user_scores` + `weekly_leaderboard`
3. Vérifier / créer la vue `weekly_leaderboard` si absente

Puis déployer en prod.

- ✅ Architecture respectée (ADR #199)
- ✅ `previous_week_rank` disponible dès que le job de reset hebdomadaire est actif
- ✅ Unbloque aussi `getLeaderboard()`
- ❌ Nécessite une migration murabbi-admin + déploiement prod avant de tester

### Option C — Migration minimale (ma recommandation)

Dans `murabbi-admin` :
1. Créer la RPC `get_user_score(p_user_id UUID)` retournant les colonnes attendues,
   **avec `previous_week_rank` hardcodé à NULL pour l'instant** :
   ```sql
   CREATE OR REPLACE FUNCTION get_user_score(p_user_id UUID)
   RETURNS TABLE(user_id UUID, total_points INT, weekly_score INT,
                 rank INT, previous_week_rank INT, pseudo TEXT)
   ...
   -- previous_week_rank: NULL::INT (à alimenter quand job reset hebdo implémenté)
   ```
2. Vérifier / créer `weekly_leaderboard` si absente.
3. **Ne pas ajouter `previous_week_rank`** à `user_scores` maintenant — reporter
   à la PR qui implémente le job de reset hebdomadaire (qui calculera et stockera
   ce rang).

- ✅ Architecture respectée (un seul RPC)
- ✅ Unbloque l'affichage du score immédiatement
- ✅ `rankMovement` = null → la flèche de rang ne s'affiche pas (comportement correct
  quand l'historique n'est pas encore disponible)
- ✅ Zéro schema drift : `previous_week_rank` ne sera ajouté que quand il peut être
  alimenté automatiquement
- ❌ Nécessite quand même une migration (petite) + déploiement prod

---

## Ma recommandation

**Option C** — migration minimale, respecte l'architecture, débloque la feature.

La migration SQL serait :

```sql
-- Dans murabbi-admin/supabase/migrations/20260527_get_user_score_rpc.sql

-- Vue weekly_leaderboard (si absente)
CREATE OR REPLACE VIEW weekly_leaderboard AS
SELECT
  us.user_id,
  us.weekly_points AS weekly_score,
  RANK() OVER (ORDER BY us.weekly_points DESC)::INT AS rank
FROM user_scores us;

-- Fonction RPC atomique
CREATE OR REPLACE FUNCTION get_user_score(p_user_id UUID)
RETURNS TABLE(
  user_id   UUID,
  total_points  INT,
  weekly_score  INT,
  rank          INT,
  previous_week_rank INT,
  pseudo        TEXT
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    us.user_id,
    us.total_points,
    wl.weekly_score,
    wl.rank::INT,
    NULL::INT AS previous_week_rank,   -- alimenté quand job reset hebdo actif
    u.pseudo
  FROM user_scores us
  JOIN users u ON u.id = us.user_id
  LEFT JOIN weekly_leaderboard wl ON wl.user_id = us.user_id
  WHERE us.user_id = p_user_id;
$$;
```

---

## Question

**Dois-je créer cette migration dans `murabbi-admin` et la déployer en prod,
ou préfères-tu une autre approche ?**

Bloquant : **OUI** — sans cette migration, le score dashboard est vide pour tous
les utilisateurs connectés.

---

*Ouvert par : Claude Agent (feat/dashboard-rank-movement)*
*À valider par : Cherif DIOUF*
