**BESOIN ADMIN — Classement hebdomadaire / Écran LB-01**

**Contexte**

L'écran Classement (LB-01) est implémenté côté mobile (Phase 5). Il affiche
un podium top-3 + liste des autres rangs. En prod, l'écran retourne
systématiquement l'état d'erreur générique car la requête Supabase échoue.
Ce document décrit ce que la feature mobile attend du backend.

---

**Ce que la feature mobile fait du côté du backend**

**1. Chargement du classement global (50 entrées)**

Le datasource mobile effectue la requête suivante sur la vue `weekly_leaderboard` :

```sql
SELECT user_id, weekly_score, rank
FROM public.weekly_leaderboard
ORDER BY rank ASC
LIMIT 50 OFFSET 0
```

Il attend en retour une liste de lignes avec exactement ces colonnes :

| Colonne        | Type    | Description                              |
|----------------|---------|------------------------------------------|
| `user_id`      | `uuid`  | Référence `public.users.id`              |
| `weekly_score` | `int`   | Score accumulé sur la semaine courante   |
| `rank`         | `int`   | Rang calculé (1 = meilleur score)        |

Si la vue est absente ou si les colonnes diffèrent, le `PostgrestException`
remonte jusqu'à l'écran et affiche "Une erreur est survenue."

**2. Chargement du score personnel (utilisé sur d'autres écrans)**

Le datasource fait également une requête sur la même vue pour récupérer
le rang de l'utilisateur connecté :

```sql
SELECT user_id, weekly_score, rank
FROM public.weekly_leaderboard
WHERE user_id = '<current_user_id>'
LIMIT 1
```

Combinée avec :

```sql
SELECT id, total_points
FROM public.users
WHERE id = '<current_user_id>'
```

Le mobile assemble les deux résultats pour construire l'entité `UserScore`
(total_points + weekly_score + rank + niveau dérivé des points).

---

**Entités domain concernées**

- `UserScore` : lecture — champs concernés : `weeklyPoints`, `weeklyRank`, `totalPoints`
- `ScoreRepository` / `SupabaseScoreDataSource` : lecture seule sur `weekly_leaderboard`
- Aucune écriture depuis le mobile sur cette vue

---

**Ce que je te demande**

Sans présupposer de ce qui est ou n'est pas déjà en place dans `murabbi-admin`,
je te demande d'analyser :

- La vue `public.weekly_leaderboard` existe-t-elle ? Si oui, dispose-t-elle
  bien des colonnes `user_id`, `weekly_score`, `rank` avec les types attendus ?
- Si la vue n'existe pas, quelle est la source de données qui alimente le
  classement hebdomadaire côté admin (table, vue matérialisée, calcul à la
  demande) ? Faut-il créer une vue ou une RPC ?
- Les RLS policies de la vue (ou table source) permettent-elles à un utilisateur
  authentifié de lire toutes les lignes (classement public) ?
- Qu'est-ce que le mobile doit attendre exactement si aucun utilisateur n'a
  encore de score cette semaine — liste vide `[]` ou erreur ?

Tu as la vision complète du schéma backend. Je te fais confiance pour analyser
et prendre les mesures adaptées.
