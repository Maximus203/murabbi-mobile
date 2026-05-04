# ADR-009 — Retrait du champ `Category.points`

**Statut** : accepté
**Date** : 2026-05-04
**Auteur** : Architecte mobile
**Sources** :
- Décision produit : Q-12 (`product_decisions_v1.md` admin) — verrouillée 2026-05-03
- Issue : [murabbi-mobile#9](https://github.com/Maximus203/murabbi-mobile/issues/9)
- Documents impactés : `docs/architecture/data_model.md`, `lib/domain/entities/category.dart`,
  `lib/domain/use_cases/categories/create_category_use_case.dart`

---

## 1. Contexte

La modélisation Phase 0 portait un champ `points` (`HabitPoints` 1..10) à la fois sur
`Habit` ET sur `Category`. Deux justifications possibles coexistaient :

- **Option A** — points par habitude uniquement : la catégorie est purement organisationnelle
  (couleur, icône, regroupement). Chaque habitude définit sa propre valeur (ex: prière > dhikr).
- **Option B** — points par catégorie (héritage) : toutes les habitudes d'une catégorie
  héritent du même score (ex: « Sport » = 3 pts pour toutes ses habitudes).
- **Option C** — hybride : la catégorie fournit un défaut, l'habitude peut surcharger.

L'option C — celle implicitement portée par le code Phase 0 (les deux entités exposaient
`points`) — était ambiguë : aucun use case ne précisait laquelle des deux valeurs faisait
foi au moment du scoring, et le risque de désynchronisation (catégorie 3 pts, habitude
5 pts) était structurel.

## 2. Décision

**Option A** retenue par le PO (Q-12, 2026-05-03) : `Category.points` est **retiré** du
modèle de domaine. Chaque `Habit` porte sa propre `HabitPoints` (1..10), unique source
de vérité pour le scoring.

La catégorie redevient un objet purement organisationnel : `id`, `name`, `color`, `icon`,
`isSystem`. Aucune valeur numérique liée au scoring.

## 3. Conséquences

### Positives

- **Source de vérité unique** : `ScoreCalculatorUseCase` lit `habit.points` sans avoir
  à arbitrer entre deux champs.
- **Liberté éditoriale** : deux habitudes de la même catégorie peuvent avoir des poids
  différents sans introduire d'exception (« Coran 5 min » 3 pts vs « Coran approfondi »
  7 pts, tous deux dans « Spirituel »).
- **Modèle SQL admin aligné** : la table `categories` côté Supabase n'a jamais eu de
  colonne `points` — le domaine mobile est désormais cohérent avec la persistance.

### Négatives

- **Saisie utilisateur** : créer une habitude personnalisée nécessite explicitement de
  choisir une valeur de points. Le formulaire HB-02 doit proposer un défaut sensé
  (ex: 3 pts) pour ne pas surcharger l'utilisateur — décision UI, hors scope ADR.
- **Catégories système moins « descriptives »** : on perd la valeur indicative
  « catégorie X = effort moyen Y pts » qu'on aurait pu afficher. Acceptable, ça
  doublonnait le rôle des niveaux.

### Neutres

- Aucune migration SQL nécessaire (la colonne n'a jamais été persistée côté admin).
- `HabitPoints` reste utilisée — uniquement par `Habit`.

---

## 4. Notes d'implémentation

- `lib/domain/entities/category.dart` : champ `points` supprimé, `props` mis à jour.
- Tests TDD `test/domain/entities/entities_test.dart` et
  `test/domain/use_cases/categories/categories_use_cases_test.dart` adaptés (RED → GREEN).
- `docs/architecture/data_model.md` à relire si une mention résiduelle subsiste — la
  source de vérité SQL vit côté `murabbi-admin/supabase/`, pas dans ce repo.

---

*ADR-009 — Murabbi mobile · 2026-05-04*
