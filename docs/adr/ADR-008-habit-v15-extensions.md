# ADR-008 — Extensions habit v1.5 : composition `HabitTarget` côté Dart

**Statut** : accepté
**Date** : 2026-05-04
**Auteur** : Architecte mobile
**Sources**
- Spec v1.5 (admin) : `murabbi-admin/docs/decisions/murabbi_v15_spec_addendum.md`
- Design v1.5 (admin) : `murabbi-admin/docs/decisions/murabbi_v15_design_addendum.md`
- ADR admin équivalent : `murabbi-admin/docs/adr/ADR-009-habit-v15-extensions.md`
- Issue : [murabbi-mobile#9](https://github.com/Maximus203/murabbi-mobile/issues/9)
- Décisions produit verrouillées 2026-05-03 : Q-07 (`makeup` +1), Q-08-cal (couleur jour),
  Q-10 (pseudonym), Q-12 (`Category.points` retiré → ADR-009), Q-13 (cover obligatoire),
  Q-15a (`flutter_local_notifications` requis), Q-17 (streak option C)

---

## 1. Contexte

La spec v1.5 ajoute trois fonctionnalités optionnelles par habitude — **objectif chiffré**,
**timer in-app**, **sous-tâches** — avec un modèle SQL plat sur la table `habits` (5
colonnes nullables + 3 `CHECK` constraints + colonne GENERATED `target_reached` sur
`habit_logs`).

Côté admin (TypeScript / Server Actions), le mapping est trivial : un formulaire HAB-02
manipule directement les 5 champs avec validation Zod alignée sur les `CHECK`
(cf. `ADR-009-habit-v15-extensions.md` admin).

Côté **mobile**, l'option naïve serait de répliquer 1-pour-1 le SQL — 5 champs nullables
sur `Habit`. Mais cela fragmente la cohérence métier : chaque widget d'exécution
(HB-EXECUTE), chaque use case de scoring devrait reconstituer la logique des `CHECK`
constraints (« y a-t-il un objectif ? un timer ? l'unité est-elle custom ? »).

## 2. Décision

**Composition `HabitTarget`** côté Dart, SQL flat inchangé.

```dart
sealed class HabitTarget extends Equatable {
  const factory HabitTarget.none() = HabitTargetNone;
  factory HabitTarget.value({...}) = HabitTargetValue;   // objectif sans timer
  factory HabitTarget.timed({...}) = HabitTargetTimed;   // objectif + timer (min/h)
}
```

Sur `Habit`, on porte :

```dart
final HabitTarget target;          // default: HabitTarget.none()
final List<HabitSubtask> subtasks; // max 15
final bool subtasksAllRequired;    // implique subtasks.isNotEmpty quand true
```

Sur `HabitLog`, les nouveaux champs sont optionnels et plats (`actualValue`,
`targetReached`, `subtasksCompleted`, `duration`) — ils reflètent le SQL parce que
ce sont des données d'état, pas des invariants de configuration.

Le mapping `HabitTarget` ↔ 5 colonnes plates est confiné au repository
(`data/repositories/habit_repository_impl.dart`, hors scope Phase 0.5).

## 3. Conséquences

### Positives

- **Sécurité de typage** : un `HabitTarget.timed` ne peut pas être construit avec une
  unité non-temporelle — le compilateur Dart rejoue les `CHECK` SQL en mémoire.
- **Pattern matching exhaustif Dart 3** : `switch` sur la sealed class signale tout cas
  oublié dans HB-EXECUTE et HB-DETAIL — utile quand une éventuelle `HabitTarget.recurring`
  s'ajoutera plus tard.
- **Use cases simplifiés** : `ScoreCalculatorUseCase` lit directement `habit.target.hasValue`
  / `habit.subtasksAllRequired` au lieu d'un cascade de `if (... != null)`.
- **Cohérence avec admin** : les invariants v1.5 sont enforced par 3 mécanismes
  indépendants — SQL `CHECK`, Zod admin, sealed Dart — chacun dans son cadre.
  Un changement de spec déclenche 3 mises à jour explicites.

### Négatives

- **Couche de mapping** : ~30 lignes au repository data layer pour traduire
  `HabitTarget` ↔ 5 colonnes flat. Tests round-trip à prévoir.
- **Décalage DTO/entité** : `HabitDto` (mapping JSON Supabase) restera plat,
  `Habit` est composé. À documenter dans `data/models/habit_dto.dart` (Phase 1).
- **`HabitLog` reste plat** : asymétrie volontaire — un log est de la donnée d'état
  qui voyage 1-pour-1 entre Supabase et le mobile, sans invariant de configuration
  à enforcer côté entité.

### Neutres

- L'évolution future (`HabitTarget.recurring` ex: 5 pages tous les 3 jours) nécessitera
  une extension du SQL ET de la sealed class — coût explicite, acceptable.
- Le linter ne vérifie pas l'alignement SQL/Zod/Dart — relire les 3 sources à chaque
  changement de spec habit.

## 4. Notes d'implémentation (Phase 0.5 mobile)

- `lib/domain/entities/habit_target.dart` : sealed class + 3 variantes.
- `lib/domain/entities/habit_subtask.dart` : entité + invariants (title <= 120,
  orderIndex >= 0).
- `lib/domain/entities/habit.dart` : ajout des champs `target`, `subtasks`,
  `subtasksAllRequired` + invariants collection (max 15, `(habitId, orderIndex)`
  unique, `subtasksAllRequired` ⇒ `subtasks.isNotEmpty`).
- `lib/domain/entities/habit_log.dart` : ajout de `actualValue`, `targetReached`,
  `subtasksCompleted`, `duration` + invariants (actualValue >= 0,
  targetReached ⇒ actualValue != null, duration ∈ [0, 24h]).
- `lib/domain/value_objects/target_unit.dart` : enum 10 valeurs +
  `TargetUnit.isTimeBased`.
- `lib/domain/value_objects/target_value.dart` : wrapper `int` ∈ [1..9999].
- `lib/domain/use_cases/timer/habit_timer.dart` : machine à états pure
  (start/pause/resume/stop), aucune dépendance à `flutter_local_notifications` —
  cette dernière sera pilotée par un service présentation à partir de cet état.
- `lib/domain/use_cases/score/score_calculator_use_case.dart` : matrix v1.5 § 3.2/4.

## 5. Hors scope (Phase 1+ ou Phase 4)

- DTO Supabase + mapping `HabitTarget` ↔ flat (Phase 1 datasource).
- UI HB-EXECUTE bottom sheet (Phase 4).
- HB-02 form additions — target picker, subtasks editor, timer toggle (Phase 4).
- Notifications natives planifiées (Phase 4 — service au-dessus du domaine).

---

*ADR-008 — Murabbi mobile · 2026-05-04*
