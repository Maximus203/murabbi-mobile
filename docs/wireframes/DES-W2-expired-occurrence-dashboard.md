# DES-W2 — Expired Occurrence State in Dashboard

> Issue : [#177](https://github.com/Maximus203/murabbi-mobile/issues/177)
> Milestone : Alert System v1 — Bloque MOB-007
> Pré-reads : CDC §13.5 (états des occurrences), ADR-018, HB-02

## 1. Objectif UX

Sur le dashboard du jour, l'utilisateur doit identifier **en moins de 2 secondes**
quelles habitudes ont été manquées, et savoir si un rattrapage est encore possible.
Trois états de carte : **Late (rattrapable)**, **Missed (grace expirée même jour)**,
**Expired (après minuit, plus rattrapable)**.

## 2. Header Dashboard — Badge counter

```
┌──────────────────────────────────────────────┐
│  Aujourd'hui                          ⚙      │
│  Lundi 23 mai · 14:32                        │
│                                              │
│  ┌────┐ ┌──────────────────────────────────┐ │
│  │ 7  │ │ ⚠ 3 habitudes en attente         │ │  ← badge pending count
│  │/12 │ │ Tap pour voir →                  │ │
│  └────┘ └──────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

- Badge `3` = nb d'occurrences en statut `awaiting_validation` ou `late`
- Tap sur la pill → scroll smooth vers la première carte pending (offset 80px haut)
- Badge masqué si count = 0
- Si count > 99 → "99+"

## 3. Variants de carte habitude

### 3.1 — Carte Late (catchup possible, avant minuit)

```
┌──────────────────────────────────────────────┐
│  ┌────┐                                       │
│  │ 📖 │  Lecture du Coran                     │
│  └────┘  ━━━ 06:30                       🟠   │  ← time strikethrough
│                                          Late │
│                                               │
│  ⏰ Grace expirée il y a 2h47                 │
│  Tu peux encore le consigner avant 23:59      │
│                                               │
│  ┌──────────────────────┐ ┌────────────────┐  │
│  │  ✓ Consigner quand   │ │  ✕ Abandonner  │  │
│  │     même             │ │                │  │
│  └──────────────────────┘ └────────────────┘  │
└──────────────────────────────────────────────┘
```

- Background : `AppColors.warning.withAlpha(0.08)` (sable léger)
- Border-left : 4px solid `AppColors.warning`
- Badge "Late" : pill orange, `labelS`, 12px padding horizontal
- "Consigner quand même" → ouvre validation modal (DES-W1 état spécial: pas de grace bar, juste les 2 CTAs Done/Dismiss avec `outcome = late`)

### 3.2 — Carte Missed (grace expirée, day-of, sans flag late)

```
┌──────────────────────────────────────────────┐
│  ┌────┐                                       │
│  │ 📖 │  Lecture du Coran                     │
│  └────┘  ━━━ 06:30                       🔴   │
│                                       Manqué  │
│                                               │
│  La fenêtre de validation est terminée.       │
│  Reviens demain inchAllah.                    │
└──────────────────────────────────────────────┘
```

- Background : `AppColors.error.withAlpha(0.05)`
- Border-left : 4px solid `AppColors.error`
- Pas de CTA (state final intra-jour)
- Texte secondaire : `AppColors.textMuted`

> **Note métier** : Late vs Missed dépend de la config habit (`allowLateCatchup: bool`).
> Si l'habitude permet le rattrapage jusqu'à minuit → état Late. Sinon → Missed direct
> après grace. Voir question ouverte §8.1.

### 3.3 — Carte Expired (après minuit, J+1+)

```
┌──────────────────────────────────────────────┐
│  ┌────┐                                       │
│  │ 📖 │  Lecture du Coran               ▣     │  ← muted icon
│  └────┘  ━━━ 06:30 (hier)               ⚫    │
│                                       Expiré  │
└──────────────────────────────────────────────┘
```

- Background : `AppColors.surface` (neutre)
- Border : 1px `AppColors.outlineMuted`
- Tout en `AppColors.textMuted`, opacity 0.6
- Cliquable mais : tap → toast "Cette occurrence n'est plus modifiable"
- Apparaît uniquement dans la vue Historique (Calendar), pas dans Today

### 3.4 — Empty state (0 pending)

```
┌──────────────────────────────────────────────┐
│                                              │
│              🌿  (illustration)              │
│                                              │
│           Tout est à jour                    │
│                                              │
│  Aucune habitude en attente. Continue        │
│            comme ça !                        │
│                                              │
│      ┌─────────────────────────────┐         │
│      │   + Ajouter une habitude    │         │
│      └─────────────────────────────┘         │
│                                              │
└──────────────────────────────────────────────┘
```

- Affiché uniquement si **et** count pending = 0 **et** aucune habit du jour
- Si pending = 0 mais habits du jour OK : pas d'empty state, juste le dashboard normal
- Illustration : `assets/illustrations/empty_pending.svg` (à créer)

## 4. Interactions

| Élément                         | Action                                                  |
|---------------------------------|---------------------------------------------------------|
| Tap "Consigner quand même"      | Ouvre DES-W1 bottom sheet en mode `late`, grace bar absente |
| Tap "Abandonner"                | Confirm dialog → marque `dismissed/missed`              |
| Tap header badge "3 en attente" | Scroll smooth vers 1ère carte Late                      |
| Long-press carte                | Menu contextuel : Voir détails / Désactiver notifs auj. |
| Swipe gauche sur carte Late     | Action rapide : Consigner (équivalent au CTA)           |
| Swipe droite sur carte Late     | Action rapide : Abandonner                              |

## 5. Données affichées (mapping)

| Champ UI                  | Source                                          | Statut data model |
|---------------------------|-------------------------------------------------|-------------------|
| Habit name                | `Habit.name`                                    | ✅                 |
| Habit icon                | `Category.icon`                                 | ✅                 |
| Scheduled time            | `Occurrence.scheduledAt`                        | ❌ entité manquante |
| "Grace expirée il y a..." | `now() - Occurrence.graceExpiresAt`             | ❌                 |
| Pending count badge       | `count(occurrences WHERE status IN (awaiting,late))` | ❌            |
| Late catchup deadline     | `endOfDay(scheduledAt)` ou champ explicite ?    | ❓                 |

## 6. Tokens

| Élément          | Token                                    |
|------------------|------------------------------------------|
| Late bg          | `AppColors.warning.withAlpha(0.08)`      |
| Late border-left | `AppColors.warning` 4px                  |
| Missed bg        | `AppColors.error.withAlpha(0.05)`        |
| Missed border    | `AppColors.error` 4px                    |
| Expired bg       | `AppColors.surface`                      |
| Expired text     | `AppColors.textMuted`                    |
| Strikethrough    | `TextDecoration.lineThrough` + `AppColors.textMuted` |
| Pill Late        | bg `AppColors.warning`, fg `AppColors.onWarning`     |
| Pill Missed      | bg `AppColors.error`, fg `AppColors.onError`         |
| Pill Expired     | bg `AppColors.outline`, fg `AppColors.textMuted`     |
| Border radius    | 16px (cartes), 999px (pills)             |

## 7. Accessibilité

- Information jamais portée par la couleur seule : badge texte + icône emoji
- `Semantics.label` carte : "Habitude Lecture du Coran, en retard, prévue à 6h30, encore consignable"
- Tap target min 56px hauteur carte, 48px CTAs
- Strikethrough lue par TalkBack/VoiceOver : "prévue à 6h30 (annulée)"
- Empty state illustration : `Semantics.label: "Aucune habitude en attente"`
- Animation badge pulse : respect `disableAnimations`

## 8. Edge cases

| Cas                                          | Comportement                                  |
|----------------------------------------------|-----------------------------------------------|
| Habitude permet `frequency=3/jour`, 2 ratées | 2 cartes Late distinctes ? Ou 1 carte "2/3 manqués" ? **À valider §8.2** |
| User dans fuseau horaire différent           | "Avant minuit" = minuit du fuseau user (`Habit.timezone` ou device tz) |
| Refresh dashboard à 23:59 → 00:01            | Cartes Late migrent automatiquement vers historique en Expired |
| 50+ habitudes Late simultanément             | Pagination par 20 dans la liste, "Voir plus" en bas |
| Habit supprimée alors qu'occurrence Late     | Carte affichée avec icône poubelle + "Habitude supprimée" |

## 9. Animations

- Apparition cartes : staggered 50ms entre chaque, slide-up 200ms
- Tap CTA : scale 0.98 + haptic light
- Migration Late → Expired (passage minuit) : fade-out 300ms, retire de la liste
- Badge counter : pulse 1.05 → 1.0 sur changement de valeur

## 10. Questions ouvertes

1. **Late vs Missed — règle de bascule.** Le wireframe distingue Late (catchup OK)
   de Missed (catchup interdit). Cette distinction existe-t-elle au niveau habit
   (`allowLateCatchup`) ou est-ce une règle globale ? Si globale : on supprime
   l'état Missed §3.2 et toute occurrence après grace = Late jusqu'à minuit.

2. **Frequency > 1/jour.** Une habitude `perDay = 3` génère 3 occurrences/jour.
   Comment grouper sur le dashboard ? Recommandation : 1 carte parent + chips
   d'état par occurrence (3 dots colorés sous le nom). Sinon le dashboard
   devient illisible.

3. **`Occurrence.deadline` calculé ou stocké ?** Pour "avant 23:59" : on assume
   `endOfDay(scheduledAt, timezone)` ou colonne dédiée `catchupDeadline` ?

4. **Pending counter — quoi compter exactement ?**
   - (a) `awaiting_validation` uniquement (grace pas encore expirée)
   - (b) `awaiting_validation + late` (tout ce qui demande action user)
   - (c) inclure aussi `snoozed` ?
   Recommandation : (b). À valider.

5. **Empty state — illustration**. À fournir par design (SVG ~120px), pas encore
   dans `assets/illustrations/`. Issue de suivi à ouvrir.

6. **Long-press menu**. "Désactiver notifs aujourd'hui" — règle inédite. Cela
   crée-t-il une exception OneOff dans la table notifications ? Persistant
   jusqu'à minuit puis auto-réactivé ? À spécifier.
