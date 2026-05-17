# ADR-017 — Garde-fou anti-régression `strokeWidth` : script CI Dart plutôt que `custom_lint`

**Statut** : Accepté · 2026-05-17
**Slice associée** : Issue #32 (suite de #28 / PR #31 — tokens `AppBorderWidth`)
**Référence** : `docs/architecture/design-tokens.md` §Épaisseurs de trait.

## Contexte

PR #31 (`feat(ds): introduce AppBorderWidth tokens (#28)`) a livré la grammaire
ternaire d'épaisseurs (`thin 0.5` / `focusRing 1.5` / `indicatorStroke 2.0`).
Sans garde-fou, rien n'empêche un futur contributeur de réintroduire un
`strokeWidth: 2` hardcodé — le drift que les tokens visent justement à éliminer.

L'issue #32 demande une règle qui :
- interdit `strokeWidth: <littéral>` dans `lib/` ;
- tolère `test/` (golden tests, comparaisons numériques) ;
- suggère le token `AppBorderWidth` le plus proche ;
- ignore les déclarations de paramètre des widgets custom (`AppProgressRing`).

## Options

### Option A — Package `custom_lint` + règle `avoid_literal_stroke_width`

Ajouter `custom_lint` + `analyzer_plugin` en `dev_dependencies`, créer un
package de lints, déclarer un plugin analyzer dans `analysis_options.yaml`.

**Avantages**
- Intégration native dans `flutter analyze` et l'IDE (squiggle en direct).
- Accès à l'AST → distinction call-site / déclaration parfaitement fiable.

**Inconvénients**
- Réintroduit exactement la complexité que **ADR-016 vient de retirer** :
  un plugin analyzer est un sous-processus à versionner, sensible aux bumps
  de SDK Dart / `analyzer` (instabilité de build connue de l'écosystème).
- Un package séparé (`tool/lints/` ou `packages/`) à maintenir, avec son
  propre `pubspec.yaml` et sa résolution de versions.
- Ralentit `flutter analyze` (chargement du plugin).
- Surdimensionné pour **une seule règle** sur un pattern textuel simple.

### Option B — Script Dart de CI (`tool/check_stroke_width.dart`)

Un script Dart autonome qui scanne `lib/`, détecte `strokeWidth:` suivi d'un
nombre littéral via regex, suggère le token le plus proche, et sort en code 1
si une violation est trouvée. Branché en CI avant `flutter analyze`.

**Avantages**
- **Zéro nouvelle dépendance** — n'utilise que `dart:io`.
- Aucune instabilité de build : pas de plugin analyzer, pas de sous-processus.
- Aligné avec la philosophie d'ADR-016 (boucle dev simple et rapide).
- Lisible et modifiable par n'importe quel contributeur en 2 minutes.
- La distinction call-site / déclaration est triviale : le `:` après
  `strokeWidth` n'apparaît que sur un argument nommé, jamais sur
  `final double strokeWidth;` ni `this.strokeWidth = 6,`.

**Inconvénients**
- Pas de feedback live dans l'IDE — la violation n'apparaît qu'à l'exécution
  du script (en CI ou en pré-commit local).
- Analyse textuelle, pas AST : un `strokeWidth:` dans une string multi-ligne
  serait théoriquement un faux positif (cas inexistant et peu plausible).

## Décision

**Option B retenue** — script Dart de CI.

**Justifications senior** :
1. **Cohérence avec ADR-016** : le repo a délibérément retiré `build_runner`
   pour préserver une boucle dev simple. Ajouter un plugin analyzer
   (`custom_lint`) irait à contre-courant de cette décision récente.
2. **Proportionnalité** : une règle unique sur un pattern textuel ne justifie
   pas l'infrastructure d'un package de lints custom.
3. **Robustesse de build** : `custom_lint` est réputé fragile aux bumps de
   SDK ; le script n'a aucune surface de casse.
4. **Le besoin réel est la CI verte**, pas le feedback IDE — un pré-commit
   ou un job CI suffit à empêcher le drift.
5. **Réversibilité** : si un besoin de feedback IDE émerge, migrer vers
   `custom_lint` reste possible (la regex se transpose en visiteur AST).

## Conséquences

### Action immédiate
- ✅ **`tool/check_stroke_width.dart`** créé.
- 🔧 **4 violations existantes corrigées** : `CircularProgressIndicator(
  strokeWidth: 2)` → `AppBorderWidth.indicatorStroke` dans
  `ha_01_habits_list_screen.dart`, `ha_02_create_habit_screen.dart`,
  `sa_01_today_screen.dart`, `sa_03_prayer_detail_screen.dart`.
- 📝 **`docs/architecture/design-tokens.md`** mis à jour (section garde-fou).

### À faire (suivi)
- Brancher `dart run tool/check_stroke_width.dart` dans le workflow CI
  GitHub Actions avant l'étape `flutter analyze`. Tant que la CI n'est pas
  formalisée, le script reste exécutable manuellement / en pré-commit.

### Périmètre figé
- Le script ne scanne **que `lib/`**. `test/` reste libre (issue #32).
- Les déclarations de champ/paramètre (`AppProgressRing.strokeWidth`) ne
  sont pas concernées : seules les valeurs hardcodées en call-site le sont.

## Lien avec les ADRs précédents
- **ADR-016** (providers legacy, anti-`build_runner`) — cet ADR-017 prolonge
  la même doctrine « simplicité de build » au choix d'outillage lint.
