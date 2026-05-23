# DES-W5 — Prayer Settings Screen (complete — replaces SETUP-01)

> Issue : [#180](https://github.com/Maximus203/murabbi-mobile/issues/180)
> Milestone : Alert System v1 — Bloque MOB-007
> Pré-reads : CDC §6 (Salat), ADR-013 (prayer times strategy), `lib/domain/entities/prayer_settings.dart`

## 1. Objectif UX

Écran complet de configuration des paramètres de prière, en remplacement de
SETUP-01 (incomplet). Doit couvrir 100% des champs du modèle `prayer_user_settings`
(côté Supabase + `PrayerSettings` côté Dart) **plus** les ajustements per-prayer
non encore modélisés. Live preview en bas qui recalcule les horaires du jour à
chaque changement.

## 2. Structure globale

```
┌──────────────────────────────────────────────┐
│ ←     Paramètres de prière           [Reset] │  ← AppBar
├──────────────────────────────────────────────┤
│                                              │
│  📍 SECTION 1 — Localisation                 │
│  ┌────────────────────────────────────────┐  │
│  │ [●─] GPS automatique                    │  │
│  │      📍 Dakar, Sénégal (14.69°N, 17.44°W)│ │
│  │      Mis à jour : il y a 12 min  ↻      │  │
│  │ [○─] Saisie manuelle (ville)            │  │
│  │ [○─] Coordonnées (lat/lng)              │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  🧭 SECTION 2 — Méthode de calcul            │
│  ┌────────────────────────────────────────┐  │
│  │ (●) MuslimWorldLeague        recommandé │  │
│  │ ( ) Egyptian                            │  │
│  │ ( ) Karachi                             │  │
│  │ ( ) UmmAlQura                           │  │
│  │ ( ) Dubai                               │  │
│  │ ( ) NorthAmerica                        │  │
│  │ ( ) Kuwait                              │  │
│  │ ( ) Qatar                               │  │
│  │ ( ) Singapore                           │  │
│  │ ( ) Turkey                              │  │
│  │ ( ) Tehran                              │  │
│  │ ( ) Jafari                              │  │
│  │   ⓘ Comment choisir ?                   │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  📚 SECTION 3 — Madhab (école pour Asr)      │
│  ┌────────────────────────────────────────┐  │
│  │ ┌───────────┐ ┌───────────┐             │  │
│  │ │ ● Shafi   │ │   Hanafi  │             │  │
│  │ │  (défaut) │ │ (Asr +1h) │             │  │
│  │ └───────────┘ └───────────┘             │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  🌐 SECTION 4 — Hautes latitudes  (lat > 48°)│
│  ┌────────────────────────────────────────┐  │  ← masquée si lat ≤ 48°
│  │ (●) Milieu de la nuit                   │  │
│  │ ( ) Septième de la nuit                 │  │
│  │ ( ) Angle crépusculaire                 │  │
│  │   ⓘ Quelle règle choisir ?              │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ⏰ SECTION 5 — Heure d'été (DST)            │
│  ┌────────────────────────────────────────┐  │
│  │ [●─] Détection automatique              │  │
│  │ [○─] Forcer ON                          │  │
│  │ [○─] Forcer OFF                         │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  🛠 SECTION 6 — Ajustements (±min)           │
│  ┌────────────────────────────────────────┐  │
│  │  Fajr     [- 0  +]  0 min               │  │  ← stepper -30 à +30
│  │  Dhuhr    [- 2  +]  +2 min              │  │
│  │  Asr      [- 0  +]  0 min               │  │
│  │  Maghrib  [- -1 +]  -1 min              │  │
│  │  Isha     [- 0  +]  0 min               │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ──────────────────────────────────────      │
│                                              │
├──────────────────────────────────────────────┤  ← sticky bottom
│  👁 Aperçu des horaires d'aujourd'hui        │
│  ┌────────────────────────────────────────┐  │
│  │  Fajr     05:42      Maghrib   19:14    │  │
│  │  Dhuhr    13:24      Isha      20:31    │  │
│  │  Asr      16:38                         │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │           ✓  Appliquer                  │  │  ← Primary CTA fixed
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

Layout : `CustomScrollView` avec `SliverList` pour sections + `BottomSheet`
persistant (non-modal) pour le panneau preview/Apply.

## 3. Sections — détails

### 3.1 — Localisation

3 modes mutuellement exclusifs (radio + contenu conditionnel) :

**Mode GPS automatique** (default si permission accordée) :
- Affiche ville reverse-géocodée + coordonnées arrondies (2 décimales)
- "Mis à jour il y a X min" + bouton refresh manuel
- Si permission refusée : bouton "Activer la localisation" + lien settings OS

**Mode saisie manuelle ville** :
- Champ texte avec autocompletion (search API à définir — locale ou réseau ?)
- Suggestion : 5 résultats max, format "Dakar, Sénégal"
- Erreur si ville introuvable : "Ville non trouvée. Essaie avec lat/lng."

**Mode coordonnées** :
- 2 champs numériques : Latitude [-90, 90], Longitude [-180, 180]
- Validation inline : message rouge sous champ si hors range
- Bouton "Centrer sur ma position" → bascule au mode GPS

### 3.2 — Méthode de calcul

Radio list avec badge "recommandé" sur l'option suggérée par défaut selon le
pays détecté (cf. ADR-013 §2.1). Tap sur `ⓘ` ouvre BottomSheet expliquant
les différences entre méthodes (texte 200 mots + liens externes).

### 3.3 — Madhab

Toggle 2 boutons :
- **Shafi** (default, Asr standard, ombre = 1× objet)
- **Hanafi** (Asr +1h, ombre = 2× objet)

Affecte uniquement l'heure d'Asr. Petit caption sous chaque bouton explique la différence.

### 3.4 — Hautes latitudes (conditionnel)

**Masquée si `|latitude| ≤ 48°`**. Apparaît avec fade 200ms quand la latitude
saisie/détectée passe ce seuil.

3 options radio :
- Milieu de la nuit (default)
- Septième de la nuit
- Angle crépusculaire

### 3.5 — DST

3 options radio :
- **Automatique** (default) — détection via timezone IANA
- **Forcer ON** — ajoute +1h en permanence
- **Forcer OFF** — pas d'ajustement saison

Caption : "Utile si ton fuseau horaire n'est pas reconnu par le système."

### 3.6 — Ajustements per-prayer

5 rows, chacune avec stepper `[- value +]` :
- Range : -30 à +30 minutes (step 1)
- Default : 0 pour toutes
- Long-press sur bouton → repeat tap (accélération après 500ms)
- Bouton "Reset tous les ajustements" en bas de section (si au moins un ≠ 0)

### 3.7 — Live preview panel (sticky)

- Affiche les 5 horaires recalculés à chaque changement (debounce 300ms)
- Layout 2 colonnes pour économiser hauteur
- Highlight visuel court (flash bg sand 400ms) quand un horaire change
- Si calcul échoue (offline + cache vide) : "Aperçu indisponible — vérifie ta connexion"

### 3.8 — CTA Apply

Sticky bas, full-width, primary color. Désactivé si aucun changement vs état
sauvegardé (dirty tracking).

## 4. États de l'écran

### 4.1 — Loading (initial)

```
┌──────────────────────────────────────────────┐
│                                              │
│              ▒▒▒▒▒▒▒▒▒▒▒▒                    │
│              ▒▒▒▒▒▒▒                         │
│                                              │
│              ▒▒▒▒▒▒▒▒▒▒▒▒                    │
│              ▒▒▒▒▒▒▒▒▒▒                      │
│              ▒▒▒▒▒▒▒                         │
│                                              │
│            (skeleton shimmer)                │
└──────────────────────────────────────────────┘
```

Skeleton 6 blocs gris animés (shimmer 1.2s loop), tant que les settings ne sont
pas chargés. Apply caché.

### 4.2 — Editing (normal)

Layout standard. CTA Apply actif dès le 1er changement.

### 4.3 — Saving

```
┌──────────────────────────────────────────────┐
│  (form grayed out, pointerEvents: none)      │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │      ⟳  Enregistrement...               │  │  ← spinner inline
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

CTA = spinner + texte. Form opacity 0.5. Timeout 10s → erreur.

### 4.4 — Saved (success)

Toast bottom 3s : "✓ Paramètres enregistrés". Form re-actif, dirty = false, Apply re-désactivé.

### 4.5 — Error

Banner rouge en haut sous l'AppBar, dismissable :

```
┌──────────────────────────────────────────────┐
│ ⚠ Impossible d'enregistrer. Réessaie.   ✕    │
└──────────────────────────────────────────────┘
```

Message dynamique selon erreur (network / validation / 500).

### 4.6 — Offline

Banner persistant haut :

```
┌──────────────────────────────────────────────┐
│ ☁ Mode hors-ligne — sync à la reconnexion    │
└──────────────────────────────────────────────┘
```

CTA Apply transforme en "Enregistrer localement" (save local, sync queue).
Live preview fonctionne avec lib client-side (`adhan_dart`).

## 5. Interactions

| Élément                  | Action                                            |
|--------------------------|---------------------------------------------------|
| Toggle GPS/manuel/coords | Bascule mode, conserve les valeurs des 2 autres   |
| Refresh GPS              | Re-fetch position, refresh preview                |
| Tap pays autocompletion  | Set lat/lng, refresh preview                      |
| Stepper - / +            | -1/+1 min, clamp à [-30, +30], haptic light       |
| Long-press stepper       | Auto-repeat après 500ms (accélération)            |
| Tap radio méthode        | Update, refresh preview, scroll garde le focus    |
| Tap madhab toggle        | Update Asr en preview                             |
| Tap Apply                | Save → loading → success/error                    |
| Tap Reset (AppBar)       | Confirm dialog → restaure defaults                |
| Tap `ⓘ` méthode/règle    | BottomSheet info (40-60% hauteur)                 |
| Hardware back avec dirty | Confirm dialog "Quitter sans enregistrer ?"       |

## 6. Données affichées (mapping)

| Champ UI                  | Source                                                 | Statut data model |
|---------------------------|--------------------------------------------------------|-------------------|
| Ville reverse-géo         | `geocoding` plugin → `Placemark.locality`              | ⚙ service (à créer) |
| Latitude / Longitude      | `PrayerSettings.latitude` / `longitude`                | ✅ OK              |
| Source location (auto/manuel/coords) | `PrayerSettings.locationMode`                | ❌ enum manquant   |
| Méthode                   | `PrayerSettings.method` (`CalculationMethod`)          | ✅ OK              |
| Madhab                    | `PrayerSettings.madhab`                                | ✅ OK              |
| Haute latitude            | `PrayerSettings.highLatitudeRule`                      | ✅ OK              |
| DST mode                  | `PrayerSettings.dstMode` (auto/on/off)                 | ❌ champ manquant  |
| Ajustement Fajr (etc.)    | `PrayerSettings.adjustments.fajr` (Map<Prayer,int>)    | ❌ champ manquant  |
| Aperçu horaires           | `computePrayerTimesForToday(settings)` → `PrayerTimes` | ✅ entité OK       |
| Dirty state               | local state UI (compare avec snapshot loaded)          | ✅                 |

## 7. Tokens

| Élément              | Token                                       |
|----------------------|---------------------------------------------|
| Section title        | `AppTypography.titleM`                      |
| Section caption      | `AppTypography.bodyS`, `AppColors.textMuted`|
| Radio active         | `AppColors.primary`                         |
| Toggle thumb         | `AppColors.surface`, track `AppColors.primary` |
| Stepper button       | 40×40 round, bg `AppColors.sandLight`       |
| Apply CTA            | full-width, `AppColors.primary`, height 56  |
| Preview panel bg     | `AppColors.surfaceVariant`                  |
| Skeleton             | `AppColors.skeleton` (à ajouter aux tokens) |
| Section padding      | 16px horizontal, 24px vertical entre sections |
| Section bg           | `AppColors.surface`, optionnel border-radius 16px |

## 8. Accessibilité

- Toutes les sections : `Semantics.header` sur le titre
- Radio : `Semantics.inMutuallyExclusiveGroup: true`
- Stepper : `Semantics.adjustable` avec `onIncrease` / `onDecrease`
- Live preview : `Semantics.liveRegion: true` mais throttle update (1× / 2s pour TalkBack) sinon spam
- Banner offline/error : `Semantics.liveRegion` + `priority: assertive`
- Skeleton loading : `Semantics(label: 'Chargement des paramètres')`
- AppBar Reset : `Semantics.button`, label complet "Réinitialiser tous les paramètres"
- Toutes targets ≥ 44×44, steppers à 40×40 acceptables car padding tap zone 8px

## 9. Edge cases

| Cas                                              | Comportement                          |
|--------------------------------------------------|---------------------------------------|
| Permission GPS refusée                           | Mode GPS désactivé + bouton settings OS |
| Geocoding API down                               | Bascule auto vers mode coords manuel  |
| Coordonnées hors range mais form submit         | Validation bloque + scroll vers champ erreur |
| Latitude passe sous 48° en cours d'édition       | Section 4 disparaît + valeur réinitialisée default |
| User change méthode → preview = même horaires    | Pas de flash highlight (no-op visuel) |
| 50+ changements rapides                          | Debounce preview 300ms, garantit 1 calcul/sec max |
| Save success mais réseau coupe avant ACK         | Idempotency key → retry transparent   |
| User logged out pendant édition                  | Redirect auth + restore intent au retour |
| Daylight Saving transition cette nuit            | Banner info "Heure d'été change cette nuit, horaires adaptés auto" |

## 10. Animations

- Skeleton shimmer : loop infini 1.2s, opacity 0.4 → 0.8
- Apparition section haute latitude : 200ms fade + height
- Preview highlight horaire changé : bg flash 400ms ease-out
- Stepper button press : scale 0.9 + haptic light
- Toast saved : slide-up 250ms + auto-dismiss 3s + slide-down 200ms
- Banner offline : slide-down 200ms, sticky
- Sticky bottom panel : shadow apparait quand scroll > 0

## 11. Questions ouvertes

1. **`PrayerSettings` data model — champs manquants**. Les 3 champs suivants
   n'existent pas dans l'entité actuelle :
   - `locationMode: enum { gps, city, manual }` — sinon impossible de savoir
     l'origine des coords au reload
   - `dstMode: enum { auto, forceOn, forceOff }`
   - `adjustments: Map<Prayer, int>` (5 entrées, -30..+30)

   Faut-il étendre l'entité ou créer `PrayerSettingsAdvanced` séparée ?
   Recommandation : étendre `PrayerSettings` (simplifie la persistance).

2. **City autocompletion — source**. Pas de plugin Flutter natif. Options :
   - (a) API Nominatim OpenStreetMap (gratuit, rate-limited)
   - (b) Mapbox/Google (payant, qualité)
   - (c) Liste statique de 1000 villes principales (offline-friendly)
   Recommandation : (c) en V1 (offline-first), (a) en V1.5.

3. **Reset — scope**. AppBar Reset → restaure quoi exactement ?
   - Tout aux defaults système
   - Tout au dernier save Supabase
   Recommandation : defaults système (cf. ADR-013).

4. **Méthode "recommandé"**. Sur quoi se base la recommandation ? Pays
   détecté ? Si oui, mapping à confirmer (ADR-013 §2.1 mentionne MWL par
   défaut si pays inconnu, mais quid des autres ?).

5. **Multi-utilisateur même device**. Settings sont per-user (RLS). Si user
   se déconnecte et un autre se connecte, on recharge ses propres settings ?
   Confirmation : oui (RLS garantit isolation).

6. **Preview en mode prière qaza (rattrapage)** : non concerné par V1, à
   noter pour V2.

7. **Sync à la reconnexion en offline**. Si user édite offline puis reconnecte :
   resolve conflict comment si Supabase a été modifié entre-temps (autre device) ?
   Recommandation : last-write-wins client en V1, CRDT en V2.

8. **Notification re-scheduling**. Quand les settings changent, faut-il
   replanifier toutes les notifs prière de la semaine ? Recommandation : oui,
   batch background après Apply success.
