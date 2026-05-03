# ADR-004 — Couche d'accès Supabase (datasource pattern)

**Date** : 2026-04-27
**Auteur** : Agent mobile (Phase 0)
**Statut** : Accepté

## Contexte

Les repository interfaces (`domain/repositories/`) doivent être implémentées en Phase 2+.
La question est : comment structurer la couche `data/` pour accéder à Supabase de façon
testable et maintenable ?

## Options évaluées

### A — Repository directement dans data/ avec Supabase
```dart
class SupabaseHabitRepository implements HabitRepository {
  final SupabaseClient _client;
  // Requêtes Supabase directement ici
}
```
Simple mais mélange la logique de mapping et d'accès réseau.

### B — Datasource + Repository (retenu)
```
data/
├── datasources/
│   └── supabase_habit_datasource.dart   ← accès réseau pur (JSON → Map)
├── mappers/
│   └── habit_mapper.dart                 ← Map → Entity
└── repositories/
    └── supabase_habit_repository.dart    ← implémente l'interface domaine
```

Séparation claire : datasource gère le réseau, mapper convertit, repository orchestre.

## Décision

**Option B retenue** — Datasource pattern.

## Conséquences

- Les datasources reçoivent `SupabaseClient` par injection
- Les mappers sont des classes statiques pures (pas d'état, pas de dépendances)
- Les repository implémentent les interfaces `domain/repositories/`
- En test, on peut mocker uniquement le datasource et tester le mapper séparément
- La règle S-3 (service role key côté serveur uniquement) est respectée : le client
  mobile utilise uniquement `supabase.auth.session?.accessToken` (anon key + RLS)
