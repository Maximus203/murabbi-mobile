# ADR-010 — Goldens Linux-only + workflow de régénération CI

**Statut** : Proposé
**Date** : 2026-05-05
**Décideur** : Cherif (PO) + agent senior

## Contexte

La PR #15 (Phase 1 — design system + 8 widgets atomiques) introduit des
goldens (`golden_toolkit`) pour verrouiller le rendu pixel des composants
contre régression visuelle.

Premier passage CI : 7 goldens sur 8 échouent avec des diffs de pixels
sub-percentuels (0.35 % à 4.67 %). Cause confirmée : les PNG de référence
ont été générés sur Windows (DirectWrite) alors que la CI tourne sur
Ubuntu (FreeType). L'antialiasing diffère, ce qui produit des diffs
visuellement invisibles mais détectés par le `LocalFileComparator`.

C'est un piège classique de `flutter_test` golden : le rendu n'est **pas**
bit-exact entre OS, même avec des polices bundlées.

## Options envisagées

### A. Tolérance de diff globale (`goldenFileComparator` permissif < 5 %)

- ✅ Simple à mettre en place (un comparator custom)
- ❌ Masque les vraies régressions sous le seuil
- ❌ Le seuil empirique varie par widget (le ProgressRing à 0.35 %, le
  BottomNav à 4.67 %)
- ❌ Pratique anti-pattern dans la communauté Flutter

### B. Régénérer les goldens en local sur chaque OS contributeur

- ❌ Non scalable (chaque dev/OS produit des PNG différents)
- ❌ Bruit Git permanent
- ❌ Aucune source of truth

### C. Goldens Linux-only + workflow de régénération CI **(retenu)**

- ✅ Une seule source de vérité : Linux (= CI prod)
- ✅ Local Windows/macOS : bypass no-op → feedback rapide, zéro faux positif
- ✅ Regénération déterministe via workflow GitHub manuel
- ✅ Pratique standard sur les projets Flutter matures (cf. Flutter SDK
  lui-même qui n'enforce les goldens que sur un runner précis)

## Décision

**Adopter l'option C** :

1. **`test/flutter_test_config.dart`** détecte `Platform.isLinux` et installe
   un `_BypassGoldenFileComparator` (no-op `compare()` + `update()`) hors
   Linux.
2. **`.github/workflows/update-goldens.yml`** : workflow GitHub
   `workflow_dispatch` qui :
   - checkout la branche cible
   - exécute `flutter test --update-goldens` sur `ubuntu-latest`
   - commit les PNG sous `**/goldens/*.png` avec message
     `chore(test): regenerate goldens on Linux CI`
   - push sur la branche cible (auteur `github-actions[bot]` — règle G-1
     respectée, pas de trailer Claude)
3. **CI principale** (`.github/workflows/mobile.yml`) inchangée : continue
   d'enforcer les goldens sur le job `Test & Coverage` (Linux).

## Conséquences

### Positives
- CI fiable et déterministe sur les régressions visuelles.
- Les développeurs Windows/macOS ne sont plus bloqués par des diffs OS.
- Process de régénération automatisé, traçable (commits CI signés bot).

### Négatives / à surveiller
- Les développeurs Windows/macOS ne **voient** plus les régressions
  visuelles en local : il faut compter sur la CI (acceptable, c'est aussi
  le rôle de la CI).
- Si un dev modifie un widget et veut prévisualiser le golden localement,
  il doit soit (a) push et lancer le workflow, soit (b) lancer un
  conteneur Docker Linux. Documenter dans le README test.
- Le workflow `update-goldens` requiert `permissions: contents: write` —
  vérifier que la policy GitHub du repo l'autorise.

### Migration immédiate (PR #15)
1. Merger ce changement sur la branche `feat/phase-1-mobile-setup`.
2. Déclencher `Update Goldens` workflow → `branch =
   feat/phase-1-mobile-setup`.
3. Le workflow regénère les 8 PNG sous Linux et les push.
4. La CI principale repasse au vert.

## Références
- PR #15 — première occurrence du problème.
- `.github/workflows/update-goldens.yml` — implémentation.
- `test/flutter_test_config.dart` — comparator bypass.
- ADR-001 — Clean Architecture (contexte général qualité).
