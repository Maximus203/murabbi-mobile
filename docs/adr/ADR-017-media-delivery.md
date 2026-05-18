# ADR-017 — Stratégie de livraison des médias vidéo

- **Date** : 2026-05-17
- **Statut** : Accepté
- **Décideurs** : Cherif DIOUF (PO), Agent senior mobile
- **Issues** : #90

---

## Contexte

L'application Murabbi embarque 11 vidéos MP4 utilisées comme fonds décoratifs
sur différents écrans. Ces vidéos ont des tailles significatives et un impact
direct sur la taille de l'APK/IPA finale.

Deux usages se distinguent clairement :

1. **Vidéos d'onboarding** — affichées avant toute connexion réseau (splash,
   slides de configuration). Elles doivent être disponibles hors-ligne dès le
   premier lancement.

2. **Vidéos in-app** — affichées après authentification (dashboard Niyyah,
   écrans Salat, level-up, collections). L'utilisateur est connecté ; un
   chargement réseau est acceptable.

Contrainte de taille : la limite APK est fixée à **< 30 MB** (CLAUDE.md §10).
Embarquer les 11 vidéos dans l'APK risque de dépasser cette limite.

---

## Options envisagées

### Option A — 100 % bundlées (toutes les vidéos dans l'APK)

- **\+** Disponible hors-ligne partout.
- **\-** APK > 30 MB (violation de la contrainte §10).
- **\-** Mise à jour des vidéos impossible sans release store.

### Option B — 100 % Supabase Storage (toutes les vidéos à distance)

- **\+** APK minimal.
- **\-** L'onboarding nécessite une connexion réseau dès le premier lancement —
  mauvaise UX et possible échec sur Android avec faible signal.
- **\-** Complexité accrue sans bénéfice sur les vidéos vues une seule fois.

### Option C — Split (retenue) : onboarding bundlé + in-app via Supabase Storage

- Vidéos onboarding (02, 03, 04, 06) → `assets/videos/` dans l'APK.
- Vidéos in-app (01, 07, 08, 09, 10, 11) → bucket Supabase `app-media`.
- **\+** APK cible : ~20–25 MB avec les 4 vidéos bundlées (< 30 MB limite §10).
- **\+** Onboarding disponible hors-ligne.
- **\+** Vidéos in-app mises à jour sans release store.
- **\-** Les vidéos in-app nécessitent une connexion ; un fallback (loading +
  couleur de fond) est obligatoire.

---

## Décision

**Option C retenue** — split onboarding bundlé / in-app Supabase Storage.

### Mapping détaillé

| Fichier source     | Écran cible                        | Livraison         | Clé / chemin asset              |
|--------------------|------------------------------------|-------------------|---------------------------------|
| `02 Murabbi.mp4`   | OB-01 Splash (fond plein écran)    | Bundlée           | `assets/videos/02_murabbi.mp4`  |
| `06 Murabbi.mp4`   | OB-02 (fond plein écran)           | Bundlée           | `assets/videos/06_murabbi.mp4`  |
| `04 Murabbi.mp4`   | OB-03 (fond plein écran)           | Bundlée           | `assets/videos/04_murabbi.mp4`  |
| `03 Murabbi.mp4`   | OB-04 (fond plein écran)           | Bundlée           | `assets/videos/03_murabbi.mp4`  |
| `01 Murabbi.mp4`   | HM-01 Niyyah card (130 px)         | Supabase Storage  | `01_murabbi.mp4`                |
| `07 Murabbi.mp4`   | SA-03 SL-DETAIL (bandeau 200 px)   | Supabase Storage  | `07_murabbi.mp4`                |
| `08 Murabbi.mp4`   | LEVEL-UP (plein écran)             | Supabase Storage  | `08_murabbi.mp4`                |
| `09 Murabbi.mp4`   | SA-01 header (bandeau 130 px)      | Supabase Storage  | `09_murabbi.mp4`                |
| `10 Murabbi.mp4`   | CO-01 thumbnail                    | Supabase Storage  | `10_murabbi.mp4`                |
| `11 Murabbi.mp4`   | CO-01 thumbnail                    | Supabase Storage  | `11_murabbi.mp4`                |

> Note : la vidéo `05 Murabbi.mp4` n'est pas référencée dans les wireframes
> validés. Elle n'est pas embarquée dans cette version.

---

## Conséquences

### Techniques

- **APK cible** : ~20–25 MB avec 4 vidéos bundlées — respecte la limite de
  30 MB du §10.
- **Bucket Supabase `app-media`** : à créer manuellement dans la console
  Supabase avant la Phase 3 (HM-01 / SA-01 / SA-03). Accès public en lecture.
- **`AppMedia`** (`lib/core/constants/app_media.dart`) : classe de constantes
  centralisant tous les chemins asset et toutes les clés Storage.
- **`VideoService`** (`lib/services/video_service.dart`) : service résolvant
  les URLs publiques depuis Supabase Storage. Utilisé uniquement par la couche
  `presentation` via `videoServiceProvider`.
- **`AppVideoPlayer`** (`lib/presentation/common/app_video_player.dart`) :
  widget unifié supportant `assetPath` (bundlé) et `url` (remote). Remplace
  `AppVideoBackground` sur les écrans nécessitant les deux modes. `AppVideoBackground`
  est conservé pour compatibilité ascendante (usage existant assets/media/).
- **Fallback obligatoire** : si la vidéo remote est absente ou si la requête
  échoue, afficher un `Container` couleur `bgCard` (jamais de crash).

### Opérationnelles

- Les fichiers MP4 doivent être copiés dans `assets/videos/` depuis le dossier
  local des assets compressés avant tout build release (cf. `assets/videos/README.md`).
- Les vidéos in-app doivent être uploadées dans le bucket `app-media` avant la
  Phase 3 (HM-01, SA-01, SA-03). Voir la procédure dans `assets/videos/README.md`.
- Row Level Security : le bucket `app-media` est public en lecture (pas de RLS
  sur les objets Storage — accès anonyme autorisé). Aucune donnée sensible
  n'est stockée dans ce bucket.

### Hors périmètre (à traiter ultérieurement)

- Mise en cache locale des vidéos Supabase (éviter un re-download à chaque
  lancement) — à évaluer en Phase 4 si la bande passante est identifiée comme
  problème.
- iOS : les mêmes vidéos bundlées sont utilisées. La taille IPA cible reste
  < 40 MB (CLAUDE.md §10). À mesurer lors de la Phase 6.
