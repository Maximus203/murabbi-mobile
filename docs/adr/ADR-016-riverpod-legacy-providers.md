# ADR-016 — Riverpod : providers legacy (manuels) plutôt que codegen `@riverpod`

**Statut** : Accepté · 2026-05-14
**Slice associée** : Issue #49 (suivi CP PR #43)
**Référence dette** : ADR-015 §Dette suivie, audit TL §B.2 PR #41 + PR #43.

## Contexte

Le CLAUDE.md §5 stipule :

> **Toujours utiliser `@riverpod` avec génération de code.**

Mais la **réalité du repo** Murabbi mobile à 2026-05-14 :

| Provider | Pattern utilisé | Localisation |
|---|---|---|
| `authNotifierProvider` | `AsyncNotifierProvider` manuel | `auth_notifier.dart` |
| `onboardingNotifierProvider` | `AsyncNotifierProvider` manuel | `onboarding_notifier.dart` |
| `todaySalatNotifierProvider` | `AsyncNotifierProvider` manuel | `today_salat_notifier.dart` |
| `prayerSettingsFormNotifierProvider` | `NotifierProvider` manuel | `prayer_settings_form_notifier.dart` |
| `rememberedAccountsNotifierProvider` | `AsyncNotifierProvider` manuel | `remembered_accounts_notifier.dart` |
| `dashboardNotifierProvider` | `AsyncNotifierProvider` manuel | `dashboard_notifier.dart` |
| `habitsNotifierProvider` | `AsyncNotifierProvider` manuel | `habits_notifier.dart` |
| `prayerDetailNotifierProvider` | `AsyncNotifierProvider.family` manuel | `prayer_detail_notifier.dart` |
| ~30 `Provider<T>` divers | API legacy | `*_provider.dart`, `*_use_case_providers.dart` |
| `dashboardTickerProvider` | `StreamProvider.autoDispose` | `dashboard_ticker_provider.dart` |
| `prayerTimesServiceProvider` etc. | `Provider<T>` legacy | `prayer_times_provider.dart` |

**100 % du code écrit utilise l'API legacy.** `riverpod_generator` et `build_runner` sont déclarés en `dev_dependencies` mais aucun fichier `.g.dart` n'a jamais été généré, aucun fichier de production n'a l'annotation `@riverpod`.

Le statu quo (doctrine ≠ pratique) est intenable :
- chaque nouvelle PR doit re-arbitrer le pattern ;
- les nouveaux contributeurs reçoivent un signal contradictoire (CLAUDE.md vs code) ;
- des audits TL successifs ont signalé la dette (PR #41 ADR-015 §Dette, PR #43 suivi CP §3).

## Options

### Option A — Migration en masse vers `@riverpod` codegen

Convertir l'intégralité des providers existants vers l'annotation `@riverpod` + génération `.g.dart`. Ajouter une étape `dart run build_runner build --delete-conflicting-outputs` dans la CI avant `flutter analyze`/`flutter test`.

**Avantages**
- Cohérence stricte avec CLAUDE.md §5.
- Typage `Ref` automatique (le compilateur infère la classe `XxxRef` à partir de l'annotation).
- Outillage Riverpod (devtools, lint package `riverpod_lint`) plus efficace sur le code annoté.

**Inconvénients**
- ~40 fichiers de production à modifier, ~50 fichiers de tests à ré-aligner.
- Étape `build_runner` obligatoire avant chaque `flutter analyze`/`flutter test`/`flutter build` → CI plus lente (~30s), boucle dev plus lente.
- Fichiers `.g.dart` générés à versionner OU à `.gitignore` + générer en CI (les deux options ont leurs travers).
- Risque de régression sur ~20 PR concurrentes en attente (#38, #41, #42, #43, #45, #46, #51, #52, #53) → rebase massif.

### Option B — Acceptation explicite du pattern legacy + amendement CLAUDE.md

Acter formellement que **Murabbi mobile utilise les providers Riverpod manuels** (`Provider<T>`, `NotifierProvider`, `AsyncNotifierProvider`, `StreamProvider`, `FutureProvider`). Mettre à jour CLAUDE.md §5 en conséquence. Retirer `riverpod_generator` + `build_runner` des `dev_dependencies` (devenus morts).

**Avantages**
- Zéro changement de code (alignement doctrine sur la réalité).
- Boucle dev rapide (pas de codegen).
- Le typage `Ref` est déjà obtenu via la déclaration explicite `AsyncNotifier<T>` qui force la signature.
- Cohérence immédiate sur toutes les PR en flight.

**Inconvénients**
- Les outils Riverpod custom (`riverpod_lint` annotations, devtools timeline) sont sous-optimaux sans codegen.
- Si l'écosystème Flutter bascule à fond sur `@riverpod` à 6 mois, on devra migrer plus tard avec un coût équivalent à l'option A.

## Décision

**Option B retenue** — providers legacy manuels.

**Justifications senior** :
1. **Tous les notifiers actuels sont déjà bien typés** : `class XxxNotifier extends AsyncNotifier<T>` exprime la signature de manière statique, le codegen n'apporte pas de garantie supplémentaire.
2. **La boucle dev rapide est un asset critique** pour un projet à ce stade (TDD strict + 750 tests : `build_runner` ajouterait ~30 s × N fois par jour).
3. **Aucun blocker écosystème** : Riverpod 2.x continuera de supporter l'API legacy au moins jusqu'en 4.x (cf. roadmap public).
4. **Cohérence immédiate** : zéro PR à rebaser, l'équipe ne paie pas la dette tout de suite.
5. **Réversibilité** : si on bascule à 6 mois, le coût est le même qu'aujourd'hui (~1 PR dédiée), sans urgence.

## Conséquences

### Action immédiate

- ✅ **Cet ADR-016** crée.
- 🔧 **Amender CLAUDE.md §5** — remplacer « Toujours utiliser `@riverpod` avec génération de code » par : *« Utiliser les providers Riverpod legacy manuels (`Provider`, `NotifierProvider`, `AsyncNotifierProvider`, `StreamProvider`, `FutureProvider`). Cf. ADR-016. »*
- 🧹 **Retirer `riverpod_generator` + `build_runner`** de `pubspec.yaml dev_dependencies` (deps mortes — aucune ligne du repo ne les utilise). Allègera `flutter pub get`.

### Long terme

- Re-ouvrir un ADR-XXX si l'écosystème Flutter/Riverpod casse l'API legacy ou si un besoin de tooling devtools-timeline-Riverpod émerge.
- Aucun TODO `@riverpod` ne devrait apparaître dans les commits / commentaires futurs.

### Aucun changement de code requis

L'ADR ne casse rien : tous les providers actuels (~40 fichiers) sont déjà conformes au pattern accepté. Les futures PR continuent simplement de suivre le pattern existant — pas d'effort de migration.

## Lien avec les ADRs précédents

- **ADR-015** (Remembered accounts, PR #41) §Dette suivie : référence cette dette. Désormais close par cet ADR.
- **ADR-002** (Riverpod codegen) — précédent ADR qui défendait le codegen côté Phase 0. **Cet ADR-016 prend le pas** (date plus récente + retour d'expérience après 6 slices livrées en legacy).
