# ADR-009 — Modèle hybride pour les points habitude/catégorie

**Statut** : amendé v2 (2026-05-09) — remplace v1 (2026-05-04)
**Date** : 2026-05-04 (v1) → 2026-05-09 (v2)
**Auteur** : Architecte mobile
**Sources** :
- Décision produit v1 : Q-12 (`product_decisions_v1.md` admin) — verrouillée 2026-05-03
- Audit cross-spec : 2026-05-09 (D-03) — révèle un désalignement entre l'ADR v1
  et le SQL admin
- Décision produit v2 : Q-12 ré-ouverte par le PO le 2026-05-09 → Option C hybride
- Migration : `20260509000000_align_mobile_domain.sql` (PR #46 admin, mergée 2026-05-09)
- Documents impactés : `docs/architecture/data_model.md`, `lib/domain/entities/category.dart`,
  `lib/domain/entities/habit.dart`, `lib/domain/use_cases/score/score_calculator_use_case.dart`

---

## 1. Contexte

La modélisation Phase 0 portait un champ `points` (`HabitPoints` 1..10) à la fois sur
`Habit` ET sur `Category` côté Dart. Trois options coexistaient :

- **Option A** — points par habitude uniquement : la catégorie est purement organisationnelle
  (couleur, icône, regroupement). Chaque habitude définit sa propre valeur.
- **Option B** — points par catégorie (héritage) : toutes les habitudes d'une catégorie
  héritent du même score, défini une seule fois côté catégorie.
- **Option C** — hybride : la catégorie fournit un défaut, l'habitude peut surcharger.

L'audit cross-spec du 2026-05-09 (D-03) a révélé un **désalignement structurel** entre
les couches mobile et admin :

| Couche | État au 2026-05-04 |
|--------|---------------------|
| Dart (mobile) | `Habit.points` ✓ — `Category.points` retiré (Option A) |
| SQL (admin) | `categories.points_per_completion` ✓ (depuis baseline `20260427000000_initial_admin_schema.sql:326`) — `habits.points` **absent** (de facto Option B) |

Autrement dit : l'ADR v1 (2026-05-04) prétendait justifier l'Option A en s'appuyant sur
le fait que « la table `categories` côté Supabase n'a jamais eu de colonne `points` » —
**c'était factuellement faux**. Le SQL admin implémentait depuis le début exactement
l'Option B que l'ADR rejetait.

## 2. Décision (révisée 2026-05-09)

**Option C hybride** retenue par le PO suite à l'audit cross-spec 2026-05-09 :

- `categories.points_per_completion` (1..10) **conservée** côté SQL — fournit le défaut
  au niveau catégorie.
- `habits.points` (`smallint NULL`, 1..10) **ajoutée** côté SQL par la migration
  `20260509000000_align_mobile_domain.sql` — override par habitude possible.
- Sémantique scoring : `effective_points = habit.points ?? category.points_per_completion`.
  Si l'habitude n'a pas de valeur explicite, on hérite de la catégorie.
- Côté domain Dart : `Habit.points` reste de type `HabitPoints` (1..10) **non-null**, le
  fallback catégorie est résolu à la lecture par le repository (`HabitMapper`) avant
  d'instancier l'entité — l'entité domain n'a donc pas à connaître la nullabilité SQL.

L'ADR initial (2026-05-04) actait Option A pure ; la migration SQL ne l'a jamais suivie
(cf. audit D-03). Le PO a re-tranché en C pour préserver à la fois les défauts catégorie
(UX simplifiée à la création) et la liberté éditoriale par habitude (override quand
pertinent : « Coran 5 min » 3 pts vs « Coran approfondi » 7 pts).

## 3. Conséquences

### Positives

- **Convergence mobile ↔ admin** : domain Dart, schéma SQL et règle de scoring sont
  alignés sur la même sémantique. Plus de désalignement structurel comme constaté
  dans l'audit D-03.
- **UX création d'habitude simplifiée** : le formulaire HB-02 peut omettre le champ
  « points » par défaut — la catégorie sélectionnée fournit la valeur. L'utilisateur
  qui veut surcharger reste libre de le faire (champ optionnel).
- **Liberté éditoriale conservée** : deux habitudes de la même catégorie peuvent avoir
  des poids différents quand l'éditorial le justifie.

### Négatives

- **Source de vérité à deux niveaux** : `ScoreCalculatorUseCase` (et toute requête
  analytique) doit appliquer la résolution `habit.points ?? category.points_per_completion`.
  Risque : un consommateur qui lit directement `habit.points` sans tenir compte du
  fallback catégorie obtient `null` pour des habitudes valides. **Mitigation** : la
  résolution est faite dans `HabitMapper` côté repository, l'entité domain expose
  toujours une valeur non-null.
- **Migration SQL non rétrocompatible** : la colonne `habits.points` est nouvelle ;
  les anciennes lignes ont `NULL` (donc fallback catégorie). Aucune perte de donnée,
  mais toute requête écrite avant le 2026-05-09 doit être relue.

### Neutres

- `HabitPoints` (1..10) reste utilisée par `Habit` et — désormais — par `Category`.
- `Category.points_per_completion` réintroduit côté Dart en tant que défaut héritable.

---

## 4. Notes d'implémentation

- `lib/domain/entities/category.dart` : champ `pointsPerCompletion` (`HabitPoints`)
  réintroduit, `props` mis à jour.
- `lib/domain/entities/habit.dart` : `points` reste non-null, le mapper résout le
  fallback catégorie à la construction.
- `lib/data/mappers/habit_mapper.dart` (à créer / amender en Phase 3) : applique
  `effective = row['points'] ?? category.pointsPerCompletion`.
- Tests TDD à amender : `test/domain/entities/entities_test.dart`,
  `test/domain/use_cases/categories/categories_use_cases_test.dart`,
  `test/domain/use_cases/score/...`.
- `docs/architecture/data_model.md` : section catégories/habitudes à actualiser pour
  refléter l'Option C (la source de vérité SQL reste côté `murabbi-admin/supabase/`).

---

## 5. Historique

- **v1 — 2026-05-04** — Option A retenue (`Category.points` retiré côté Dart).
  Justification §3 « Modèle SQL admin aligné » **factuellement fausse** : la colonne
  `categories.points_per_completion` existait côté SQL depuis le baseline
  `20260427000000_initial_admin_schema.sql:326`. L'ADR a renversé l'attribution
  Habit↔Category uniquement côté Dart, alors que le SQL implémentait exactement
  l'Option B que l'ADR prétendait avoir rejetée.
- **v2 — 2026-05-09** — Audit cross-spec (D-03) révèle le désalignement. PO ré-ouvre
  Q-12 et tranche en faveur de l'Option C hybride. Migration
  `20260509000000_align_mobile_domain.sql` ajoute `habits.points smallint NULL`
  côté SQL, sans toucher à `categories.points_per_completion`. ADR ré-écrit (cette
  version), titre changé de « Retrait du champ `Category.points` » à
  « Modèle hybride pour les points habitude/catégorie ».

---

*ADR-009 — Murabbi mobile · v2 2026-05-09 (amende v1 2026-05-04)*
