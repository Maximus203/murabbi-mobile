# Audit conformité design — Phase 2 mobile

> **Date** : 2026-05-09
> **Auteur** : Architecte/dev senior (review statique)
> **Scope** : 6 écrans Phase 2 (splash + onboarding 4 slides + 4 écrans auth)
> **Référentiel** : règles produit P-1 à P-8 du `CLAUDE.md` racine § A.3.3
> **Méthode** : lecture statique du code Dart + grep tokens + revue des golden tests existants. Pas de run UI (les goldens sont déjà couverts ailleurs).

---

## 0. Périmètre

| ID | Écran | Fichier |
|---|---|---|
| OB-01 | Splash | `lib/presentation/features/splash/screens/splash_screen.dart` |
| SETUP-01 | Onboarding 4 slides walkthrough | `lib/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart` |
| AU-01 | Connexion | `lib/presentation/features/auth/screens/au_01_login_screen.dart` |
| AU-02 | Inscription | `lib/presentation/features/auth/screens/au_02_signup_screen.dart` |
| AU-03 | Mot de passe oublié | `lib/presentation/features/auth/screens/au_03_forgot_password_screen.dart` |
| AU-04 | Vérification email + gate | `lib/presentation/features/auth/screens/au_04_email_verification_screen.dart` + `au_04_email_verification_gate.dart` |

Widgets partagés vérifiés en transverse : `AppButton`, `AppInput`, `AppHeader`, `AuthErrorBanner`, tokens `AppColors` / `AppSpacing` / `AppTypography` / `AppBorderWidth` / `AppRadius`.

---

## 1. Synthèse — Tableau de scoring

Légende sévérité : 🔴 bloquant · 🟠 majeur · 🟡 mineur · 🔵 observation.

| Règle | OB-01 | SETUP-01 | AU-01 | AU-02 | AU-03 | AU-04 | Sévérité agrégée |
|---|---|---|---|---|---|---|---|
| **P-1** Aucun emoji | OK | OK | OK | OK | OK | OK | — |
| **P-2** Palette terreuse (zéro hex hors `AppColors`) | OK | OK | OK | OK | OK | OK | — |
| **P-3** Typographie Geist + Noto Sans Arabic | OK¹ | OK¹ | OK¹ | OK¹ | OK¹ | OK¹ | 🟡 dette TTF |
| **P-4** Mode clair par défaut | OK | OK | OK | OK | OK | OK | — |
| **P-5** Bordures 0.5px, focus 1.5px, pas d'ombre | OK | OK | OK | OK | OK | OK | 🔵 stroke loader |
| **P-6** 1 seul CTA primaire par écran | OK² | OK | OK | OK | 🟡 | OK | 🟡 |
| **P-7** Notifications respectueuses | N/A | N/A | N/A | N/A | N/A | N/A | — |
| **P-8** Pas de gamification agressive | OK | OK | OK | OK | OK | OK | — |

¹ Conforme **par construction** : 100 % des `Text` passent par `AppTypography.*` qui pointe `Geist` / `Geist Mono` / `Noto Sans Arabic`. Lock test [`app_typography_test.dart:39-61`](test/presentation/theme/app_typography_test.dart) verrouille les `fontFamily`. Dette : les TTFs ne sont **pas encore bundlés** (`pubspec.yaml > flutter.fonts` vide) — Flutter retombe sur la police système. Voir item AT-1.
² OB-01 (splash) n'expose aucun CTA — non concerné par P-6.

**Comptage des écarts** : 0 🔴 · 0 🟠 · **3 🟡** · **2 🔵**.

**Verdict global** : Phase 2 est **conforme** aux 8 règles produit. La dette principale est la non-distribution des polices Geist (P-3 partiel runtime), à régler en Phase 1.x quand les TTFs seront livrés par le PO. Aucun blocage merge.

---

## 2. Détail par règle

### P-1 — Aucun emoji dans l'UI

**Méthode** : grep regex `[\u{1F300}-\u{1F9FF}]|🌙|✨|emoji` sur `lib/presentation/features/{splash,onboarding,auth}/**`.

**Résultat** : 0 match. Tous les pictogrammes sont des `IconData` Lucide (`LucideIcons.mailCheck`, `LucideIcons.mapPin`, `LucideIcons.calculator`, `LucideIcons.clock`, `LucideIcons.circleCheck`, `LucideIcons.mail`, `LucideIcons.lock`).

**Caractères unicode non-emoji détectés** (acceptés par P-1) :
- `'Bismi-Llāh'` ([splash_screen.dart:27](lib/presentation/features/splash/screens/splash_screen.dart:27)) — translittération arabe.
- Apostrophes typographiques `’` et points de suspension `…` dans les copys FR — typographie standard, pas un emoji.

**Conclusion** : ✅ conforme.

---

### P-2 — Palette terreuse / aucune couleur hex hors design system

**Méthode** : grep regex `0x[0-9A-Fa-f]{6,8}|Color\(0x|Colors\.[a-z]+` sur les 6 écrans + widgets référencés.

**Résultat sur les 6 écrans** : 0 match hex. Tous les `Color` proviennent de `AppColors.*` (`bgPrimary`, `bgSurface`, `bgInput`, `accent`, `success`, `danger`, `borderDefault`, `borderEmphasis`, `textPrimary`, `textSecondary`, `textTertiary`).

**Cas marginal détecté dans `app_button.dart`** : usage de `Colors.transparent` pour les variantes `ghost` et `link` ([app_button.dart:81](lib/presentation/widgets/app_button.dart:81), [app_button.dart:93](lib/presentation/widgets/app_button.dart:93)). C'est conforme à l'esprit de P-2 (transparent n'est pas une couleur d'identité visuelle), mais à terme un token `AppColors.transparent` clarifierait la traçabilité du DS.

**Conclusion** : ✅ conforme. AppColors est la seule source de vérité hex pour les 6 écrans. Aucun écart sur la palette terreuse.

---

### P-3 — Typographie Geist + Noto Sans Arabic uniquement

**Méthode** : grep regex `TextStyle\(|fontFamily:` sur les 6 écrans (hors imports/AppTypography).

**Résultat** : aucune instanciation directe de `TextStyle` dans les 6 écrans Phase 2. Tous les `Text(...)` utilisent `AppTypography.{h1|h2|h3|body|caption|label|arabic|mono|display}` (parfois `.copyWith(color: ...)` ce qui préserve la `fontFamily` du base style).

**Verrouillage runtime** : `test/presentation/theme/app_typography_test.dart` lock les `fontFamily` à `'Geist'`, `'Geist Mono'`, `'Noto Sans Arabic'` ([lignes 39-61](test/presentation/theme/app_typography_test.dart:39)). Ce test bloque toute régression silencieuse vers `Roboto` / `SF Pro` / system font *au niveau de la classe `AppTypography`*.

**Limites du verrou actuel** :
- Le test ne couvre **pas** une régression future où un dev introduirait un `TextStyle(...)` brut dans un nouvel écran. Pas de lint custom qui interdit `TextStyle(` hors de `lib/presentation/theme/`.
- Les TTFs **Geist + Geist Mono + Noto Sans Arabic** ne sont **pas** déclarés dans `pubspec.yaml > flutter.fonts` (vérifié — section `fonts:` absente). Conséquence : à runtime, Flutter ne trouve pas la famille `'Geist'` et tombe sur la police système (Roboto Android / SF Pro iOS). Les tailles, poids, tracking sont honorés ; le **glyphe** est faux. Documenté explicitement dans [app_typography.dart:10-14](lib/presentation/theme/app_typography.dart:10).

**Conclusion** : ✅ structurellement conforme (code 100 % sur `AppTypography`), 🟡 **dette runtime** sur les TTFs à régler. Voir AT-1.

---

### P-4 — Mode clair par défaut

**Méthode** : grep `Brightness\.dark|ThemeMode\.dark|brightness:` sur les 6 écrans + `Theme.of(context).brightness` forçage.

**Résultat** : 0 match. Aucun `Scaffold` ne force un thème sombre. Tous les fonds : `backgroundColor: AppColors.bgPrimary` (sable clair `#F5F2ED`) ou `AppColors.bgSurface` pour les bannières internes.

Le thème global (`AppTheme.light()`) est appliqué par `MurabbiApp` en racine, et aucun écran Phase 2 ne fait de surcharge `Theme(` locale.

**Conclusion** : ✅ conforme.

---

### P-5 — Bordures 0.5px, focus 1.5px, pas d'ombre portée

**Méthode** : grep `BoxShadow|elevation:|shadow:` sur les 6 écrans.

**Résultat** : 0 `BoxShadow`, 0 `elevation` non-nulle. Toutes les `Container` décorées utilisent `Border.all(width: AppBorderWidth.hairline)` (0.5px) ou `AppBorderWidth.focusRing` (1.5px) :
- [setup_01_onboarding_screen.dart:181](lib/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart:181) — cercle d'icône slide
- [au_03_forgot_password_screen.dart:122](lib/presentation/features/auth/screens/au_03_forgot_password_screen.dart:122) — bannière succès
- [au_04_email_verification_screen.dart:148](lib/presentation/features/auth/screens/au_04_email_verification_screen.dart:148) — illustration mail
- [au_04_email_verification_screen.dart:175](lib/presentation/features/auth/screens/au_04_email_verification_screen.dart:175) — bannière "renvoyé"
- [app_button.dart:49](lib/presentation/widgets/app_button.dart:49) — bordures bouton

`AppHeader` (vérifié séparément) n'utilise pas non plus d'`elevation` — c'est un `AppBar` plat conforme.

**Cas marginal observé** :
- 🔵 [splash_screen.dart:37](lib/presentation/features/splash/screens/splash_screen.dart:37) — `CircularProgressIndicator(strokeWidth: 2)`. C'est l'épaisseur du **trait du loader**, pas une bordure d'élément UI. P-5 vise les bordures et ombres de containers, pas le stroke d'un widget Material. Pas un écart, juste à noter pour cohérence si on voulait un loader hairline.

**Conclusion** : ✅ conforme. 🔵 observation cosmétique sur le stroke du loader splash.

---

### P-6 — Un seul CTA primaire par écran

**Méthode** : compter les `AppButton(...)` sans `variant:` (= primary par défaut) par écran. Recompter en distinguant les **vues alternatives** (état succès vs formulaire) car elles ne sont jamais visibles simultanément.

| Écran | Vue | `AppButton` primary count | `AppButton` autres | Détail |
|---|---|---|---|---|
| OB-01 splash | unique | **0** | 0 | `CircularProgressIndicator` seul |
| SETUP-01 | unique | **1** | 0 | `_isLast ? 'Commencer' : 'Suivant'` ([l.121](lib/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart:121)). `_TopBar.Passer` est un `TextButton` (link), pas un AppButton |
| AU-01 login | unique | **1** | 1 ghost | "Se connecter" primary ([l.108](lib/presentation/features/auth/screens/au_01_login_screen.dart:108)), "Continuer avec Google" `variant: ghost` ([l.113](lib/presentation/features/auth/screens/au_01_login_screen.dart:113)). Liens "Mot de passe oublié ?" et "Créer un compte" sont des `TextButton` (link) |
| AU-02 signup | unique | **1** | 1 ghost | "Créer mon compte" primary ([l.99](lib/presentation/features/auth/screens/au_02_signup_screen.dart:99)), "Continuer avec Google" ghost ([l.104](lib/presentation/features/auth/screens/au_02_signup_screen.dart:104)) |
| AU-03 forgot | form | **1** | 0 | "Envoyer le lien" primary ([l.95](lib/presentation/features/auth/screens/au_03_forgot_password_screen.dart:95)) |
| AU-03 forgot | success | **1** | 0 | "Retour à la connexion" primary ([l.152](lib/presentation/features/auth/screens/au_03_forgot_password_screen.dart:152)) |
| AU-04 email verif | unique | **1** | 1 ghost | "J'ai vérifié mon email" primary ([l.108](lib/presentation/features/auth/screens/au_04_email_verification_screen.dart:108)), "Renvoyer l'email" ghost ([l.113](lib/presentation/features/auth/screens/au_04_email_verification_screen.dart:113)). "Changer d'adresse" est un `TextButton` |

**Observation 🟡** :
- **AU-03 vue "success"** : le seul AppButton est primary par défaut — c'est sémantiquement un "retour" (ce n'est pas l'action principale d'un écran de réinitialisation). Conforme P-6 (1 seul primary), mais on pourrait s'interroger si "Retour à la connexion" mérite la variante `secondary` plutôt que `primary` après un succès. **Recommandation** : conserver tel quel — c'est la seule action proposée donc elle mérite le poids visuel d'un primary. Pas un écart.

**Conclusion** : ✅ conforme. 🟡 observation stylistique sur AU-03 success view (pas d'action requise).

---

### P-7 — Notifications respectueuses

**N/A pour Phase 2.** Les notifications (`flutter_local_notifications` + FCM) arrivent en Phase 6. Aucune logique de scheduling de notif dans les 6 écrans audités.

**Conclusion** : N/A.

---

### P-8 — Pas de gamification agressive

**Méthode** : revue des copys et des animations.

**Résultat** : copys sobres ("Tout est prêt", "Bonne route, ya Murabbi", "Lien envoyé", "Email renvoyé. Vérifie ta boîte (et les spams).", "Pense à vérifier les spams."). Aucune mention de "streak", "niveau", "badge", "score", "récompense" dans les 6 écrans Phase 2 — cohérent avec le périmètre auth/onboarding qui précède la gamification scoring (Phase 4).

Animations détectées :
- `_DotsIndicator` `AnimatedContainer` 200ms ([setup_01_onboarding_screen.dart:214](lib/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart:214)) — transition de l'indicateur de page actif. Sobre.
- `PageView` `nextPage` 250ms easeOut ([setup_01_onboarding_screen.dart:88](lib/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart:88)) — slide entre étapes. Sobre.

Aucun confetti, aucun `flutter_animate` lottie, aucune célébration excessive. Pas de "streak panic" : aucun écran ne menace l'utilisateur de perte d'engagement.

**Conclusion** : ✅ conforme.

---

## 3. Top 5 actions à traiter

Classement par priorité produit/dette technique (du plus impactant au plus cosmétique).

### 🟡 AT-1 — Distribuer les TTFs Geist + Geist Mono + Noto Sans Arabic

**Sévérité** : mineure (P-3 partiel runtime).
**Impact** : tous les écrans, pas seulement Phase 2.
**Action** :
1. Le PO fournit les 6 TTFs : `Geist-Regular.ttf`, `Geist-Medium.ttf`, `Geist-SemiBold.ttf`, `GeistMono-Regular.ttf`, `GeistMono-Medium.ttf`, `NotoSansArabic-Medium.ttf`.
2. Bundler dans `assets/fonts/` + déclarer dans `pubspec.yaml > flutter.fonts`.
3. Ajouter un test golden léger sur `splash_screen` qui compare le rendu avec/sans TTF en CI Linux uniquement (cf. ADR-010 goldens-linux-only).

**Quand** : avant Phase 5 polish. Pas bloquant Phase 3.

### 🟡 AT-2 — Lint custom interdire `TextStyle(` hors `lib/presentation/theme/`

**Sévérité** : mineure (anti-régression P-3).
**Action** : ajouter une règle `analysis_options.yaml` custom (ou un test de scan AST) qui rejette `TextStyle(` dans tout fichier non situé sous `lib/presentation/theme/`. Le verrou actuel `app_typography_test.dart` ne couvre que la classe — pas les usages futurs.

**Quand** : opportuniste, paire avec une PR design.

### 🟡 AT-3 — Token `AppColors.transparent`

**Sévérité** : mineure (anti-régression P-2).
**Action** : ajouter `static const Color transparent = Colors.transparent;` dans `AppColors` et remplacer les 2 `Colors.transparent` de `AppButton` par le token. Aligne 100 % de la palette sur `AppColors`.

**Quand** : opportuniste, ~5 minutes.

### 🔵 AT-4 — `strokeWidth` du loader splash via `AppBorderWidth`

**Sévérité** : observation, non régression.
**Action** : remplacer `strokeWidth: 2` par une constante `AppBorderWidth.loaderStroke = 2.0` ou réutiliser `AppBorderWidth.focusRing = 1.5`. Cohérence DS vs lecture explicite.

**Quand** : opportuniste, paire AT-3.

### 🔵 AT-5 — Validation accessibilité tap targets sur `_TopBar.Passer`

**Sévérité** : observation hors P-1..P-8 (mais pertinent qualité produit).
**Action** : `TextButton` "Passer" dans le SETUP-01 a une hauteur effective de ~36px (`MaterialTextButton` default). En dessous des 44px iOS / 48dp Android Material. À vérifier en widget test ou augmenter `padding` pour atteindre la cible WCAG 2.5.5.

**Quand** : Phase 5 polish.

---

## 4. Annexe — Vérifications de provenance

### A. Comptage de couverture

```
Écrans Phase 2 audités : 6 / 6
Widgets partagés revus : 4 (AppButton, AppInput, AppHeader, AuthErrorBanner)
Tokens revus : 5 (AppColors, AppSpacing, AppTypography, AppBorderWidth, AppRadius)
Lock tests vérifiés : 1 (app_typography_test.dart)
```

### B. Greps exécutés

| Pattern | Cible | Résultat |
|---|---|---|
| `[\u{1F300}-\u{1F9FF}]\|emoji\|🌙\|✨` | `lib/presentation/features/{splash,onboarding,auth}` | 0 match |
| `0x[0-9A-Fa-f]{6,8}` | idem | 0 match |
| `BoxShadow\|elevation:\|brightness\|Brightness\.dark` | idem | 0 match |
| `TextStyle\(` (hors theme) | idem | 0 match |
| `AppButton\(` (sans variant) | idem | 7 matches → 7 primary, distribution conforme P-6 |

### C. Référentiel

- `CLAUDE.md` racine § A.3.3 (P-1 à P-8) — version au commit `pensive-goldberg-9d8ded`.
- `CLAUDE.md` mobile § 4-6 (architecture, stack, règles code).
- `lib/presentation/theme/app_*.dart` — tokens DS source de vérité.
- `test/presentation/theme/app_typography_test.dart` — verrou runtime fontFamily.

---

*Audit clos. Phase 2 mobile validée vis-à-vis des règles P-1 à P-8 sous réserve de la dette TTF (AT-1) à régler avant la release Phase 5.*
