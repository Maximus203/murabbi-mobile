# ADR-002 — Riverpod codegen vs alternatives

**Date** : 2026-04-27
**Auteur** : Agent mobile (Phase 0)
**Statut** : Accepté

## Contexte

Murabbi Mobile a besoin d'un système de gestion d'état qui supporte :
- L'injection de dépendances des use cases
- La réactivité (streams Supabase, mise à jour UI)
- La testabilité (overrides pour les mocks)
- La scalabilité sur 6 phases de développement

## Options évaluées

### A — Provider (legacy)
Pattern simple mais sans types forts, pas de codegen, déprécié pour les nouveaux projets.

### B — Riverpod 2.x sans codegen
API manuelle avec `Provider`, `StateNotifierProvider`, `FutureProvider`. Verbeux,
risque d'erreurs de type au runtime.

### C — Riverpod 2.x avec codegen (retenu)
Annotations `@riverpod` + `build_runner` génèrent le boilerplate. Types forts garantis
à la compilation. Support natif pour `AsyncValue`, `family`, `keepAlive`.

### D — Bloc / Cubit
Pattern plus structuré mais plus verbeux. BlocProvider vs Riverpod : Riverpod gagne
sur la testabilité et l'ergonomie pour ce type de projet.

## Décision

**Option C retenue** — Riverpod 2.x avec codegen (`riverpod_annotation` + `riverpod_generator`).

## Conséquences

- Tous les providers utilisent `@riverpod` — zéro `Provider` legacy
- `build_runner` doit être relancé après chaque modification d'un provider annoté
- Les fichiers `*.g.dart` sont gitignored (générés)
- En test, `ProviderContainer` avec `.overrideWith()` remplace les dépendances réelles
- Convention de nommage : `habitListProvider`, `prayerDayProvider(date)` (camelCase + suffix `Provider`)
