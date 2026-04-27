# ADR-003 — go_router vs alternatives de routing

**Date** : 2026-04-27
**Auteur** : Agent mobile (Phase 0)
**Statut** : Accepté

## Contexte

Murabbi Mobile a une navigation multi-écrans avec :
- Auth guards (redirect vers login si non authentifié)
- Navigation deep-link (notifications push → écran Salat)
- Navigation bottom tab + push (écrans imbriqués)

## Options évaluées

### A — Navigator 1.0 (imperative)
Simple mais pas de deep linking natif, pas d'URL-based routing, difficile à tester.

### B — AutoRoute
Codegen puissant mais lourd à configurer, moins maintenu que go_router.

### C — go_router 14.x (retenu)
Routing déclaratif URL-based, intégré officiellement dans Flutter. Support natif :
redirect guards, deep links, ShellRoute (bottom tabs), GoRouterState.

## Décision

**Option C retenue** — go_router 14.x.

## Conséquences

- Toutes les routes sont définies dans `lib/presentation/router/app_router.dart`
- Les routes sont nommées (`GoRoute(name: 'prayer', ...)`) pour la navigation programmatique
- Les auth guards utilisent `redirect` avec écoute du `authStateChanges`
- Les notifications push résolvent leur route via `GoRouter.of(context).go('/prayer')`
- Convention : `const routePrayer = '/prayer'` dans `lib/presentation/router/routes.dart`
