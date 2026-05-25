# Design tokens — Murabbi mobile

> Source de vérité côté code : `lib/presentation/theme/app_spacing.dart` (et `app_colors.dart`, `app_typography.dart`).
> Source de vérité côté design : `docs/wireframes/bundle/design-system-sheet.jsx`.
>
> Ce document recense les contrats de tokens **publiés** (utilisables dans toute l'UI) et la
> **rationale** qui les sous-tend. Toute valeur littérale (hex, px, sp) hors token dans
> `lib/presentation/` est interdite (P-2, P-5, Q-5).

---

## Épaisseurs de trait — `AppBorderWidth`

**Décision PO Option A (issue #28)** : grammaire **ternaire volontaire**. Trois épaisseurs
sémantiques distinctes couvrent toutes les surfaces de l'app. Aucune autre valeur n'est admise.

| Token | Valeur | Usage |
|---|:---:|---|
| `AppBorderWidth.thin` | `0.5` | Bordures fines, séparateurs, cartes, bottom-nav, headers, chips, toggles. |
| `AppBorderWidth.focusRing` | `1.5` | Anneau de focus accessibilité (états focused des inputs / boutons). |
| `AppBorderWidth.indicatorStroke` | `2.0` | Indicateurs d'état : `CircularProgressIndicator`, arcs de progression Salat (slice 3.C.3 countdown next-prayer). |

### Rationale

- **`thin = 0.5`** matérialise l'esthétique "carnet Moleskine numérisé" du CLAUDE.md
  (P-5 — bordures fines partout, pas d'ombre portée).
- **`focusRing = 1.5`** doit être perceptible mais pas envahissant ; valeur calibrée pendant
  Phase 2 sur l'audit a11y (cf. `widgets_a11y_test.dart`).
- **`indicatorStroke = 2.0`** réservé aux **éléments dynamiques** : c'est ce qui distingue
  un trait stable (0.5) d'un signal mouvant (loader, arc de countdown). Sans cette distinction,
  les arcs Salat slice 3.C.3 auraient hérité d'un `2.0` hardcodé (cf. AT-4 audit Phase 2).

### Anti-pattern

```dart
// ❌ Interdit — magic number
CircularProgressIndicator(strokeWidth: 2)
Border.all(width: 0.5)

// ✅ Token sémantique
CircularProgressIndicator(strokeWidth: AppBorderWidth.indicatorStroke)
Border.all(width: AppBorderWidth.thin)
```

### Anti-régression

`test/presentation/theme/app_spacing_test.dart` asserte les trois valeurs.
`test/presentation/features/splash/splash_screen_test.dart` vérifie que le splash spinner
consomme bien le token (et non une valeur littérale).

**Garde-fou CI `avoid_literal_stroke_width`** (issue #32, ADR-017) :
le script `tool/check_stroke_width.dart` interdit tout `strokeWidth: <nombre
littéral>` dans `lib/`. Il suggère le token `AppBorderWidth` le plus proche du
littéral fautif et fait échouer la CI (exit code 1) en cas de violation.

```bash
# Lancer manuellement / en pré-commit (zéro dépendance, dart:io only)
dart run tool/check_stroke_width.dart
```

Périmètre : `lib/` uniquement — `test/` est toléré (golden tests, comparaisons
numériques). Les déclarations de paramètre des widgets custom
(`AppProgressRing.strokeWidth`) ne sont pas concernées : seules les valeurs
hardcodées côté call-site le sont. Le choix d'un script CI plutôt que d'un
plugin `custom_lint` est justifié dans `docs/adr/ADR-017-lint-stroke-width-ci-script.md`.

---

## Voir aussi

- `AppSpacing` — grille 4px (s1..s8). Tests : même fichier.
- `AppRadius` — `chip` (6) / `button` (10) / `card` (16) / `pill` (100).
- `AppColors` — palette terreuse, source `app_colors.dart`.
- `AppTypography` — Geist + Geist Mono + Noto Sans Arabic.
