# Décisions Produit V1 — Murabbi

> **Source de vérité partagée mobile + admin.**
> Toute modification doit passer par une PR sur `murabbi-admin` avec validation Cherif.
> Repo de référence : `murabbi-admin` (privé) — les agents mobile lisent ce fichier en read-only.
>
> Dernière mise à jour : 2026-04-28

---

## Statut global

| Question | Sujet | Décision | Statut |
|----------|-------|----------|--------|
| Q-02 | Fréquences habitudes V1 | B — Toutes les 6 options | ✅ Validé |
| Q-03 | Stockage niyyah | A — Supabase | ✅ Validé |
| Q-04 | Calcul streak global | C+B — Habitudes ≥ 80% | ✅ Validé |
| Q-05 | Horaires de prière | A — Package adhan (local) | ✅ Validé |
| Q-06 | Statut "Rattrapée" | B — 5e valeur PrayerStatus | ✅ Validé |
| Q-07 | Livraison vidéos onboarding | B — Supabase Storage | ✅ Validé |
| Q-08 | Scope + période classement | A+D — Global, semaine lun–dim | ✅ Validé |
| Q-10 | Objectif points quotidien | B — Fixé par niveau actuel | ✅ Validé |
| Q-10b | Seuils et objectifs par niveau | — | ⚠️ EN ATTENTE Cherif |
| Q-10c | Timezone reset leaderboard | — | ⚠️ EN ATTENTE |

---

## Q-02 — Fréquences d'habitudes supportées en V1

**Décision : B — Toutes les 6 options dès V1**

Fréquences supportées :

| Valeur enum | Libellé UI | Description |
|-------------|-----------|-------------|
| `daily` | Quotidien | Tous les jours actifs (`active_days`) |
| `3x_week` | 3×/semaine | 3 jours parmi `active_days` |
| `5x_week` | 5×/semaine | 5 jours parmi `active_days` |
| `weekly` | Hebdomadaire | 1 fois par semaine |
| `monthly` | Mensuel | 1 fois par mois, jour fixé par `monthly_day` |
| `custom` | Personnalisé | Jours cochés explicitement dans `active_days` |

**Définition précise de "custom" :** jours spécifiques de la semaine cochables (L/M/M/J/V/S/D). Intervalle libre (ex: "tous les 3 jours") = V2.

### Impact domaine mobile

```dart
// lib/domain/entities/habit.dart
enum FrequencyType { daily, x3Week, x5Week, weekly, monthly, custom }

class Habit {
  final FrequencyType frequency;
  final Set<int> activeDays;  // 1=lundi, 7=dimanche — utilisé pour daily, custom, Nx_week
  final int? monthlyDay;      // 1-31 — uniquement pour monthly
  // ...
}
```

### Impact schema Supabase

```sql
-- habits table — à inclure dans la migration Phase 0
ALTER TABLE habits
  ADD COLUMN frequency text NOT NULL
    CHECK (frequency IN ('daily','3x_week','5x_week','weekly','monthly','custom')),
  ADD COLUMN active_days int[] DEFAULT '{1,2,3,4,5,6,7}',
  ADD COLUMN monthly_day int CHECK (monthly_day BETWEEN 1 AND 31);
-- monthly_day NULL si frequency != 'monthly'
```

### Impact admin

- HAB-02 (édition habitude système) : sélecteur de fréquence avec les 6 options
- Afficher grille L-D si `daily` ou `custom`
- Afficher champ "Jour du mois" si `monthly`

---

## Q-03 — Stockage de la niyyah (intention du jour)

**Décision : A — Supabase (persistée, exportable en V2)**

### Impact schema Supabase

```sql
CREATE TABLE daily_intentions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date        date NOT NULL,
  content     text NOT NULL CHECK (length(content) BETWEEN 1 AND 200),
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now(),
  UNIQUE (user_id, date)
);
-- RLS : utilisateur voit uniquement ses propres intentions
-- Trigger updated_at automatique
```

### Impact mobile

- `NIYYAH-EDIT` : sauvegarde dans `daily_intentions` via `UpdateIntentionUseCase`
- `HM-01` : charge l'intention du jour via `GetTodayIntentionUseCase`
- Max 200 caractères (validé côté Dart ET Supabase check)

### Impact admin

Aucun en V1. Les intentions sont des données privées utilisateur — pas accessibles depuis le backoffice.

---

## Q-04 — Calcul du streak global

**Décision : C + B — Habitudes uniquement, taux de complétion ≥ 80 %**

- Streak = nombre de jours **consécutifs** avec `habit_completion_rate >= 0.80`
- Les prières **ne font PAS** partie du calcul du streak global
- Un jour **sans habitudes planifiées** = jour neutre (ne rompt pas le streak)

### Définition "habitude attendue ce jour"

| Fréquence | Attendue si... |
|-----------|----------------|
| `daily` | Toujours (selon `active_days`) |
| `3x_week` / `5x_week` | Jour dans `active_days` ET quota hebdo non atteint |
| `weekly` | Premier jour actif de la semaine calendaire |
| `monthly` | Jour du mois = `monthly_day` |
| `custom` | Jour coché dans `active_days` |

### Impact domaine mobile

```dart
// lib/domain/constants/scoring_constants.dart
class ScoringConstants {
  static const double kStreakCompletionThreshold = 0.80;
  // ...
}

// lib/domain/use_cases/score/calculate_streak_use_case.dart
// Entrée : List<HabitLog> + List<Habit> sur N jours
// Remonte jour par jour jusqu'à rupture du seuil
```

### Impact schema Supabase

Streak calculé côté mobile (client) sur les N derniers logs. Pas de colonne `streak` en base en V1 (évite la désynchronisation). Envisager une vue matérialisée en V2 si performance insuffisante.

---

## Q-05 — Source des horaires de prière

**Décision : A — Package adhan (calcul local, offline, gratuit)**

- Package Flutter : [`adhan`](https://pub.dev/packages/adhan)
- Zéro requête réseau pour les horaires de prière
- Paramètres requis (configurés dans SETUP-01) : latitude, longitude, méthode de calcul

### Méthodes de calcul disponibles dans SETUP-01

| Clé | Libellé |
|-----|---------|
| `mwl` | Muslim World League |
| `isna` | ISNA (Amérique du Nord) |
| `egyptian` | Egyptian General Authority of Survey |
| `umm_al_qura` | Umm Al-Qura (Arabie Saoudite) |
| `karachi` | University of Islamic Sciences, Karachi |
| `diyanet` | Diyanet İşleri Başkanlığı (Turquie) |

### Impact mobile

- `data/services/prayer_times_service.dart` — wrapper autour de `adhan`
- Permission localisation demandée dans SETUP-01
- Fallback : saisie manuelle des coordonnées si localisation refusée
- Recalcul automatique à minuit et si localisation change

### Impact admin / Supabase

Aucun — calcul 100 % côté client.

---

## Q-06 — Statut "Rattrapée" sur SL-DETAIL

**Décision : B — 5e valeur de l'enum PrayerStatus**

```dart
enum PrayerStatus {
  pending,   // non encore faite (jour en cours)
  onTime,    // faite à l'heure
  late,      // faite en retard (dans le même jour)
  missed,    // manquée (jour passé, non rattrapée)
  makeup,    // rattrapée (qada)
}
```

### Scoring du statut `makeup`

- Points : **+1 pt** (identique à `late`) — rattraper a de la valeur, moins qu'à l'heure
- Impact streak : `makeup` ne rompt PAS le streak (la prière a quand même été faite)
- Note : le streak est calculé sur les habitudes (Q-04), pas les prières — pas d'impact indirect

### Impact schema Supabase

```sql
-- Mettre à jour le check constraint sur prayer_logs
status text NOT NULL CHECK (status IN ('pending','onTime','late','missed','makeup')),
```

### Impact analytics admin (ANALYTICS-02)

Pour le "taux de complétion prières" :
- Numérateur : `onTime` + `late` + `makeup` (prière effectuée, quelle que soit la forme)
- Dénominateur : toutes les prières hors `pending`
- Affichage séparé optionnel : % à l'heure vs % total effectuées

---

## Q-07 — Livraison des vidéos d'onboarding

**Décision : B — Téléchargées au premier launch via Supabase Storage**

- Bucket Supabase : `onboarding-media` (lecture anonyme avec signed URLs)
- Vidéos non bundlées dans l'IPA/APK → taille du build maîtrisée
- Téléchargement en background au premier lancement après inscription
- Fallback : PNG statique si vidéo non encore téléchargée ou pas de connexion
- Fichiers sources : voir `MEDIA_NOT_VERSIONED.md`

### Impact mobile

- `OnboardingVideoService` — télécharge et met en cache les MP4 localement
- Progress indicator pendant le téléchargement initial
- Cache : `flutter_cache_manager` ou stockage local `path_provider`
- Zéro vidéo commitée dans le repo (règle MEDIA_NOT_VERSIONED)

### Impact admin / Supabase

- Bucket `onboarding-media` à créer dans Supabase Storage
- Upload des 11 MP4 + fallback PNG par Cherif (opération manuelle)
- URLs référencées dans une table `onboarding_assets` ou en constantes côté mobile (à décider en Phase 6)

---

## Q-08 — Scope et période du classement

**Décision : A + D — Global (tous les utilisateurs) · Semaine calendaire lundi–dimanche**

- Scope : tous les utilisateurs de l'app (cercle fermé = V2)
- Période : semaine calendaire lundi–dimanche
- Reset : **lundi 00:00 UTC** (début de la nouvelle semaine)
- Affichage : "Semaine du lun 21 au dim 27 avril · N participants"

### ⚠️ Décision en attente — Timezone du reset

Le reset à 00:00 UTC correspond à des heures différentes selon la région (France = 02:00, USA EST = 20:00 samedi). À valider : UTC strict ou heure locale du serveur (Europe/Paris) ?

**Recommandation** : UTC strict pour V1 (simplifie la logique serveur).

### Impact schema Supabase

```sql
-- Vue live du leaderboard (semaine courante)
CREATE OR REPLACE VIEW weekly_leaderboard AS
SELECT
  user_id,
  SUM(points)                                    AS weekly_score,
  RANK() OVER (ORDER BY SUM(points) DESC)        AS rank,
  COUNT(*) OVER ()                               AS total_participants
FROM score_events
WHERE created_at >= date_trunc('week', now() AT TIME ZONE 'UTC')
  AND created_at <  date_trunc('week', now() AT TIME ZONE 'UTC') + INTERVAL '7 days'
GROUP BY user_id;
```

Vue live recommandée en V1. Envisager cron + snapshot table si performance insuffisante (V2).

### Impact mobile

- LB-01 : calculer et afficher les dates de début/fin de semaine courante
- Indicateur du rang de l'utilisateur connecté en bas de liste

### Impact admin

- ANALYTICS-02 : historique des classements hebdomadaires (archive des semaines passées)

---

## Q-10 — Objectif de points quotidien

**Décision : B — Fixé par le niveau actuel (augmente automatiquement à chaque palier)**

L'objectif affiché sur HM-01 ("42 / 60 pts") change selon le niveau de l'utilisateur.

### ⚠️ Seuils et objectifs — EN ATTENTE DE VALIDATION CHERIF

Les valeurs ci-dessous sont des **propositions** à valider avant que l'agent code le système de scoring :

| Niveau | Seuil d'entrée (pts cumulés) | Objectif quotidien |
|--------|-----------------------------|--------------------|
| Aspirant (1) | 0 pts | 30 pts/j |
| Murid (2) | 10 000 pts | 45 pts/j |
| Salik (3) | 30 000 pts | 60 pts/j |
| Mujahid (4) | 70 000 pts | 75 pts/j |
| Wali (5) | 150 000 pts | 90 pts/j |
| Murabbi (6) | 300 000 pts | 105 pts/j |

> Calibration sur 10 ans d'assiduité : à 60 pts/j × 365j × 10 ans = 219 000 pts totaux.
> Le niveau Murabbi (300 000 pts) nécessite environ 14 ans à plein régime — délibérément difficile.

### Impact domaine mobile

```dart
// lib/domain/constants/scoring_constants.dart — EN ATTENTE VALIDATION
class LevelConstants {
  static const Map<Level, int> cumulativeThresholds = {
    Level.aspirant:  0,
    Level.murid:     10000,
    Level.salik:     30000,
    Level.mujahid:   70000,
    Level.wali:      150000,
    Level.murabbi:   300000,
  };
  static const Map<Level, int> dailyObjective = {
    Level.aspirant:  30,
    Level.murid:     45,
    Level.salik:     60,
    Level.mujahid:   75,
    Level.wali:      90,
    Level.murabbi:   105,
  };
}
```

**BLOQUER le développement du scoring jusqu'à validation de ces valeurs.**

---

## Table des scores par action

> Commune mobile + admin (analytics). Source de vérité ici.

| Action | Points |
|--------|--------|
| Prière à l'heure (`onTime`) | +3 pts |
| Prière en retard (`late`) | +1 pt |
| Prière rattrapée (`makeup`) | +1 pt |
| Prière manquée (`missed`) | 0 pt |
| Habitude complétée (`done`) | points de l'habitude (1–10) |
| Habitude en retard (`late`) | points / 2 (arrondi inférieur) |
| Habitude manquée (`missed`) | 0 pt |

Score maximum théorique / jour : 5 prières × 3 pts = 15 pts prières + habitudes (variable).

---

## Décisions restantes — ⚠️ Bloquantes avant Phase 3+

| # | Question | Impact | Urgence |
|---|----------|--------|---------|
| Q-10b | Seuils d'entrée par niveau (pts cumulés) | Scoring, Level-Up, ANALYTICS | Avant Phase 5 |
| Q-10c | Objectifs quotidiens par niveau (valeurs exactes) | HM-01 affichage, scoring | Avant Phase 5 |
| Q-08t | Timezone du reset leaderboard (UTC vs Europe/Paris) | Vue Supabase, LB-01 | Avant Phase 5 |
| Q-07s | Table `onboarding_assets` vs constantes Dart pour les URLs vidéo | Architecture mobile | Avant Phase 6 |

---

## Références croisées

- Schema Supabase complet : `murabbi-admin/supabase/migrations/`
- ERD : `murabbi-admin/docs/architecture/erd.md` (à produire en Phase 0)
- Issues Phase 0 mobile : https://github.com/Maximus203/murabbi-mobile/issues/1
- Issues Phase 0 admin : https://github.com/Maximus203/murabbi-admin/issues/1
