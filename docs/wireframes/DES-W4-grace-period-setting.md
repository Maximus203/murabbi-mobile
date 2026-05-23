# DES-W4 — Habit Grace Period Setting in Habit Editor

> Issue : [#179](https://github.com/Maximus203/murabbi-mobile/issues/179)
> Milestone : Alert System v1
> Pré-reads : CDC §13.1, ADR-018, HB-02 (habit editor)

## 1. Objectif UX

Dans l'écran de création/édition d'habitude (HB-02), ajouter une section
**"Fenêtre de confirmation"** sous le toggle des notifications. Slider
configurable de **5 à 180 minutes** (default : 30 min). Visible uniquement si
`template.configurableFields` contient `grace_period_minutes`. Désactivé pour
les prières (valeur figée par le système).

## 2. Position dans HB-02

```
┌──────────────────────────────────────────────┐
│  ← Nouvelle habitude              Enregistrer│
│                                              │
│  [Nom] _______________________               │
│  [Catégorie] ___________________  ▾          │
│  ...                                         │
│  [Plage horaire] 06:00 — 08:00               │
│                                              │
│  ─────────────────────────────────           │
│  Notifications                               │
│  [●─────] Activer les rappels                │
│                                              │
│  ▼ ─── Section DES-W4 (état Active) ────────│
│                                              │
│  Fenêtre de confirmation                     │
│  ┌────────────────────────────────┐ ┌──────┐│
│  │ ●────────────────────          │ │30 min││  ← slider + value
│  └────────────────────────────────┘ └──────┘│
│   5min                          180min        │
│                                              │
│  Après le rappel, combien de temps as-tu     │  ← caption muted
│  pour confirmer ? Au-delà l'occurrence       │
│  passe en "manqué".                          │
│                                              │
│  ▲ ─────────────────────────────────────────│
└──────────────────────────────────────────────┘
```

## 3. États

### 3.1 — Active (default)

```
   Fenêtre de confirmation                     ⓘ
   ┌────────────────────────────────┐ ┌──────┐
   │ ●────────────────────          │ │30 min│
   └────────────────────────────────┘ └──────┘
    5min                          180min

   Après le rappel, combien de temps as-tu
   pour confirmer ?
```

- Slider Material 3 (Flutter `Slider` widget tuné)
- Track inactive : `AppColors.outline`
- Track active : `AppColors.primary`
- Thumb : 24×24, `AppColors.primary`, élévation 2
- Value pill : 60×32, bg `AppColors.sandLight`, `labelL`, met à jour en live
- Steps : par pas de 5min jusqu'à 60, puis par pas de 15min de 60 à 180
  (12 + 8 = 20 stops total)
- Tap `ⓘ` → BottomSheet info expliquant la mécanique grace + lien CDC

### 3.2 — Disabled (prayer habit)

```
   Fenêtre de confirmation                     ⓘ
   ┌──────────────────────────────────────────┐
   │ 🔒 Valeur fixée par le système (10 min)  │
   └──────────────────────────────────────────┘
   Les prières ont une fenêtre standardisée
   pour respecter les horaires canoniques.
```

- Bg : `AppColors.surfaceVariant`
- Icône 🔒 : `AppColors.textMuted`
- Pas de slider, pas d'interaction
- Le tap sur le bloc déclenche un toast "Non modifiable pour les prières"

### 3.3 — Hidden (`grace_period_minutes` not in `configurableFields`)

La section **n'est pas rendue du tout**. Pas de placeholder, pas de séparateur
supplémentaire. C'est le cas pour certains templates pré-définis (ex. "Goûter
des dattes" — pas de notion de grace).

### 3.4 — Edge: valeur invalide à l'édition

Si l'habitude existante a une valeur hors range (legacy, migration), le slider
clamp à la borne la plus proche au chargement et un toast informatif s'affiche :
"Fenêtre ajustée à 5 min (valeur précédente non supportée)".

## 4. Interactions

| Élément          | Action                  | Résultat                                  |
|------------------|-------------------------|-------------------------------------------|
| Drag thumb       | Slide gauche-droite     | Value pill update en temps réel (haptic light tous les 30 min) |
| Tap track        | Tap n'importe où        | Thumb jump à la position, snap au step    |
| Tap value pill   | (no-op V1)              | Future : ouvrir input numérique direct    |
| Tap `ⓘ`          | Ouvre info sheet        | BottomSheet 40% hauteur expliquant grace  |
| Tap zone disabled| Toast                   | "Non modifiable pour les prières"         |

## 5. Données affichées (mapping)

| Champ UI                  | Source                                       | Statut data model |
|---------------------------|----------------------------------------------|-------------------|
| Valeur initiale slider    | `Habit.gracePeriodMinutes` (ou template default) | ❌ champ manquant |
| Valeur sauvegardée        | `Habit.gracePeriodMinutes` à `onSave`        | ❌                 |
| Visibilité section        | `HabitTemplate.configurableFields.contains('grace_period_minutes')` | ❌ entité absente |
| Valeur figée (prière)     | `HabitTemplate.fixedGracePeriodMinutes` (ex. 10 pour prières) | ❌            |

## 6. Tokens

| Élément              | Token                                |
|----------------------|--------------------------------------|
| Track inactive       | `AppColors.outline`                  |
| Track active         | `AppColors.primary`                  |
| Thumb                | `AppColors.primary` + shadow level 2 |
| Value pill bg        | `AppColors.sandLight`                |
| Value pill text      | `AppTypography.labelL`               |
| Caption              | `AppTypography.bodyS`, `AppColors.textMuted` |
| Section title        | `AppTypography.titleS`               |
| Disabled bg          | `AppColors.surfaceVariant`           |
| Lock icon            | `AppColors.textMuted`                |
| Spacing              | 16px section padding, 12px gap inter-éléments |
| Slider height        | 48px tap zone, 4px visual track      |

## 7. Accessibilité

- `Semantics.slider` avec `value`, `min`, `max`, `step`
- Annonce TalkBack : "Fenêtre de confirmation, slider, 30 minutes, glisse pour ajuster de 5 à 180"
- Drag avec accessibility actions : `increase` / `decrease` (step 5)
- Value pill : `Semantics.liveRegion` pour annoncer le changement
- Section disabled : `Semantics(enabled: false, label: 'Fenêtre fixée à 10 minutes')`
- Contraste track active vs inactive ≥ 3:1 (validé sur palette crème)

## 8. Edge cases

| Cas                                          | Comportement                                  |
|----------------------------------------------|-----------------------------------------------|
| User change template avec / sans grace      | Section apparait/disparait avec fade 150ms ; valeur préservée si re-show |
| Network coupé à l'enregistrement             | Save local optimiste + retry sync arrière-plan |
| Habit avec notifications désactivées         | Section grisée (pas masquée) : "Active les rappels pour configurer" |
| Slider à 5 min + grace pratique très courte  | Warning subtil sous le slider : "Fenêtre courte — assure-toi d'être réactif" (affiché si < 10) |
| Slider à 180 min                             | Pas de warning, c'est valide                  |
| Value clipboard paste                        | N/A V1 (slider only)                          |

## 9. Animations

- Drag : thumb suit le doigt sans easing
- Snap au release : 120ms ease-out vers le step le plus proche
- Value pill : tween du nombre (300ms `Curves.easeOut`)
- Apparition/masquage section : 150ms fade + 150ms height (200ms total)
- Disabled state hover/tap : pas d'animation (statique)

## 10. Questions ouvertes

1. **`HabitTemplate` entité absente.** Le pattern "configurable_fields" suppose
   une entité Template référencée par chaque Habit (type prière, lecture, dhikr,
   etc.). Cette entité n'existe pas dans `lib/domain/entities/`. À créer ?
   Sinon, comment décider de l'affichage conditionnel ?

2. **Range & default**. Issue dit 5-180 min, je propose default 30. À valider :
   - Default 30 min est-il acceptable ?
   - Pour les prières, valeur fixe = 10 min (mon hypothèse) — à confirmer.

3. **Granularité du slider**. Continue (1 min step), 5 min, ou hybride
   (5/15) ? Recommandation hybride : pas fin pour les valeurs courtes (où ça
   compte) et grossier au-dessus.

4. **Warning "fenêtre courte"**. Faut-il avertir l'user qu'une grace de 5min
   risque de générer beaucoup de "missed" ? Recommandation : warning soft
   (texte caption coloré, pas de modal bloquant) si < 10.

5. **Édition vs création**. Si l'user édite une habitude existante avec des
   occurrences en cours, le changement de grace s'applique uniquement aux
   futures occurrences ou rétroactivement ? Recommandation : futures uniquement.

6. **Settings global vs per-habit**. Y aura-t-il aussi un default grace global
   dans les settings utilisateur ? Recommandation : non en V1, juste les
   defaults par template.
