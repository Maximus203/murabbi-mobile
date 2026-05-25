# Murabbi v1.5 — Design Spec Sheet

> Itération sur les wireframes Hi-Fi v3. **Aucun token visuel nouveau** — tout réutilise la palette terreuse, Geist + Geist Mono, bordures 0.5px, rayons 16/10/6/100, mode clair, Lucide.

---

## 1. Écrans modifiés

### HM-01 · Dashboard

| Avant (v3) | Après (v1.5) |
|---|---|
| Liste plate "Habitudes 6/9" sans détail | Micro-rows enrichies : nom + valeur Mono à droite + bouton check **OU** badge timer pulse |
| — | Si objectif chiffré : `3 / 5 pages` à droite |
| — | Si sous-tâches seules : `3/5` à droite |
| — | Si timer en cours : pill ocre avec dot pulse + `12:34` |

**Pourquoi** : densité d'info préservée (pas de redesign) tout en exposant les 3 nouvelles dimensions.

### HB-01 · Liste habitudes

| Avant (v3) | Après (v1.5) |
|---|---|
| Carte : dot + nom + fréquence + check | Idem **+** mini-barre 4px (60% largeur) sous le titre si objectif |
| — | Caption `3 / 5 pages` Mono au-dessus de la barre |
| — | Si timer actif : pill `Timer · 12:34 restant` |

**Couleurs de la mini-barre** :
- 0–49% : `rgba(139, 111, 71, 0.4)` — ocre clair
- 50–99% : `#8B6F47` — ocre
- 100% : `#6B8C6B` — sauge

### HB-02 · Création / édition habitude

Trois nouvelles sections **pliables** insérées **après "Jours actifs"**, **avant "Aperçu notification"** :

1. **Objectif chiffré** — toggle on/off + champ valeur (Mono) + select unité (10 options + "Personnalisé…")
2. **Sous-tâches** — toggle + liste drag-and-drop + bouton ajouter (max 15) + toggle "Toutes obligatoires"
3. **Timer in-app** — toggle (grisé si unité ≠ minutes/heures) + caption + mini-aperçu de la modal

Composant réutilisé : `<CollapsibleSection>` (chevron rotation + label uppercase + count Mono optionnel + toggle à droite).

### HB-DETAIL · 3 variantes

Layout reconfiguré : carte **"Aujourd'hui"** en haut, qui adapte son contenu selon les fonctionnalités :

- **Objectif chiffré** : Display Mono `3 / 5` + mini-barre + CTA "Reprendre la lecture"
- **Sous-tâches** : liste cochable inline + CTA disabled jusqu'à complétion
- **Timer** : Display Mono `20:00` + CTA "Démarrer le timer (20 min)"

Ajout du **graphique GitHub-style 30 jours** : 30 cellules verticales 8×40px (gap 2px), remplissage progressif en sauge (25% / 75% / 100%), border tertiaire pour les jours vides.

---

## 2. Nouvel écran · HB-EXECUTE

**Type** : modal bottom sheet (~92% hauteur), drag handle 36×4px en haut, fermeture × en haut à droite.

**Header** :
- Nom de l'habitude (H1 Geist SemiBold 22px)
- Sous-titre : dot catégorie + nom catégorie + horaire prévu
- Caption Mono : `20 min · pages · sauge`

**Footer sticky** :
- Bouton "Valider l'habitude" (pleine largeur, primaire ocre)
- État disabled (`--accent-disabled` 40%) avec caption explicative

### Variantes

| Variante | Contenu central | Validation |
|---|---|---|
| **A · Timer** | Anneau 240×240 (stroke 4px), Mono 56pt MM:SS au centre, 2 boutons ronds 64×64 (pause + arrêter) | Désactivée tant que timer tourne |
| **B · Objectif** | Mono 64pt `3 / 5`, sous-titre unité, mini-barre 80%, mode incrément (- / + ronds 64×64) **OU** input total | Activée si `actual ≥ target` |
| **C · Sous-tâches** | Liste 56px/row : checkbox 24×24 + titre + index Mono | Activée si toutes cochées (si obligatoires) |
| **D · Combiné** | Anneau réduit 160×160 + objectif Mono 36pt + liste sous-tâches | Toutes les conditions empilées |

### États documentés

- A : initial / running / pause
- B : 0/5 (vide) · 3/5 (partiel) · 5/5 (atteint) · 7/5 (dépassé, sauge)
- C : 3/5 (partiel) · 5/5 (toutes)
- D : combiné (partiel)

---

## 3. Écran admin · HAB-02 (Next.js)

Layout 2 colonnes (form 1fr + aperçu live 420px) en thème anthracite + ocre `#C4A87C`. Les 3 nouvelles sections sont signalées par un badge `NEW v1.5` ocre. L'aperçu de droite affiche en miniature `HBExecuteTimerInitial` à 70% de scale.

---

## 4. Conventions de nommage Flutter

| Composant Design | Widget Flutter (suggéré) |
|---|---|
| MiniProgressBar | `HabitProgressBar(actual, target, height)` |
| TimerBadge | `RunningTimerPill(remainingMs)` |
| CollapsibleSection | `EditFormSection(label, count?, toggle?)` |
| HBExecuteSheet | `ShowHabitExecuteSheet(habitId)` (helper) |
| TimerRing | `CountdownRing(progress, label)` |
| Github30dGraph | `Thirty DayBarChart(values)` |
| MiniCheckbox | `SubtaskCheckbox(checked)` |

**Modèle de données** (champs ajoutés au schéma Habit) :

```dart
class Habit {
  // ... champs v3 inchangés
  final HabitTarget? target;        // nullable — opt-in
  final List<Subtask> subtasks;     // [] si pas configuré
  final bool subtasksAllRequired;
  final bool timerEnabled;          // requires target.unit ∈ {minutes, hours}
}

class HabitTarget { final num value; final HabitUnit unit; final String? customLabel; }
class Subtask { final String id; final String title; final int order; bool done; }
```

---

## 5. Cohérence avec v3

**Préservé** :
- Palette terreuse intégrale (aucun nouveau token couleur)
- Typo Geist + Geist Mono (Mono partout pour les chiffres v1.5)
- Bordures 0.5px, rayons 16/10/6/100
- Aucun emoji, aucune ombre portée
- Bottom navigation conservée sur HM-01 et HB-01
- Composants existants réutilisés : `Phone`, `HeaderBack`, `HeaderTitle`, `BottomNav`, `card`, `chip`, `salat-btn`, `dot-status`, `btn-primary/secondary/ghost/destructive`, `input`, `field-label`, `label`, `display`, `caption`, `ProgressRing`, `Logo`

**Nouveaux composants introduits** :
- `MiniProgressBar` — primitive de progression 4–6px (HB-01, HB-DETAIL, HB-EXECUTE)
- `TimerBadge` + `PulseDot` — indicateur de timer actif
- `V15Toggle` — toggle iOS-like ocre (utilisé dans HB-02 sections + admin)
- `CollapsibleSection` — section pliable avec chevron + count + toggle
- `MiniCheckbox` — checkbox 24×24 ocre/blanche
- `Github30dGraph` — bar chart 30 jours en sauge progressive
- `BottomSheet` + `SheetHeader` + `StickyValidate` — shell pour HB-EXECUTE
- `TimerRing` — anneau de progression circulaire 240×240
- `RoundBtn` — bouton rond 64×64 (3 variants : primary / secondary / ghost)

Chaque composant respecte les tokens v3 — aucune valeur hardcodée hors palette.

---

## 6. Checklist 0.5 — autotest avant livraison

- [x] Design system v3 strictement respecté
- [x] Sections nouvelles cohérentes (mêmes paddings, labels uppercase 11px, captions 11px)
- [x] Tous les états représentés (3 variantes HB-DETAIL, 4 sous-variantes HB-EXECUTE × 4 états)
- [x] Bouton "Valider l'habitude" disabled quand conditions non remplies (B.1, B.2, C.1, D)
- [x] Graphique 30j en sauge progressive (3 niveaux + vide)
- [x] Aucun emoji
- [x] Aucune ombre portée
- [x] Bottom navigation préservée sur HM-01 et HB-01
- [x] Cohérence inter-écrans (MiniProgressBar identique sur HB-01, HB-DETAIL, HB-EXECUTE)

---

*Spec sheet v1.5 — Avril 2026*
