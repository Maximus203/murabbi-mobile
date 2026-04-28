# ADR-007 — Modélisation de la plage horaire d'une Habit (TimeOfDayValue)

**Date** : 2026-04-28
**Auteur** : Agent mobile (Phase 0, après review Tech Lead PR #8)
**Statut** : Accepté

## Contexte

Le wireframe HB-02 / HB-04 affiche un **double picker `from / to`** permettant à
l'utilisateur de saisir une plage horaire libre (ex. `08:00 → 12:00`) pour une
habitude. Cette plage pilote :

- l'affichage du badge horaire sur la home (HM-01)
- les notifications calibrées dans la fenêtre exacte (P-7 — promesse produit)
- le tri / regroupement des habitudes par moment de la journée

Le code initial de Phase 0 utilisait un enum à 4 valeurs
(`HabitTimeRange { morning, afternoon, evening, anytime }`), simplification
incompatible avec la précision attendue par les wireframes et la règle P-7.

## Options évaluées

### A — Enum simplifié à 4 catégories (initial Phase 0)

**Avantages** : trivial à modéliser, mapping SQL direct.

**Inconvénients**
- Impossible de calibrer les notifications sur la plage choisie par l'user
- Contredit le wireframe HB-02 (saisie libre `from`/`to`)
- Régression métier vis-à-vis de P-7

### B — Champs riches `rangeStart` / `rangeEnd: TimeOfDayValue?` (retenu)

**Avantages**
- Capture la précision exacte saisie par l'utilisateur
- Permet aux notifications d'être calibrées (P-7)
- Sémantique « anytime » = `rangeStart == null && rangeEnd == null`
- Invariants explicites en domaine pur

**Inconvénients**
- Nécessite un value object (Flutter `TimeOfDay` interdit en `lib/domain/`)
- Invariants à valider côté constructeur

## Décision

**Option B retenue.** Création d'un value object pur `TimeOfDayValue(hour, minute)`
dans `lib/domain/value_objects/time_of_day_value.dart`. L'entité `Habit` expose
deux champs nullables `rangeStart` et `rangeEnd: TimeOfDayValue?`.

### Pourquoi un value object pur plutôt que `flutter.TimeOfDay`

`lib/domain/` ne peut pas dépendre de Flutter (cf. ADR-001 — Clean Architecture,
règle de pureté Q-1). Un mapper sera fourni dans la couche `presentation/`
pour convertir `TimeOfDayValue ↔ flutter.TimeOfDay` au moment du picker.

### Invariants

1. `rangeStart == null` ⇔ `rangeEnd == null` (sémantique « anytime »).
   L'asymétrie est une erreur de saisie.
2. Si non-null : `rangeStart.isBefore(rangeEnd)` strictement.
3. **Pas de wrap autour de minuit en V1.** Une habitude `23:00 → 02:00` est
   refusée par l'invariant. Justification : le cas d'usage est rare, et le
   support (notifications, affichage) doublerait la complexité sans valeur
   produit prouvée. À reconsidérer en V2 si la demande utilisateur est forte.

## Conséquences

- L'enum `HabitTimeRange` est supprimé du domaine.
- Tous les tests `Habit` migrent vers `rangeStart` / `rangeEnd` (RED puis GREEN).
- Le wireframe HB-02 peut désormais être implémenté fidèlement en Phase 4 :
  picker `from` ↔ `TimeOfDayValue`, picker `to` ↔ `TimeOfDayValue`, "anytime"
  toggle ↔ both null.
- Les notifications (P-7) seront déclenchées au sein de la plage `[rangeStart,
  rangeEnd]` ; la stratégie de planification sera détaillée dans l'ADR notif
  (Phase 4 ou 5).
- Côté Supabase : prévoir deux colonnes `range_start time` / `range_end time`
  nullables (mapper data layer Phase 4).

## Références

- Review Tech Lead PR #8 — critique #3 (2026-04-28)
- `lib/domain/value_objects/time_of_day_value.dart`
- `lib/domain/entities/habit.dart`
- `test/domain/entities/entities_test.dart` groupe `Habit time range invariant`
- ADR-001 — Clean Architecture (pureté domaine)
