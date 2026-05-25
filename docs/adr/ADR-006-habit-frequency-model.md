# ADR-006 — Modèle de fréquence Habit (frequencyType + frequency + monthlyDay)

**Date** : 2026-04-28
**Auteur** : Agent mobile (Phase 0, après review Tech Lead PR #8)
**Statut** : Accepté

## Contexte

L'entité `Habit` doit modéliser des récurrences variées : quotidienne, X fois par
semaine, jours précis de la semaine, X fois par jour, mensuelle (jour précis du mois),
ou règle libre. Le wireframe HB-02 / HB-04 expose un picker à 6 choix, avec champs
contextuels selon le choix (sliders pour frequency, jours de semaine, jour du mois…).

La source de vérité produit (`murabbi-admin/docs/decisions/product_decisions_v1.md`
§ Q-02) propose initialement un modèle SQL basé sur un `text` enum simple :

```sql
frequency text CHECK (frequency IN ('daily','3x_week','5x_week','weekly','monthly','custom')),
active_days int[],
monthly_day int CHECK (monthly_day BETWEEN 1 AND 31),
```

La review Tech Lead (PR #8, critique #2) a identifié 3 divergences entre ce modèle
SQL et le code Dart livré : naming, `monthlyDay` manquant, ajout de `frequency: int`
sans contrepartie SQL.

## Options évaluées

### A — Modèle SQL plat (enum string `'3x_week'`, `'5x_week'`, …)

**Avantages**
- Mapping 1:1 avec une seule colonne `frequency text`
- Check constraint SQL simple
- Lisibilité directe en BDD

**Inconvénients**
- Explosion combinatoire dès qu'on veut "X fois par semaine" pour X arbitraire
  (`3x_week`, `5x_week`, `7x_week`, `12x_week`…)
- Couplage fort entre la valeur produit (X) et son nom enum
- Migration coûteuse pour toute évolution

### B — Modèle riche `frequencyType + frequency: int` + `monthlyDay: int?` (retenu)

**Avantages**
- Sépare la **catégorie** de récurrence (`HabitFrequencyType`) de sa **valeur** (`frequency`)
- Permet n'importe quel X pour `perDay` / `perWeek` sans toucher au schéma
- Invariants Dart explicites (constructeur lève `ArgumentError`)
- `monthlyDay` typé et borné à 1..31, séparé de `activeDays` qui reste un set
  de jours de semaine 1..7

**Inconvénients**
- Mapping data layer non trivial : un `text` simple ne suffit plus côté Supabase
- Nécessite de trancher la stratégie de stockage (JSONB ? Plusieurs colonnes ?)

## Décision

**Option B retenue.** Le modèle Dart fait foi pour le domaine. Le mapping vers
Supabase sera défini dans **l'ADR data Phase 4** (au plus tard), avec deux pistes
ouvertes :

1. **Schema relationnel enrichi** : colonnes `frequency_type text`,
   `frequency_count int`, `monthly_day int`, `active_days int[]`. Plus verbeux
   mais queryable et indexable.
2. **JSONB** : une seule colonne `frequency_config jsonb` typée par un check.
   Plus souple, moins queryable.

## Conséquences

- `product_decisions_v1.md` § Q-02 doit être mis à jour côté admin pour refléter
  le modèle Dart comme source de vérité (à faire côté repo `murabbi-admin`).
- L'entité `Habit` valide ses invariants au runtime via `ArgumentError` :
  - `monthly` ⇒ `monthlyDay ∈ [1..31]`
  - non-`monthly` ⇒ `monthlyDay == null`
- `activeDays` reste un `Set<int>` de jours de **semaine** (1..7). Le jour du
  mois est désormais porté par le champ dédié `monthlyDay` — fini la double
  sémantique signalée en review.
- Le data layer (Phase 4) devra fournir un mapper bidirectionnel
  `Habit ↔ HabitDto`.

## Références

- Review Tech Lead PR #8 — critique #2 (2026-04-28)
- `lib/domain/entities/habit.dart`
- `test/domain/entities/entities_test.dart` groupe `Habit monthlyDay invariant`
