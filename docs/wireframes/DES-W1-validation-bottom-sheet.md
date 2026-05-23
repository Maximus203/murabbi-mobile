# DES-W1 — In-app Validation Bottom Sheet (post-notification)

> Issue : [#176](https://github.com/Maximus203/murabbi-mobile/issues/176)
> Milestone : Alert System v1 — Bloque MOB-007
> Pré-reads : CDC §13 (Alert System), ADR-018 (à créer), HB-02, SL-01

## 1. Objectif UX

Lorsqu'un utilisateur ouvre l'app après avoir reçu une notification d'habitude (ou
tape directement la notification), une **bottom sheet modale** s'affiche pour
permettre une action immédiate sans naviguer. Trois actions : **Done / Later / Dismiss**.

Critère de succès : 90% des validations doivent pouvoir être faites depuis cette
feuille en < 3s, sans navigation supplémentaire (cf. CDC §13.2).

## 2. Layout — État Normal (grace ouverte)

```
┌─────────────────────────────────────────────┐
│                                             │
│              ▂▂▂▂▂  (drag handle, 36×4)     │
│                                             │
│   ┌────┐                                    │
│   │ 📖 │  Lecture du Coran                  │  ← habit name + category icon
│   └────┘  Catégorie · Spirituel             │
│                                             │
│   ⏰ Prévue à 06:30 · 12 min ago            │  ← scheduled time + relative
│                                             │
│   ▰▰▰▰▰▰▰▰▱▱▱▱▱▱▱  Expire dans 8 min       │  ← grace progress bar
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │           ✓  Done                   │   │  ← Primary CTA (cream/green)
│   └─────────────────────────────────────┘   │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │     ⏱  Later          (1/2) ›       │   │  ← Secondary (sand)
│   └─────────────────────────────────────┘   │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │           ✕  Dismiss                │   │  ← Tertiary (ghost, muted)
│   └─────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

**Dimensions** : hauteur ~60% de la viewport (max 540px). Coins arrondis 24px top-left/top-right.
Background : `AppColors.surface` (crème), avec safe-area bottom respectée.

## 3. États

### 3.1 — Normal
Comme ci-dessus. Tous les boutons actifs, grace progress bar animée (60fps).

### 3.2 — Grace expired (avant minuit)

```
   ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰  ⚠ Trop tard pour valider

   ┌─────────────────────────────────────┐
   │     ✓  Done            (disabled)   │  ← grisé, opacity 0.4
   └─────────────────────────────────────┘

   ┌─────────────────────────────────────┐
   │     ⏱  Later           (disabled)   │
   └─────────────────────────────────────┘

   ┌─────────────────────────────────────┐
   │           ✕  Dismiss                │  ← seul actif
   └─────────────────────────────────────┘

   ↪  "Tu peux encore consigner en retard
       depuis le dashboard" (link → HB-02)
```

Couleur du header : `AppColors.warning` (sable foncé).

### 3.3 — Prayer mode (Fajr/Dhuhr/Asr/Maghrib/Isha)

Bouton **Later absent** (pas de snooze sur prière obligatoire — règle métier CDC §13.4).
Seuls **Done** et **Dismiss** affichés. La grace progress bar reste visible.

```
   ┌─────────────────────────────────────┐
   │           ✓  Prié                   │  ← libellé adapté
   └─────────────────────────────────────┘

   ┌─────────────────────────────────────┐
   │       ✕  Pas prié maintenant        │  ← libellé clarifie l'intention
   └─────────────────────────────────────┘
```

### 3.4 — Loading (après tap)

Le bouton tappé est remplacé par un spinner centré, les deux autres deviennent
`pointerEvents: none` (opacity 0.4). La sheet n'est plus dismissable (swipe down ignoré)
tant que l'API n'a pas répondu. Timeout : 8s → erreur inline.

### 3.5 — Erreur réseau

Toast en haut de la sheet : "Connexion perdue — réessayer". Sheet reste ouverte,
boutons réactivés. Retry automatique après 3s en arrière-plan.

## 4. Interactions

| Élément          | Action                       | Résultat                                          |
|------------------|------------------------------|---------------------------------------------------|
| Tap **Done**     | `validateOccurrence(onTime)` | Spinner → success haptic → sheet close + toast    |
| Tap **Later**    | open snooze picker (DES-W3)  | Transition slide vers picker inline (200ms)       |
| Tap **Dismiss**  | `dismissOccurrence(missed)`  | Confirm dialog ssi `dismissCount == 0` du jour    |
| Swipe down       | dismiss sheet                | Pas de log écrit (occurrence reste pending)       |
| Tap backdrop     | dismiss sheet                | Idem swipe down                                   |
| Hardware back    | dismiss sheet                | Idem swipe down                                   |

**Confirm dialog Dismiss** (1ère fois du jour seulement) :
> "Marquer comme non fait ? Tu peux encore consigner depuis le dashboard avant minuit."
> [Annuler] [Confirmer]

## 5. Données affichées (mapping data model)

| Champ UI                  | Source                                           | Statut data model |
|---------------------------|--------------------------------------------------|-------------------|
| Habit name                | `Habit.name`                                     | ✅ OK              |
| Category icon             | `Category.icon` via `Habit.categoryId`           | ✅ OK              |
| Category label            | `Category.name`                                  | ✅ OK              |
| Scheduled time            | `Occurrence.scheduledAt`                         | ❌ entité manquante |
| Grace expires at          | `Occurrence.graceExpiresAt`                      | ❌ champ manquant   |
| Grace progress %          | `(now - scheduledAt) / (graceExpiresAt - scheduledAt)` | derived     |
| Snooze count / max        | `Occurrence.snoozeCount` / `Habit.maxSnoozes`    | ❌ champs manquants |

## 6. Tokens

- Sheet bg : `AppColors.surface`
- Done CTA : `AppColors.primary` (cream/green) + texte `AppColors.onPrimary`
- Later CTA : `AppColors.sandLight` + texte `AppColors.onSurface`
- Dismiss CTA : transparent + border `AppColors.outline` + texte `AppColors.textMuted`
- Grace bar fill : `AppColors.primary` → `AppColors.warning` quand >70%
- Spinner : 24×24, color `AppColors.primary`
- Typographie : `AppTypography.titleM` (habit name), `bodyS` (caption), `labelL` (CTA)
- Espacement : 16px padding latéral, 12px gap entre CTAs
- Min tap target : 56×48 (boutons), 44×44 (drag handle)

## 7. Accessibilité

- `Semantics.label` explicite pour chaque CTA ("Valider l'habitude Lecture du Coran")
- Contraste min 4.5:1 sur tous les libellés
- Grace progress bar : `Semantics(value: '8 minutes restantes')`
- Disabled buttons : `Semantics(enabled: false, hint: 'Trop tard pour valider')`
- Animation respect `MediaQuery.disableAnimations`
- Sheet swipe alternative : bouton close visible si `MediaQuery.accessibleNavigation`

## 8. Edge cases

| Cas                                              | Comportement attendu                          |
|--------------------------------------------------|-----------------------------------------------|
| Sheet ouverte mais user kill l'app               | Au redémarrage : sheet réouverte si toujours dans grace |
| Plusieurs notifs en attente                      | Stack : on traite la plus ancienne, badge "+2" sur l'icône en haut à droite |
| Notif tape 2× rapidement                         | Debounce 500ms, une seule sheet ouverte       |
| Grace expire pendant que sheet ouverte           | Hot-swap vers état 3.2 sans fermer la sheet   |
| User sans connexion                              | Log enqueued localement, sheet ferme normalement, sync au retour réseau |
| Habit supprimée entre notif et ouverture         | Sheet affiche : "Cette habitude n'existe plus" + bouton close uniquement |

## 9. Animations

- Apparition : slide-up 250ms, ease-out, opacity 0→1
- Disparition : slide-down 200ms, ease-in
- Grace bar : update CSS transform (GPU), refresh 1×/seconde
- CTA tap : scale 0.97 pendant 80ms (haptic light)
- Success : sheet close + toast slide-up bottom (3s auto-dismiss)

## 10. Questions ouvertes (écarts data model + métier)

> Pour validation Cherif avant Phase MOB-007.

1. **Entité `Occurrence` absente du domaine.** Le système d'alertes manipule un objet
   distinct du `HabitLog` (statut `awaiting_validation`, `graceExpiresAt`,
   `snoozeCount`). Cette entité n'existe pas dans `lib/domain/entities/`. Faut-il
   l'ajouter (suggestion : `HabitOccurrence`) ou étendre `HabitLog` avec un statut
   `awaitingValidation` + champs `scheduledAt`/`graceExpiresAt` ?

2. **Champ `graceExpiresAt`.** Doit-il être stocké en absolu (`DateTime`) ou
   calculé à la volée à partir de `Habit.gracePeriodMinutes` (cf. DES-W4) +
   `scheduledAt` ? Le calculé est plus simple mais ne permet pas d'override
   serveur (ex. user en avion → grace étendue).

3. **`HabitLogStatus` incomplet.** L'enum actuel est `{onTime, late, missed}`.
   La bottom sheet écrit aussi `dismissed`. Faut-il l'ajouter ? Ou
   `missed` couvre-t-il les deux ? Recommandation : ajouter `dismissed` pour
   distinguer "user a dit non" vs "user n'a rien fait → expired".

4. **`maxSnoozes`.** Quelle est la valeur par défaut ? Le CDC suggère 2/2 dans
   DES-W3 mais ce n'est pas confirmé. Recommandation : default = 2, configurable
   en settings utilisateur (pas par habitude).

5. **Dismiss avec confirm dialog.** L'issue ne spécifie pas la confirmation. Je
   propose un confirm 1×/jour (premier dismiss) pour éviter les regrets, sans
   harceler. À valider.

6. **Empilage de notifications**. Si l'user reçoit 3 notifs avant d'ouvrir l'app,
   quel comportement ? Recommandation : pile FIFO, badge counter en haut de la
   sheet "1 sur 3", après chaque action la suivante s'ouvre automatiquement.
