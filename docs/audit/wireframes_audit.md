# Audit Wireframes — Phase 0

**Date** : 2026-04-27
**Auditeur** : Agent mobile (Phase 0)
**Source attendue** : `docs/wireframes/bundle/Murabbi Wireframes.html`

## Statut

**BLOQUANT** : Les wireframes Hi-Fi ne sont pas encore disponibles dans le repo.

Le fichier `docs/wireframes/bundle/Murabbi Wireframes.html` (28 écrans attendus) n'a pas
été fourni. L'audit sera complété dès réception des wireframes.

## Action requise

Cherif : copier les wireframes depuis `murabbi-admin/docs/wireframes/mobile/` vers
`murabbi-mobile/docs/wireframes/bundle/` (synchronisation miroir selon CLAUDE.md §0).

## Structure attendue de l'audit (à compléter)

| ID | Écran | Section | Actions utilisateur | États couverts | Incohérences |
|----|-------|---------|---------------------|----------------|--------------|
| W-01 | Splash / Onboarding | Auth | — | loading | — |
| W-02 | Sign In | Auth | email, password, submit | loading/success/error | — |
| W-03 | Sign Up | Auth | displayName, email, password, submit | loading/success/error | — |
| W-04 | Home / Dashboard | Dashboard | — | loading/success/empty | — |
| W-05 | Tracker Salat | Prayer | markPrayer, viewHistory | loading/success | — |
| W-06 | Historique Salat | Prayer | scroll, filtre date | loading/success/empty | — |
| W-07 | Liste Habitudes | Habits | add, toggle, delete | loading/success/empty | — |
| W-08 | Créer Habitude | Habits | form, submit | loading/success/error | — |
| W-09 | Détail Habitude | Habits | edit, delete, heatmap | loading/success | — |
| W-10 | Heatmap Habitude | Habits | scroll | loading/success/empty | — |
| W-11 | Liste Catégories | Categories | add, select | loading/success/empty | — |
| W-12 | Créer Catégorie | Categories | form, submit | loading/success/error | — |
| W-13 | Collections | Collections | browse, activate | loading/success/empty | — |
| W-14 | Détail Collection | Collections | activate, view habits | loading/success | — |
| W-15 | Créer Collection | Collections | form, add habits, submit | loading/success/error | — |
| W-16 | Scoring / Progression | Score | view level, progress | loading/success | — |
| W-17 | Leaderboard | Score | scroll, rank | loading/success/empty | — |
| W-18 | Profil utilisateur | Settings | edit, view score | loading/success | — |
| W-19 | Paramètres | Settings | notifications, theme | — | — |
| W-20 | Paramètres notifications | Settings | plages horaires | — | — |
| W-21 | Suppression compte | Settings | confirm, saisie DELETE | loading/success/error | — |
| W-22 | Onboarding step 1 | Onboarding | next | — | — |
| W-23 | Onboarding step 2 | Onboarding | next | — | — |
| W-24 | Onboarding step 3 | Onboarding | next, finish | — | — |
| W-25 | Empty state Salat | Prayer | — | empty | — |
| W-26 | Empty state Habitudes | Habits | — | empty | — |
| W-27 | Empty state Leaderboard | Score | — | empty | — |
| W-28 | Erreur réseau | Global | retry | error | — |

> Inventaire basé sur la logique produit (CLAUDE.md A.1). À valider et compléter
> une fois les wireframes fournis.

## Questions ouvertes

Voir `docs/questions/Q-01-audit-wireframes.md`.
