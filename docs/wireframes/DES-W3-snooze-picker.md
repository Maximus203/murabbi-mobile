# DES-W3 — Snooze Picker + Snooze Exhausted State

> Issue : [#178](https://github.com/Maximus203/murabbi-mobile/issues/178)
> Milestone : Alert System v1 — Bloque MOB-007
> Pré-reads : CDC §13.3, ADR-018, DES-W1 (bottom sheet parent)

## 1. Objectif UX

Quand l'utilisateur tape **Later** dans la bottom sheet DES-W1, on remplace
inline les 3 boutons par un picker à 3 pills (+5/+10/+20 min). Limiter à
**2 snoozes max** par occurrence (config par défaut, prière = 0). Au-delà :
bouton Later grisé avec tooltip explicatif.

## 2. État Picker ouvert (inline dans la bottom sheet)

```
┌─────────────────────────────────────────────┐
│              ▂▂▂▂▂                          │
│                                             │
│   ┌────┐                                    │
│   │ 📖 │  Lecture du Coran                  │
│   └────┘  Catégorie · Spirituel             │
│                                             │
│   ⏰ Prévue à 06:30                         │
│                                             │
│   Rappelle-moi dans...                      │
│                                             │
│   ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│   │  + 5min  │ │  + 10min │ │  + 20min │    │  ← pill chips
│   └──────────┘ └──────────┘ └──────────┘    │
│                                             │
│   ↪ Annuler                                 │  ← retour à DES-W1
│                                             │
│                                  1/2 utilisé│  ← snooze count info
└─────────────────────────────────────────────┘
```

- Pill : 88×44px min, border-radius 999px, bg `AppColors.sandLight`, border 1px `AppColors.outline`
- Pill active (tap-hold) : bg `AppColors.primary`, fg `AppColors.onPrimary`
- Transition depuis DES-W1 : crossfade 180ms, hauteur de sheet inchangée

## 3. État Snooze actif (carte dashboard après confirmation)

```
┌──────────────────────────────────────────────┐
│  ┌────┐                                       │
│  │ 📖 │  Lecture du Coran                     │
│  └────┘  ⏰ 06:30                       💤    │
│                                      Snoozé  │
│                                               │
│  ⏱  Nouveau rappel dans 8 min                │  ← live countdown
│                                               │
│       ┌─────────────────────────┐             │
│       │  ✓ Consigner maintenant │             │  ← raccourci immédiat
│       └─────────────────────────┘             │
└──────────────────────────────────────────────┘
```

- Border-left 4px `AppColors.info` (bleu sable)
- Countdown texte mis à jour chaque minute (pas chaque seconde — économie batterie)
- "Consigner maintenant" → ouvre DES-W1 directement
- Si user re-tap notif avant fin du snooze → DES-W1 s'ouvre normalement

## 4. État Snooze épuisé (2/2 atteint)

Dans la bottom sheet DES-W1 :

```
   ┌─────────────────────────────────────┐
   │     ✓  Done                         │
   └─────────────────────────────────────┘

   ┌─────────────────────────────────────┐
   │  ⏱  Later  (2/2)            ⓘ       │  ← grisé, opacity 0.4
   └─────────────────────────────────────┘
        │
        └─ Tap → tooltip (200ms delay) :
           "Tu as utilisé tes 2 rappels.
            Valide ou abandonne maintenant."

   ┌─────────────────────────────────────┐
   │           ✕  Dismiss                │
   └─────────────────────────────────────┘
```

- Pill counter "(2/2)" : couleur `AppColors.error`
- Tooltip : positionnement top of button, flèche pointant vers bouton
- Long-press déclenche aussi le tooltip (pour TalkBack)

## 5. État Prayer mode

**Le bouton Later est complètement absent** (pas grisé — supprimé) sur les
5 prières obligatoires. Le picker n'est jamais accessible.

```
   ┌─────────────────────────────────────┐
   │           ✓  Prié                   │
   └─────────────────────────────────────┘

   ┌─────────────────────────────────────┐
   │       ✕  Pas prié maintenant        │
   └─────────────────────────────────────┘
```

Pas de "(0/0)" affiché — silence total sur la fonctionnalité snooze.

## 6. Animations & micro-interactions

- Pill tap : scale 0.93 + bg flash `AppColors.primary` 100ms + haptic medium
- Confirmation snooze : sheet close + toast bottom "Rappel programmé dans 10 min" (3s)
- Annuler : retour à DES-W1 en crossfade inverse 180ms
- Countdown carte dashboard : update sans flicker (animated number tween 300ms)

## 7. Interactions complètes

| État              | Action                  | Résultat                                |
|-------------------|-------------------------|-----------------------------------------|
| Picker ouvert     | Tap pill                | Snooze confirmé → sheet close + toast   |
| Picker ouvert     | Tap "Annuler"           | Retour DES-W1 (3 boutons)               |
| Picker ouvert     | Swipe down              | Dismiss sheet, pas de snooze écrit      |
| Picker ouvert     | Tap backdrop            | Idem swipe down                         |
| Snooze actif      | Tap notif (au déclenchement) | Re-ouvre DES-W1                    |
| Snooze actif      | Tap "Consigner maintenant" | Ouvre DES-W1 sans attendre fin       |
| Snooze épuisé     | Tap Later (grisé)       | Tooltip 3s + haptic warning             |

## 8. Données affichées (mapping)

| Champ UI                   | Source                                        | Statut data model |
|----------------------------|-----------------------------------------------|-------------------|
| Snooze count / max         | `Occurrence.snoozeCount` / `Habit.maxSnoozes` | ❌ champs manquants |
| Countdown "X min"          | `Occurrence.snoozeUntil - now()`              | ❌                 |
| Durées disponibles         | Constante client `[5, 10, 20]` minutes        | ✅ (en dur, OK V1) |

## 9. Tokens

- Pill bg idle : `AppColors.sandLight`
- Pill bg active : `AppColors.primary`
- Pill border : 1px `AppColors.outline`
- Pill text : `AppTypography.labelL`, `AppColors.onSurface` idle
- Counter pill text (2/2 épuisé) : `AppColors.error`
- Tooltip bg : `AppColors.inverseSurface`, text `AppColors.inverseOnSurface`
- Countdown card : `AppColors.info` border, `AppColors.infoMuted` bg
- Sheet bg inchangée : `AppColors.surface`
- Animations : durée < 250ms, easing `Curves.easeOutCubic`

## 10. Accessibilité

- Pills : tap target 88×44 (largeur dépasse minimum sur axes serrés)
- `Semantics.button` + label "Rappeler dans 5 minutes"
- Bouton Later grisé : `Semantics(enabled: false, hint: 'Maximum de rappels atteint, 2 sur 2')`
- Tooltip : `Semantics.liveRegion` pour TalkBack
- Countdown : pas annoncé à chaque seconde (uniquement updates par minute pour ne pas saturer)
- Tap hint long-press = tooltip pour utilisateurs sans hover

## 11. Edge cases

| Cas                                          | Comportement                                  |
|----------------------------------------------|-----------------------------------------------|
| User snooze, puis kill l'app                 | Notification locale planifiée OS → tire à l'heure même app fermée |
| Snooze 20min + autre habit notif entre       | Les 2 notifs coexistent, file FIFO            |
| Snooze repousse au-delà de la grace deadline | **À valider §12.1** — soit refus avec toast, soit auto-extension grace |
| Snooze repousse après minuit                 | Le snooze tire J+1 mais marque l'occurrence J-1 → Expired automatiquement, snooze ignoré |
| User change `maxSnoozes` en settings de 2→0  | Snoozes en cours préservés, nouveaux refusés  |
| User en DND (Ne pas déranger)                | Snooze planifié normalement, OS gère silence  |

## 12. Questions ouvertes

1. **Snooze qui dépasse la grace deadline.** Si grace expire à 06:42 et user
   snooze +20min à 06:35 → reminder à 06:55 alors que c'est déjà trop tard.
   - Option A : refus avec toast "Pas assez de temps avant expiration"
   - Option B : autoriser, l'occurrence sera en état Late au moment du reminder
   - Option C : étendre automatiquement la grace de 20min
   Recommandation : Option B (cohérent avec catchup Late) + warning visuel sur la pill.

2. **`maxSnoozes` configurable où ?** Par habitude (`Habit.maxSnoozes`) ou
   global utilisateur (`UserSettings.maxSnoozes`) ? Recommandation : global
   pour V1 (simplifie l'UX), per-habit en V1.5 si besoin.

3. **Durées personnalisables ?** Les 3 chips sont en dur (`5/10/20`). Faut-il
   permettre à l'user de choisir ses propres durées en settings ? Recommandation :
   non en V1, oui en V2 (post-feedback).

4. **Snooze d'un snooze.** Quand le reminder du snooze tire, l'user peut à
   nouveau tap Later → consomme le 2e snooze ? Confirmation : oui, c'est
   le compteur 2/2 qui limite quel que soit le nombre de cycles.

5. **Tooltip sur web/desktop ?** L'app est mobile-only V1 mais Flutter permet
   le portage. Le tooltip sur hover serait-il OK pour V2 ? Non bloquant.
