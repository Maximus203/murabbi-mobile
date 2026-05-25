# ADR-013 — Stratégie de calcul des horaires de prière

**Statut** : Accepté
**Date** : 2026-05-09
**Décideur** : Cherif (PO) + agent senior
**Lié** : ADR-001 (clean archi), ADR-004 (Supabase datasource), ADR-005 (offline cache), Q-19 (salat status mapping), Phase 3 slice 3.C, recherche `docs/architecture/prayer-times-strategy-research-2026-05-09.md`

## Contexte

La slice 3.C (Phase 3) doit afficher les 5 horaires de prière du jour à
l'utilisateur et permettre au tracker Salat (slice 3.B) de qualifier
automatiquement le statut d'une prière (`onTime` / `late` / `missed`)
en fonction de l'heure réelle vs l'heure attendue. Aucune décision
n'avait encore été prise sur **comment** ces horaires sont calculés —
deux familles de solutions étaient sur la table : appel à une API tiers
(Aladhan) ou calcul 100% local via une lib client.

La recherche tech `prayer-times-strategy-research-2026-05-09.md`
(2026-05-09) a documenté en détail les méthodes astronomiques, les
libs disponibles, les pratiques des apps de référence (Pillars,
Muslim Pro, Athan Pro) et les contraintes Murabbi (offline-first,
RGPD, sobriété, audience francophone/maghrébine). Cet ADR
**capitalise** cette recherche en décision architecturale opposable
avant que la slice 3.C ne commence à coder.

## Décision

**Calcul 100% local on-device via la lib Dart `adhan_dart` v2.0.0**
(port MIT du repo upstream `batoulapps/adhan-js`). **Aucun appel
réseau en runtime pour les horaires.** L'API Aladhan reste utilisée
**uniquement** comme oracle de validation dans les tests
(golden values cross-check), jamais en production.

Quatre sous-décisions verrouillées avec le PO le 2026-05-09 :

### 1. Solution technique — `adhan_dart` local, pas d'API runtime

- Lib retenue : `adhan_dart` v2.0.0 (pub.dev, MIT, port fidèle de
  `adhan-js` Batoul Apps qui est la référence open-source du domaine).
- Calcul on-device basé sur les équations astronomiques de
  Jean Meeus (précision sub-minute).
- Pas de dépendance réseau pour calculer les horaires → offline-first
  par construction, mode avion natif, pas de fuite GPS vers un tiers.
- Aladhan API n'est **pas** un fallback runtime. Elle sert uniquement
  d'oracle dans les tests (`test/services/prayer_times_service_test.dart`)
  pour vérifier qu'on retombe bien sur les mêmes valeurs que la
  référence externe.
- Précédent : Pillars (TPA) applique exactement la même stratégie et
  l'utilise comme argument privacy.

### 2. Méthode de calcul — pré-remplissage intelligent par pays, fallback MWL

- Au premier lancement (post-onboarding, après que la localisation ou
  le pays manuel est connu), l'app sélectionne automatiquement la
  méthode officielle locale :

  | Pays détecté | Méthode pré-remplie |
  |---|---|
  | FR | UOIF (Fajr 12° / Isha 12°) |
  | MA | Morocco (Habous) |
  | DZ | Algeria |
  | TN | Tunisia |
  | EG | Egyptian General Authority |
  | SA | Umm al-Qura |
  | AE | Dubai |
  | KW | Kuwait |
  | QA | Qatar |
  | TR | Turkey (Diyanet) |
  | PK / IN / BD | University of Karachi |
  | SG / MY / ID | Singapore (MUIS) |
  | IR | Tehran |
  | US / CA | ISNA (par défaut, l'utilisateur peut switcher en Moonsighting) |
  | _autre / inconnu_ | **MWL** (fallback global) |

- L'utilisateur peut **toujours** modifier la méthode dans les
  settings après le premier lancement. La table de mapping ci-dessus
  n'est qu'un défaut intelligent.
- Rationale : Murabbi cible francophones / maghrébins en priorité —
  proposer MWL global par défaut serait factuellement faux pour ces
  audiences (UOIF / Morocco diffèrent significativement). Le
  pré-remplissage évite à 80% des utilisateurs d'avoir à toucher aux
  settings.

### 3. Madhab — Shafi par défaut, configurable, pas de détection auto

- Madhab par défaut : **Shafi** (majoritaire global, règle Asr
  ombre = 1× hauteur).
- L'utilisateur peut switcher en **Hanafi** (Asr ombre = 2× hauteur)
  via les settings. Un musulman hanafi (TR / PK / IN / BD / AF
  notamment) sait s'il est hanafi — un toggle suffit.
- **Pas de détection automatique du madhab par pays.** Un Pakistanais
  installé en France peut être Shafi, un Français peut être Hanafi.
  Détecter le madhab par pays produit plus de faux positifs que de
  vrais. Simplicité V1 > sophistication.
- `adhan_dart` expose nativement `Madhab.shafi | Madhab.hanafi` — c'est
  la seule différence inter-madhab dans le calcul des horaires.

### 4. Override manuel ±N min par prière — différé V2

- En **V1**, les horaires affichés sont strictement ceux calculés par
  `adhan_dart` à partir de `(coords, date, méthode, madhab,
  high-latitude rule)`. Pas d'offset utilisateur.
- En **V2**, on ajoutera un champ `manualOffsets: Map<Prayer, int>`
  (en minutes) sur `PrayerSettings` pour permettre le calage sur la
  mosquée locale (ex: "ma jamaa fait Fajr +3 min vs le calcul
  astronomique"). Ce besoin est réel (cf. Muslim Pro, Athan Pro)
  mais ajoute de la surface settings non critique pour le tracker.
- Conséquence V1 : la documentation in-app indiquera explicitement
  "Murabbi calcule les horaires selon la méthode X. Si votre mosquée
  applique un décalage local, ajustez la méthode dans les
  paramètres." pour gérer la friction perçue.

## Conséquences

### Positives

- **Offline-first natif** : zéro appel réseau pour la feature centrale
  Salat. L'app fonctionne en métro, à l'étranger, en mode avion.
- **Privacy-first / RGPD** : les coordonnées GPS de l'utilisateur ne
  quittent jamais l'appareil. Argument fort pour un repo public OSS
  et un audit RGPD propre (cf. C-3, C-4 CLAUDE.md racine).
- **Coût zéro** : pas d'abonnement API, pas de quota à monitorer, pas
  de risque de dépréciation tiers.
- **Précision astronomique sub-minute** : équations Meeus, identique à
  ce que ferait Aladhan API.
- **UX immédiate** : pré-remplissage par pays → l'utilisateur
  francophone / maghrébin n'a rien à configurer pour avoir des
  horaires corrects.
- **Bonus features futures** : `adhan_dart` fournit aussi `qibla`,
  `sunnah times` (last third of night), `sunrise` — réutilisables
  hors slice 3.C sans dépendance supplémentaire.

### Négatives / risques

- **Dépendance à une lib OSS** (`adhan_dart`, 1 mainteneur principal,
  104 stars, v1.2.0). Mitigation : la lib est un port direct de
  `adhan-js` (upstream Batoul Apps, très active). On isole l'import
  dans un seul fichier `services/prayer/prayer_times_service.dart`
  pour pouvoir swap trivialement si besoin.
- **Override manuel reporté V2** : certains utilisateurs alignés sur
  leur mosquée locale percevront une dérive de 1–3 min. Mitigation :
  documentation in-app + roadmap V2 explicite.
- **Pas de détection madhab auto** : un musulman hanafi non averti
  verra Asr "trop tôt" tant qu'il ne change pas le réglage. Mitigation :
  le screen settings prière met le toggle Madhab en évidence et
  explique brièvement la différence.

### Limites identifiées

- **Hautes latitudes (>55°)** — Oslo, Stockholm, Reykjavik, Nord
  Canada : certaines nuits Fajr/Isha n'existent pas astronomiquement.
  `adhan_dart` gère via 3 high-latitude rules (Middle of Night /
  Seventh of Night / Twilight Angle). À exposer dans les settings
  prière (slice 3.C.1) et tester avec dates extrêmes (juin/décembre
  Oslo) en widget tests. La méthode "Moonsighting Committee"
  applique la règle 1/7 automatiquement >55° et reste un défaut
  robuste pour cette audience.
- **UOIF (France)** : à valider que `adhan_dart` expose UOIF
  nativement comme méthode prédéfinie. Si non disponible directement,
  utiliser la méthode "Other" avec params custom (Fajr 12° / Isha 12°)
  documentés en code. À vérifier au début de slice 3.C.2.
- **Méthodes Morocco / Algeria / Tunisia** : idem — exhaustivité à
  valider lors de l'implé. `adhan-js` upstream les expose ; le port
  Dart devrait suivre, mais snapshot la version à 1.2.0 et vérifier.
- **Changement d'heure été/hiver (DST)** : `adhan_dart` calcule en UTC,
  on convertit avec le timezone de l'appareil. Tester explicitement
  les transitions DST en widget tests pour éviter une dérive d'1h
  silencieuse.
- **Permission de localisation refusée** : bloque la feature si pas
  de fallback. Mitigation : fallback ville manuelle obligatoire dans
  l'onboarding settings prière (sélecteur pays/ville en dur ou via
  geocoding one-shot — à arbitrer en slice 3.C.1).

## Architecture proposée (slice 3.C)

Schéma de référence pour les sous-agents qui implémenteront la slice.
Respecte ADR-001 (clean archi) et ADR-002 (Riverpod codegen).

```
presentation/features/salat/
  ├── screens/
  │   ├── salat_screen.dart             // déjà existant (slice 3.A)
  │   └── prayer_settings_screen.dart   // nouveau (slice 3.C.1)
  ├── providers/
  │   ├── prayer_times_provider.dart    // codegen — horaires du jour
  │   ├── next_prayer_provider.dart     // codegen — prochaine prière
  │   └── prayer_settings_provider.dart // codegen — settings utilisateur
  └── widgets/
      └── prayer_card.dart

domain/
  ├── entities/
  │   ├── prayer_day.dart               // déjà existant (slice 3.A)
  │   ├── prayer_times.dart             // nouveau — fajr, sunrise, dhuhr, asr, maghrib, isha (DateTime)
  │   └── prayer_settings.dart          // nouveau — method, madhab, highLatitudeRule, location
  ├── value_objects/
  │   ├── calculation_method.dart       // enum 14+ méthodes (MWL, ISNA, Egyptian, ..., UOIF, Morocco, ...)
  │   ├── madhab.dart                   // enum Shafi | Hanafi
  │   └── high_latitude_rule.dart       // enum middleOfNight | seventhOfNight | twilightAngle
  ├── repositories/
  │   └── prayer_settings_repository.dart // interface
  └── use_cases/prayer/
      ├── get_prayer_times_for_today_use_case.dart  // pure : (settings, date) -> PrayerTimes
      ├── get_next_prayer_use_case.dart             // pure : (PrayerTimes, now) -> nextPrayer
      └── update_prayer_settings_use_case.dart

services/prayer/
  └── prayer_times_service.dart         // wrap adhan_dart — SEUL fichier qui import adhan_dart

data/
  ├── repositories/
  │   └── prayer_settings_repository_impl.dart  // SharedPreferences en V1, Supabase optionnel V1.5
  └── (rien d'autre — pas de SQL pour les horaires, calcul à la volée)

services/location/
  └── location_service.dart             // permission iOS/Android + fallback ville manuelle
```

**Règle d'isolation** : `import 'package:adhan_dart/adhan_dart.dart'`
n'apparaît **qu'une seule fois** dans tout le code, dans
`services/prayer/prayer_times_service.dart`. Aucune entité domain
n'expose un type `adhan_dart`. Tous les enums (`CalculationMethod`,
`Madhab`, `HighLatitudeRule`) sont des VOs domain Murabbi qui sont
mappés vers les types `adhan_dart` à l'intérieur du service. Si demain
on swap la lib, on touche un seul fichier.

## Plan d'implémentation slice 3.C (3 sous-slices)

### Slice 3.C.1 — Settings prière (TDD strict)

**Objectif** : entité `PrayerSettings` persistée + écran de réglages.

1. RED → GREEN sur les VOs `CalculationMethod`, `Madhab`,
   `HighLatitudeRule`.
2. RED → GREEN sur `PrayerSettings` (freezed) + `copyWith` + JSON
   serialization.
3. Décider : persistence V1 = `SharedPreferences` local OU table
   `user_prayer_settings` Supabase coordonnée avec admin. **Reco
   senior** : SharedPreferences local en V1 (cohérent avec ADR-012
   `onboarding_seen` qui est aussi local), migration Supabase
   différée V1.5 quand on aura le besoin sync multi-device. À valider
   PO en début de slice.
4. RED → GREEN sur `UpdatePrayerSettingsUseCase`.
5. UI `prayer_settings_screen.dart` : dropdown méthode (avec libellés
   FR/EN), toggle madhab Shafi/Hanafi, dropdown high-latitude rule
   (visible uniquement si lat > 48°), champ ville/pays.
6. Logique de pré-remplissage par pays au premier accès (table de
   mapping cf. décision §2).
7. Service `LocationService` : permission flow + fallback ville
   manuelle (à scoper).
8. Tests widget + golden tests sur `prayer_settings_screen`.

### Slice 3.C.2 — Calcul horaires (TDD strict avec oracle Aladhan)

**Objectif** : `GetPrayerTimesForTodayUseCase` qui retourne
`PrayerTimes` correctes pour `(settings, date)`.

1. Ajouter `adhan_dart: ^1.2.0` dans `pubspec.yaml`.
2. RED : test `prayer_times_service_test.dart` avec golden values
   pré-calculées par Aladhan API pour 5–10 villes / 5–10 dates
   (couverture : Paris UOIF, Casablanca Morocco, Mecque Umm al-Qura,
   Istanbul Diyanet, Karachi Karachi, Oslo Moonsighting, New York
   ISNA). Format : tableau de fixtures dans
   `test/fixtures/prayer_times_oracle.json`. Tolérance ±1 minute.
3. GREEN : `PrayerTimesService.computeTimes(coords, date, settings)`
   wrap `adhan_dart`, mappe les enums Murabbi vers les types
   `adhan_dart`, retourne `PrayerTimes` (entité domain).
4. RED → GREEN : `GetPrayerTimesForTodayUseCase` (pure, injecte
   `PrayerTimesService` + `PrayerSettingsRepository`).
5. RED → GREEN : `GetNextPrayerUseCase` (logique : étant donnés les 6
   timestamps du jour et `now`, retourner la prochaine prière + son
   countdown).
6. Vérifier explicitement qu'UOIF, Morocco, Algeria, Tunisia sont
   exposées par `adhan_dart` 1.2.0. Si l'une manque, utiliser méthode
   "Other" avec params custom documentés en commentaire.
7. Tests DST : 2 fixtures aux dates de transition (dernier dimanche
   d'octobre / mars) sur Paris et New York.

### Slice 3.C.3 — UI prière + intégration tracker (TDD widget + integration)

**Objectif** : afficher les horaires sur `salat_screen.dart` et
permettre au tracker (slice 3.B) de qualifier le statut d'une prière.

1. RED → GREEN : `prayerTimesProvider` (Riverpod codegen) qui pipe
   `GetPrayerTimesForTodayUseCase`.
2. RED → GREEN : `nextPrayerProvider` (Riverpod codegen) qui rebuild
   chaque minute.
3. UI `salat_screen.dart` : 5 prayer cards avec heure + statut +
   countdown next prayer (composant déjà partiellement présent).
4. Tests widget + 2 golden tests (jour normal, jour avec next prayer
   = Fajr).
5. Test integration end-to-end : "user ouvre l'app à 14h00 Paris
   après-midi → Asr est la prochaine prière, countdown affiché".
6. Câblage avec slice 3.B : le tracker auto-qualifie `late` / `missed`
   en comparant `prayer_logs.logged_at` vs les horaires retournés.
   À spec'er précisément (Q-19 / Q ouverte sur les fenêtres de
   tolérance — typiquement `onTime` = jusqu'à `next_prayer_time`,
   `late` = entre `next_prayer_time` et `next_next_prayer_time`,
   `missed` = au-delà).

## Décisions explicitement reportées en V2 / V1.5

- **Override manuel ±N min par prière** : V2 (cf. décision §4).
- **Détection automatique du madhab par pays** : non prévu (cf.
  décision §3). Restera manuel.
- **Persistence settings dans Supabase + sync multi-device** : V1.5,
  quand le besoin émerge. V1 = SharedPreferences local.
- **Notifications adhan programmées à l'heure exacte** : V1.5 ou
  Phase 6, via `flutter_local_notifications`. Doit respecter P-7
  (plages horaires utilisateur, pas de notif hors plage).

## Annexes

- Recherche détaillée : `docs/architecture/prayer-times-strategy-research-2026-05-09.md`
- Lib retenue : https://pub.dev/packages/adhan_dart (v1.2.0, MIT)
- Référence amont : https://github.com/batoulapps/adhan-js
- Méthodes documentées : https://github.com/batoulapps/adhan-js/blob/master/METHODS.md
- Méthodologie astronomique : Jean Meeus, *Astronomical Algorithms*
  (Willmann-Bell, 2nd ed.) ; spec ouverte praytimes.org/calculation.
- Oracle de validation tests : https://aladhan.com/prayer-times-api
- Précédent privacy-first : https://www.thepillarsapp.com/faqs
