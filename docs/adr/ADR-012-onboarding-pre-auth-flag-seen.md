# ADR-012 — Onboarding pédagogique pre-auth & flag `onboarding_seen`

**Statut** : Accepté
**Date** : 2026-05-08
**Décideur** : Cherif (PO) + agent senior
**Lié** : Q3-A (gating onboarding pre/post-auth), ADR-003 (go_router), Q-18 (schéma `users`)

## Contexte

En fin de Phase 2 (auth + navigation), la règle de redirection en place
envoyait tout visiteur non authentifié sur `/auth/login`. Conséquence :
le walkthrough pédagogique de 4 slides (`Setup01OnboardingScreen`)
n'était jamais vu par un visiteur — il n'apparaissait que pour un user
déjà authentifié non onboardé, ce qui ne correspond pas à la fonction
"vitrine produit" portée par les slides.

Le PO a tranché : l'onboarding doit être **pré-auth** (marketing /
pédagogique), pas un onboarding de configuration de compte.

Deux options ont été envisagées :
- **A** — un seul flag `onboarding_seen` (pré-auth uniquement). Pas de
  configuration utilisateur dans le walkthrough. Si un onboarding
  post-auth de settings est nécessaire plus tard, on ajoutera un second
  flag (probablement côté `users.account_setup_completed_at`).
- **B** — deux flags d'emblée (`onboarding_seen` pré-auth +
  `account_setup_completed` post-auth). Plus structuré mais introduit du
  code mort tant qu'aucun écran de settings prière / d'objectifs n'est
  câblé en Phase 3.

## Décision

**Option A — un seul flag `onboarding_seen`** stocké en
SharedPreferences (`onboarding_seen_v1`). Pas de second flag pour
l'instant. La règle `authRedirect` devient :

| Session | `onboarding_seen` | Route hors-auth | Comportement |
|---|---|---|---|
| ❌ | `false` | autre que `/onboarding` ou auth | redirige vers `/onboarding` |
| ❌ | `false` | route auth (`/auth/login`, `/auth/signup`, `/auth/forgot`) | autorisé (l'utilisateur peut sauter) |
| ❌ | `true` | autre que routes auth ou `/onboarding` | redirige vers `/auth/login` |
| ✅ | n/a | toute route auth ou splash ou `/onboarding` | redirige vers `/home` |
| ✅ | n/a | `/auth/verify-email` | toujours autorisé (sas transient post-signUp) |

### Migration douce

Le flag historique `onboarding_completed_v1` est lu en fallback : si un
user a déjà ouvert une version pre-Q3-A et a marqué l'onboarding
terminé, on considère le nouveau `onboarding_seen_v1` comme `true` et
on persiste la migration au premier `isCompleted()`. Un legacy à
`false` n'est pas migré (on veut que l'utilisateur voie le nouveau
walkthrough s'il ne l'a jamais validé).

## Conséquences

### Positives
- Le walkthrough pédagogique remplit enfin son rôle de vitrine.
- Pas de couplage prématuré avec la table `users` côté admin (Q-18) —
  on garde le flag local le temps que la Phase 3 stabilise les
  settings utilisateur.
- Migration douce : aucune régression pour les utilisateurs existants.

### Négatives
- Un visiteur qui change de device revoit le walkthrough une fois
  (acceptable — c'est cohérent avec un onboarding marketing).
- Si Phase 3 introduit un onboarding post-auth (settings prière,
  méthode de calcul, objectifs), il faudra ajouter un second flag.
  C'est tracé en TODO dans `lib/services/onboarding_flag_storage.dart`
  et dans cet ADR (`account_setup_completed_at` côté admin probable).

### TODO Phase 3
- [ ] Si un onboarding post-auth est ajouté, créer
      `account_setup_completed_at` dans `users` (admin) et exposer un
      second `AsyncNotifier<bool>` côté mobile.
- [ ] Étendre `authRedirect` pour gérer ce second flag.
