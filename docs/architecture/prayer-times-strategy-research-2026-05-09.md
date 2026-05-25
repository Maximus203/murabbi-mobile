# Recherche stratégie calcul horaires prière

**Date** : 2026-05-09
**Auteur** : Tech Researcher Senior (sub-agent)
**Pour** : Murabbi mobile slice 3.C (Salat UI + horaires)
**Statut** : Research only — aucune ligne de code écrite. Sert de base à un futur ADR-013.

---

## TL;DR (résumé exécutif)

**Recommandation : calcul 100% local via la lib Dart `adhan_dart` (port officiel d'Adhan-JS de Batoul Apps), avec settings utilisateur (méthode + madhab + high-latitude rule) persistés dans Supabase.** L'API Aladhan n'est utilisée ni en source primaire, ni en fallback : elle implémente exactement les mêmes formules que `adhan_dart`, donc l'utiliser ajoute du réseau, du coût latence, et un point de défaillance sans gain de précision. Aladhan reste utile **hors-app** comme oracle de validation pendant les tests (golden values), mais pas en runtime. C'est l'approche utilisée par les apps de référence (Pillars notamment) qui pratiquent le calcul on-device. Cette stratégie est offline-first par construction, RGPD-friendly (pas de coordonnées qui sortent de l'appareil), et alignée avec la sobriété Murabbi.

---

## 1. Méthodologie

- **Sources** : web search + docs officielles Aladhan + repos GitHub `batoulapps/adhan-js`, `iamriajul/adhan-dart` + FAQ Pillars/Muslim Pro/Athan Pro + community forums Islamic Network + praytimes.org + moonsighting.com.
- **Apps comparées** : Athan Pro (QuanticApps), Muslim Pro, Pillars (TPA), Pray Watch, IslamicFinder, Salatuk (awqaf.gov.kw).
- **Critères d'évaluation** : précision astronomique, conformité madhabs (Shafi/Hanafi), fiabilité offline, coût (réseau, abonnement, batterie), licence, maintenance/activité du repo, couverture des méthodes officielles, gestion des hautes latitudes.

---

## 2. Méthodes de calcul fondamentales

### 2.1 — Bases astronomiques

Les horaires de prière sont définis par la position du soleil par rapport à l'horizon de l'observateur. Cinq grandeurs astronomiques suffisent :

| Prière | Définition astronomique |
|---|---|
| **Fajr** | Soleil à `-X°` sous l'horizon avant le lever (X varie selon la méthode, typiquement 15–20°) |
| **Sunrise (Shuruq)** | Soleil au niveau de l'horizon (lever) |
| **Dhuhr** | Soleil au méridien + petit offset (1–3 min) |
| **Asr** | Ombre d'un objet vertical = `n × hauteur + ombre_méridien`, où `n=1` (Shafi) ou `n=2` (Hanafi) |
| **Maghrib** | Coucher du soleil (sauf Shia : 4° sous l'horizon) |
| **Isha** | Soleil à `-Y°` sous l'horizon, OU `Maghrib + intervalle` (ex: Umm al-Qura = 90 min) |

Toutes les libs sérieuses (dont `adhan_dart`) calculent ces grandeurs avec les **équations astronomiques de Jean Meeus** (livre "Astronomical Algorithms"), qui sont de précision **sub-minute** sur des décennies.

### 2.2 — Méthodes de calcul officielles

Une "méthode" est essentiellement le triplet `(angle Fajr, angle Isha OU intervalle Isha, ajustement Maghrib)` retenu par une autorité religieuse.

| Méthode | Fajr | Isha | Région cible |
|---|---|---|---|
| Muslim World League (MWL) | 18° | 17° | International, défaut moderne |
| Egyptian General Authority | 19.5° | 17.5° | Égypte, Afrique, Levant |
| University of Karachi | 18° | 18° | Pakistan, Inde, Bangladesh |
| Umm al-Qura, Makkah | 18.5° | **90 min après Maghrib** (+30 min pendant Ramadan) | Arabie Saoudite |
| Dubai (UAE) | 18.2° | 18.2° | Émirats |
| Qatar | 18° | **90 min** | Qatar |
| Kuwait | 18° | 17.5° | Koweït |
| Singapore (MUIS) | 20° | 18° | Singapour, Malaisie, Indonésie |
| Turkey (Diyanet) | (algorithm spécifique) | (algorithm spécifique) | Turquie |
| Tehran | 17.7° | 14° | Iran (Maghrib à 4.5° sous horizon) |
| ISNA (North America) | 15° | 15° | USA/Canada (déprécié par certains scholars) |
| Moonsighting Committee | 18° | 18° | International (auto 1/7 rule >55° lat) |
| **UOIF (France)** | 12° | 12° | Communauté musulmane française |
| **Morocco (Habous)** | 19° | 17° | Maroc |
| **Algeria** | 18° | 17° | Algérie |
| **Tunisia** | 18° | 18° | Tunisie |

Sources :
- [adhan-js/METHODS.md](https://github.com/batoulapps/adhan-js/blob/master/METHODS.md)
- [aladhan.com/calculation-methods](https://aladhan.com/calculation-methods)

### 2.3 — Madhab et calcul de Asr

| Madhab | Règle Asr |
|---|---|
| **Shafi, Maliki, Hanbali** | Ombre = `1 × hauteur` (Asr plus tôt, Asr awwal) |
| **Hanafi** | Ombre = `2 × hauteur` (Asr plus tard, Asr thani) |

C'est la **seule** différence inter-madhab dans le calcul. Les autres prières sont indépendantes du madhab. Conséquence : `adhan_dart` expose un enum `Madhab.shafi | Madhab.hanafi` qui couvre 100% des cas.

### 2.4 — Hautes latitudes (>48° N/S)

Au-delà de ~48° de latitude, certaines nuits, le soleil ne descend pas suffisamment pour atteindre l'angle Fajr/Isha (ex: 18°). Conséquence : **Fajr et/ou Isha n'existent pas** astronomiquement. Pour Oslo, Stockholm, Reykjavik, Montréal en hiver/été, c'est un problème réel.

Trois règles d'ajustement sont reconnues, toutes implémentées par `adhan_dart` :

1. **Middle of the Night** : Fajr = milieu de la nuit, Isha = milieu de la nuit (selon le côté).
2. **Seventh of the Night** : la nuit (Maghrib → Fajr du jour suivant) est divisée en 7 parts. Isha = +1/7 après Maghrib, Fajr = -1/7 avant Sunrise.
3. **Twilight Angle** : on garde l'angle mais on plafonne l'horaire à un milieu/septième en cas d'invalidité.

La méthode **Moonsighting Committee** applique automatiquement la règle 1/7 au-dessus de 55° de latitude — c'est un défaut robuste pour l'Europe du Nord et le Canada.

Source : [praytimes.org/calculation](https://praytimes.org/calculation), [moonsighting.com/how-we.html](https://www.moonsighting.com/how-we.html)

---

## 3. Comparaison des solutions techniques

### 3.1 — APIs externes

| Solution | Précision | Offline | Coût | Licence | Maintenance | Note |
|---|---|---|---|---|---|---|
| **Aladhan API** (aladhan.com) | Haute (utilise les mêmes formules astronomiques que `adhan-js`) | Non (sauf cache) | Gratuit, ~12 req/sec/IP, sans auth | API ouverte | Active | 22 méthodes, geocoding city/country, calendars mensuels. Excellent pour validation/tests. |
| **IslamicFinder API** | Haute | Non | Gratuit avec key | Propriétaire | Active | Alternative — moins documentée publiquement. |
| **UmmahAPI** | Haute | Non | Freemium | Propriétaire | Active | Concurrent récent d'Aladhan, plus opaque. |

Sources :
- [aladhan.com/prayer-times-api](https://aladhan.com/prayer-times-api)
- [community.islamic.network — rate limit](https://community.islamic.network/d/2-is-there-a-rate-limit-on-the-apis)

**Verdict APIs** : Aladhan est solide et gratuit, mais fondamentalement **redondant** avec le calcul local. L'API ne fait rien de plus que ce que `adhan_dart` fait on-device — elle utilise les mêmes équations Meeus. L'utiliser introduit dépendance réseau, latence, fuite de coordonnées GPS vers un serveur tiers (RGPD), risque de dépréciation, et limite le mode avion. Pas de gain.

### 3.2 — Librairies locales (calcul client)

| Solution | Plateforme | Précision | Maintenance | Licence | Note |
|---|---|---|---|---|---|
| **`adhan_dart`** (iamriajul, port d'Adhan-JS) | Dart pur | Sub-minute (Meeus) | Active — v1.2.0 il y a 6 mois, 104 stars, 16 issues, 44 forks | MIT | Port fidèle de la référence Adhan-JS de Batoul Apps. Tous les madhabs, toutes les méthodes principales, tous les high-latitude rules, qibla, sunnah times. |
| **`adhan` package** (pub.dev, autre auteur) | Dart pur | Identique | Variable | MIT | Concurrent — vérifier dernière maintenance avant choix. |
| **`aladhan_prayer_times`** (pub.dev) | Dart wrapper | Dépend de l'API | Active | MIT | Wrapper Aladhan API — non recommandé (cf. §3.1). |
| **Adhan-Swift / Adhan-Kotlin** (Batoul Apps) | Natif iOS/Android | Sub-minute | Active | MIT | Référence inter-plateforme. Non utilisable en Flutter sans channels. |

Sources :
- [pub.dev/packages/adhan_dart](https://pub.dev/packages/adhan_dart)
- [github.com/iamriajul/adhan-dart](https://github.com/iamriajul/adhan-dart)
- [github.com/batoulapps/adhan-js](https://github.com/batoulapps/adhan-js) (référence amont)

**Verdict libs** : `adhan_dart` est **la** solution. C'est un port direct de la lib Adhan de Batoul Apps, qui est elle-même la référence open-source utilisée par d'innombrables apps musulmanes. MIT, sans dépendance externe, calcul on-device, supporte tous les cas (madhabs, méthodes, hautes latitudes, sunnah times, qibla bonus).

### 3.3 — Apps de référence : ce qu'elles font

#### Pillars (TPA, ad-free, privacy-driven)
- **Calcul** : on-device (pas d'API tiers — argument privacy mis en avant).
- **Méthodes** : MWL, ISNA, Moonsighting Committee, et autres.
- **Madhabs** : Shafi / Hanafi sélectionnable.
- **High-latitude** : règle dédiée dans les settings ("angle-based High Latitude Rule").
- **Offline** : oui, par construction.
- Source : [thepillarsapp.com/faqs](https://www.thepillarsapp.com/faqs).
- **C'est l'app la plus alignée avec l'éthique Murabbi.**

#### Athan Pro (QuanticApps)
- **Calcul** : geo-location + on-device (toutes les méthodes principales : MWL, ISNA, Egypt, Umm al-Qura, etc.).
- **Madhabs** : Shafi / Hanafi.
- **Offline** : oui une fois la localisation faite.
- **Source** : non public sur le détail interne. Probable utilisation d'une lib similaire à Adhan.

#### Muslim Pro
- **Calcul** : on-device + option "App Recommended" qui se base sur les autorités religieuses locales / mosquées proches.
- **Méthodes** : tous les standards + custom angles (Fajr/Isha manuels).
- **Madhabs** : Shafi, Hanafi, Maliki, Hanbali (les 4 mais les 3 derniers convergent sur Asr).
- **Override manuel** : oui, ajustement +/- minutes par prière (utile pour caler sur la mosquée locale).
- Source : [support.muslimpro.com](https://support.muslimpro.com/hc/en-us/articles/200184789).

#### Pray Watch
- **Custom calculation method** : permet à l'utilisateur de définir Fajr/Isha angles manuellement.
- Source : [praywatch.app/help](https://praywatch.app/help/articles/custom-calculation-method/).

#### Salatuk (awqaf.gov.kw — Kuwait Ministry of Awqaf)
- **Calcul** : officiel Koweït (méthode 9 — Kuwait), on-device.
- **Override** : non — l'autorité fixe.

**Pattern commun observé** : toutes ces apps **calculent en local**, exposent des settings (méthode + madhab + ajustements +/- minutes par prière), et **certaines** (Muslim Pro) ajoutent une logique "recommandation par localisation" pour pré-remplir la méthode selon le pays.

---

## 4. Considérations métier Murabbi

- **Audience cible** : musulmans francophones et anglophones, 18–45 ans. → Inclure UOIF (France), Morocco, Algeria, Tunisia dans la liste des méthodes proposées par défaut, en plus des standards internationaux.
- **Sobre, anti-gamification, anti-addiction** (CLAUDE.md racine §A.1) → un seul écran de settings prière, propre, sans alertes intempestives. Pas de notification "Tu as raté Fajr aujourd'hui !" culpabilisante.
- **Précision exigée** : haute. Un musulman pratiquant ne tolère pas un horaire faux de >2 min, surtout pour Fajr/Maghrib. → `adhan_dart` (formules Meeus) est sub-minute, donc OK. La marge d'erreur perçue vient du **choix de la méthode**, pas du calcul.
- **Offline** : exigé. L'app peut être en métro, à l'étranger, sans data. → calcul local **obligatoire**.
- **Géolocalisation** : permission utilisateur (sensible en RGPD). Fallback : ville manuelle (geocoding via Aladhan en one-shot OU via une lib offline de villes). → la coordonnée GPS ne quitte jamais l'appareil — argument fort pour le repo OSS Murabbi.
- **Madhabs minimum** : Shafi (majoritaire global) + Hanafi (Asr décalé). `adhan_dart` couvre les deux.
- **Méthodes** : exposer au moins MWL, ISNA, Egyptian, Karachi, Umm al-Qura, Diyanet, Tehran, UOIF, Morocco, Algeria, Tunisia, Singapore, Moonsighting Committee.
- **Override manuel** : à confirmer avec PO (cf. §5.3) — utile pour les utilisateurs alignés sur leur mosquée locale dont les horaires diffèrent de quelques minutes.

---

## 5. Recommandation pour Murabbi

### 5.1 — Option recommandée : calcul 100% local via `adhan_dart`

**Rationale** :

1. **Offline-first** par construction — aligné avec l'usage mobile réel (transport, voyage).
2. **Privacy-first** — les coordonnées GPS de l'utilisateur ne sont jamais envoyées à un serveur tiers. Argument fort pour un repo public OSS et pour un audit RGPD propre.
3. **Précision identique** à Aladhan API (les deux utilisent les formules Meeus du même algorithme Adhan upstream).
4. **Coût zéro** — pas d'abonnement, pas de quota, pas de risque de dépréciation API.
5. **Maintenance** : `adhan_dart` est actif (v1.2.0, 6 mois), MIT, port d'une lib upstream (`adhan-js`) elle-même très active, donc faible risque de bus factor.
6. **Robustesse hautes latitudes** : 3 règles supportées (Middle of Night, Seventh of Night, Twilight Angle).
7. **Bonus** : `adhan_dart` fournit aussi qibla direction et sunnah times (last third of night) — utile pour de futures features.

### 5.2 — Architecture proposée (couches Clean Archi)

```
presentation/features/salat/
  ├── screens/salat_screen.dart
  ├── providers/prayer_times_provider.dart       (Riverpod codegen)
  └── widgets/prayer_card.dart

domain/
  ├── entities/prayer_times.dart                 (freezed: fajr, sunrise, dhuhr, asr, maghrib, isha)
  ├── entities/prayer_settings.dart              (freezed: method, madhab, highLatitudeRule, manualOffsets)
  ├── repositories/prayer_settings_repository.dart  (interface)
  └── usecases/
       ├── get_prayer_times_for_today.dart
       ├── get_next_prayer.dart
       └── update_prayer_settings.dart

data/
  ├── services/prayer_times_calculator.dart      (wrapper adhan_dart, pure)
  ├── repositories/prayer_settings_repository_impl.dart  (Supabase + cache local)
  └── datasources/supabase/prayer_settings_supabase_ds.dart
```

**Points clés** :

- `PrayerTimesCalculator` est un **service pur** côté `data/` qui prend `(coords, date, settings)` et retourne `PrayerTimes`. Il encapsule `adhan_dart` — aucun import `adhan_dart` ailleurs. Si demain on change de lib, on swap ce fichier.
- Le use case `GetPrayerTimesForToday` injecte le calculateur + le repo settings. **100% testable unitairement** (TDD strict §3 CLAUDE.md mobile).
- Settings persistés dans Supabase (table `user_prayer_settings`) → sync multi-device + rebuild facile. Cache local via `SharedPreferences` pour le mode hors-ligne au cold start.
- Géolocalisation gérée séparément (`location_service.dart` côté `services/`) avec permission iOS/Android + fallback ville manuelle.

### 5.3 — Questions ouvertes pour le PO (à valider avant slice 3.C.1)

1. **Méthode par défaut selon localisation** : pré-remplir intelligemment (FR → UOIF, MA → Morocco, DZ → Algeria, autre → MWL) ou laisser MWL global et l'utilisateur choisit lui-même ?
   - **Reco** : pré-remplissage intelligent par geo-IP au premier lancement, modifiable. C'est ce que fait Muslim Pro et c'est un gros gain UX sans complexité.
2. **Override manuel des horaires** (`+/- N minutes par prière`) : v1 ou v2 ?
   - **Reco** : v2. Pas critique pour le tracker, ajoute de la complexité settings.
3. **Madhab par défaut** : Shafi (majoritaire global) ou détection par pays (Hanafi pour TR/PK/IN/BD/AF) ?
   - **Reco** : Shafi par défaut, configurable. La détection par pays est subtile et risquée (un Pakistanais en France peut être Shafi).

### 5.4 — Risques identifiés

| Risque | Impact | Mitigation |
|---|---|---|
| Latitudes >55° (Norvège, Canada Nord) — Fajr/Isha invalides certains jours | Moyen — concerne <1% des utilisateurs cibles mais visible | Forcer "Moonsighting Committee" ou exposer le High-Latitude Rule explicitement dans settings ; tester avec dates extrêmes (juin/décembre Oslo) |
| Changement d'heure été/hiver (DST) | Faible si tz géré correctement | `adhan_dart` calcule en UTC, on convertit avec le tz de l'appareil. Tester transitions DST en widget tests. |
| Mosquée locale qui décale ses horaires manuellement (jamaa) | Moyen — utilisateurs frustrés | Override manuel en v2 (cf. Q2) |
| Lib `adhan_dart` non-maintenue à terme | Faible (port d'une lib upstream très active) | Service `PrayerTimesCalculator` isole l'import → swap futur trivial |
| Permission localisation refusée | Élevé — bloque la feature | Fallback ville manuelle obligatoire en onboarding (sélecteur pays/ville) |
| Incohérence vs. mosquée de référence (1–3 min) | Faible — perçu comme "normal" | Documentation in-app : "Murabbi suit la méthode X. Si vous suivez votre mosquée locale, ajustez la méthode dans Settings." |

---

## 6. Plan d'implémentation slice 3.C (proposition)

1. **ADR-013** — Choix solution horaires prière. Capitalise cette recherche. Format CLAUDE.md §6.
2. **Slice 3.C.1 — Settings utilisateur prière** :
   - Entité `PrayerSettings` (freezed).
   - Migration Supabase `user_prayer_settings` (à coordonner avec `murabbi-admin/supabase/`).
   - Use case `UpdatePrayerSettings` + tests TDD.
   - UI screen "Paramètres prière" (méthode, madhab, high-latitude rule).
   - Service `LocationService` + permission flow.
3. **Slice 3.C.2 — Calcul horaires** :
   - Ajout dep `adhan_dart: ^1.2.0` dans `pubspec.yaml`.
   - Service `PrayerTimesCalculator` (wrapper pur, 100% testable).
   - Use case `GetPrayerTimesForToday` + tests TDD avec golden values (cross-check vs Aladhan API en test only).
   - Use case `GetNextPrayer` (logique : quelle est la prochaine prière maintenant ?).
4. **Slice 3.C.3 — UI prière** :
   - Écran principal Salat avec les 5 prières + countdown next prayer.
   - Provider Riverpod `prayerTimesProvider` (codegen).
   - Tests widget + golden tests.
5. **Slice 3.C.4 — Notifications adhan** (peut être différé) :
   - `flutter_local_notifications` programmée à chaque heure de prière.
   - Respect plages horaires utilisateur (P-7).

---

## Annexes

### Liens utiles

- [pub.dev — adhan_dart](https://pub.dev/packages/adhan_dart)
- [GitHub — iamriajul/adhan-dart](https://github.com/iamriajul/adhan-dart)
- [GitHub — batoulapps/adhan-js (upstream reference)](https://github.com/batoulapps/adhan-js)
- [Adhan-JS METHODS.md (toutes les méthodes documentées)](https://github.com/batoulapps/adhan-js/blob/master/METHODS.md)
- [Aladhan calculation methods](https://aladhan.com/calculation-methods)
- [Aladhan API docs](https://aladhan.com/prayer-times-api)
- [Praytimes.org — algorithme de référence](https://praytimes.org/calculation)
- [Moonsighting.com — how we calculate](https://www.moonsighting.com/how-we.html)
- [Astronomy Center — high latitude prayer times](https://astronomycenter.net/latitude.html?l=en)
- [Pillars FAQ](https://www.thepillarsapp.com/faqs)
- [Muslim Pro support — calculation methods](https://support.muslimpro.com/hc/en-us/articles/200184789)

### Repos GitHub à étudier

- `batoulapps/adhan-js` — référence amont, documentation excellente
- `iamriajul/adhan-dart` — la lib à utiliser
- `batoulapps/adhan-swift` & `adhan-kotlin` — pour comparaison de comportement cross-platform

### Documents techniques

- Jean Meeus, *Astronomical Algorithms* (Willmann-Bell, 2nd ed.) — base de toutes les libs Adhan.
- Pray Times specification (praytimes.org) — spec ouverte du calcul.

---

*Fin du rapport — Tech Researcher Senior · Murabbi · 2026-05-09*
