# Murabbi · Extras Mobile — Spec

> **Périmètre livré.** Sous-ensemble priorisé : Notifications · Widgets iOS · Live Activities · Moments in‑app · App Icons. Variations Android (Pixel stock) en complément. 33 mockups répartis en 7 sections — voir `Murabbi Extras Mobile.html`.

---

## 0 · Système visuel

**Palette héritée des wireframes mobile.**

| Token              | Valeur                  | Usage                                         |
|--------------------|--------------------------|-----------------------------------------------|
| `bgPrimary`        | `#F5F2ED`               | Fond d'écran, cartes secondaires              |
| `bgSurface`        | `#FDFBF8`               | Cartes, widgets clairs                        |
| `textPrimary`      | `#1C1A16`               | Texte principal                               |
| `textSecondary`    | `#6B6155`               | Texte d'accompagnement                        |
| `textTertiary`     | `#A89880`               | Méta, kickers, mono                           |
| `accent` (sienna)  | `#8B6F47`               | Identité, prochaine prière                    |
| `success` (sage)   | `#6B8C6B`               | Validé, à l'heure                             |
| `warning` (ocre)   | `#9B5E3C`               | En retard                                     |
| `danger` (brick)   | `#8C3D3D`               | Manquée                                       |

**Typographie.** Geist (sans), Geist Mono (chiffres, kickers), Noto Sans Arabic (noms de prière). Aucune police système iOS/Android n'est imposée — ces réglages sont des **mockups**, le SDK natif appliquera ses propres polices à la livraison.

**Wallpapers.** Dégradés sobres custom, dispos en `morning` (clair, terreux) et `dusk` (sombre, chaud). Pas de photo, pas de vidéo en background — fallback statique imposé.

**Statut habitude (système 4 états).** `Validé` (sage) · `En retard` (ocre) · `Manquée` (brick) · `En attente` (gris 10%).

---

## 1 · App Icons (4 variations)

| Code | Variant | Fond            | Glyphe          | Note                                |
|------|---------|-----------------|-----------------|-------------------------------------|
| A1   | Light   | `#F5F2ED` sand  | sienna `#8B6F47`| **Icône par défaut.** Cible iOS/Android |
| A2   | Dark    | `#1C1A16`       | sable clair     | Mode sombre système iOS 18          |
| A3   | Tinted  | `#3D2E1F`       | crème           | Tinted iOS 18 (palette terre)       |
| A4   | Sage    | `#1F2A1F`       | sage clair      | Alternative pour utilisateurs sport |

Glyphe Murabbi : **cercle ouvert + barre verticale**, stroke 1.4. Lecture : la voie (cercle) + la régularité (barre). Continuous corner radius (22.5 % de la largeur).

---

## 2 · Widgets iOS (9 mockups)

### Inventaire

| Code | Taille  | Nom                          | Cellules | Données                                   |
|------|---------|------------------------------|----------|-------------------------------------------|
| B1   | small   | Score du jour                | 2×2      | Anneau % · pts · libellé                  |
| B2   | small   | Prochaine prière             | 2×2      | Nom AR + FR · heure · countdown           |
| B3   | small   | Streak                       | 2×2      | n jours · 7 derniers points               |
| B4   | medium  | Vue d'ensemble               | 4×2      | Anneau · prières 3/5 · habitudes 6/9      |
| B5   | medium  | À venir aujourd'hui          | 4×2      | 3 prochaines actions horodatées           |
| B6   | medium  | Salat (5 prières du jour)    | 4×2      | 5 colonnes · statut chacune               |
| B7   | large   | Tableau de bord              | 4×4      | Score + Salat 5×1 + 4 habitudes + streak  |
| B8   | large   | Calendrier mois              | 4×4      | Heatmap 30 jours · légende statut         |
| B9   | sheet   | Écran d'ajout iOS            | —        | Carrousel `Add Widget`                    |

### Règles

- **Anneau de progression.** Stroke 4 px. Track : `rgba(0,0,0,0.08)` (light), `rgba(255,255,255,0.20)` (dark). Couleur : `accent`.
- **Coins.** 22 px (small/medium/large) — valeur iOS native.
- **Header de widget.** Kicker mono 9 px, 1.2 letter-spacing, `textTertiary` ; glyphe Murabbi 12 px aligné à droite.
- **Prochaine prière.** Glyphe pastille 4 px `accent` au-dessus de la colonne ; bordure `accentBorder` sur la cellule (B6, B7).
- **Pas d'interaction documentée.** Tap → ouvre l'app sur la vue correspondante (Salat → Salat, Score → Aujourd'hui).

### Mises en situation

- **C1** : combo small + medium dans un iPhone 14 Pro réaliste.
- **C2** : large `B7` plein écran d'accueil.

---

## 3 · Widgets Android (Pixel stock, 4 mockups + 1 home)

| Code | Taille | Équivalent iOS | Notes                              |
|------|--------|----------------|------------------------------------|
| C1   | 2×2    | B1             | Coins 28 px (Material 3)           |
| C2   | 4×2    | B4             | —                                  |
| C3   | 4×4    | B7             | Réutilise le contenu B7            |
| C4   | sheet  | B9             | Picker Pixel (sombre, 2 cards)     |

**Règles spécifiques Android.**
- Coins 28 px sur les widgets, coins 32 px sur les écrans (Pixel).
- Police mockup Geist (en réel : Roboto / Google Sans).
- Pas de shadow forte — bordure 0.5 px `rgba(28,26,22,0.06)`.

**Skin.** Pixel stock (Android 14) en référence. Variation `Samsung` exposée dans les Tweaks pour iteration future ; non livrée à ce stade (placeholder visuel identique pour l'instant).

---

## 4 · Lock screen widgets (iOS 16+)

3 slots disponibles sur l'écran de verrouillage :

| Slot         | Géométrie         | Mockups livrés                 |
|--------------|-------------------|--------------------------------|
| `inline`     | Pill au-dessus de l'horloge | « Asr · 16:32 » / « 14 jours · 42 pts » |
| `circular`   | 76×76, bord verre | Anneau % · prochaine prière · streak |
| `rectangular`| 158×76, bord verre| Score + 3/5 prières · Asr countdown |

**Règles.**
- Background : `rgba(28,26,22,0.30)` + `backdrop-filter: blur(20px)`.
- Bord : `0.5px rgba(255,255,255,0.16)`.
- Texte : blanc opaque, opacité 0.7 pour méta.
- **D1** = configuration recommandée par défaut. **D2** = alternative dense. **D3** = pièces détachées.

---

## 5 · Live Activities (iOS)

Activité unique ciblée : **plage à l'heure d'une prière** (Asr en exemple, durée 15 min).

| Code | Variante                  | Contenu                                                      |
|------|---------------------------|--------------------------------------------------------------|
| E1   | Dynamic Island compact    | Icône soleil (gauche) · countdown (droite)                   |
| E2   | Minimal pair (split)      | Glyphe Murabbi (gauche) · icône soleil (droite)              |
| E3   | Dynamic Island expanded   | Carte 78 % largeur · nom AR/FR · countdown · barre de plage  |
| E4   | Lock screen card          | Carte plein cadre · 2 actions (Validé / Plus tard)           |

**Règles.**
- Format temps : `mm:ss` (countdown) en mono, weight 500.
- Barre de plage : remplissage `#fff` sur track `rgba(255,255,255,0.15)`, hauteur 4 px.
- Live Activity démarre 10 min avant la fin de la plage, se termine à validation ou expiration.

---

## 6 · Notifications (15 mockups)

### F1–F2 · Rappels d'habitudes
- **F1** iOS lock — habitude « Lecture du Coran » avec actions inline `Validé` / `Plus tard`.
- **F2** Pixel lock — équivalent Android avec `30 squats`.

### F3–F5 · Salat
- **F3** Banner in-app iOS — Asr déclenché alors que l'app est en avant-plan.
- **F4** Pixel lock — 3 actions (`À l'heure` / `Manquée` / `Plus tard`).
- **F5** Long-press iOS expanded — image header dégradé, progression du jour, 3 actions.

### F6–F8 · Streaks
- **F6** 7 jours consécutifs — minimal.
- **F7** 30 jours consécutifs — minimal.
- **F8** 1 an — version riche, image header.

### F9 · Niveau
- **F9** Murid débloqué (niveau 1/5).

### F10–F11 · Contenu
- **F10** iOS — nouvelle collection « Routine Ramadan ».
- **F11** Pixel — équivalent Android.

### F12 · Récap
- **F12** Récap hebdo dimanche 20:00, riche, dégradé sombre.

### F13 · In-app
- **F13** Toast `Habitude validée · +3 pts`. Pill arrondie au-dessus de la nav.

### F14 · Groupage
- **F14** 3 rappels stackés sous l'horloge (style iOS).

### F15 · Permission
- **F15** Prompt système iOS « Murabbi souhaite vous envoyer des notifications ».

### Règles transverses
- **Ton.** Sobre, factuel. Une seule version par notification — pas d'A/B exposé.
- **Heures.** Horloge mono, `accent` sur les éléments dynamiques.
- **Actions.** Toujours 1–3 max. Action principale en `weight: 600` ou couleur sémantique (sage / brick).
- **Plage à l'heure.** Indiquée systématiquement sur les rappels Salat (`jusqu'à 16:47`).

---

## 7 · Moments in-app (4 écrans)

| Code | Écran                | Trigger                                      |
|------|----------------------|----------------------------------------------|
| G1   | Streak 7 jours       | À l'ouverture le matin du 8ᵉ jour            |
| G2   | Niveau 1 — Murid     | Au franchissement du palier (120 pts)        |
| G3   | État vide habitudes  | Premier accès à `Mes habitudes` sans contenu |
| G4   | Journée complète     | Après validation du dernier item du jour     |

**Règles.**
- 1 illustration symbolique (pas de figuratif), 1 titre court, 1 paragraphe ≤ 2 phrases, 1 ou 2 boutons.
- Bouton primaire `textPrimary` plein, radius 999. Secondaire en bordure 0.5 px.
- Headers pré-existants conservés (status bar + navigation).

---

## Tweaks exposés dans le livrable

- **Wallpaper** : Clair / Sombre — affecte les mises en situation (lock, home).
- **Plateforme** : iOS / Android — bascule les frames device.
- **Skin Android** : Pixel / Samsung (Pixel livré, Samsung en placeholder).

---

## Hors périmètre (à confirmer dans une itération suivante)

- Apple Watch · complications, notifications.
- One UI Samsung (skin Android #2).
- Always-On Display (iOS 16+, Pixel).
- Variations marketing (App Store screenshots, OG images).
- Sons de notification, haptics — non couverts ici.
