# ADR-001 — Clean Architecture vs Feature-first

**Date** : 2026-04-27
**Auteur** : Agent mobile (Phase 0)
**Statut** : Accepté

## Contexte

L'application Murabbi Mobile doit être maintenable sur une horizon de 10 ans, testable
à 100% sur la logique métier, et indépendante du framework Flutter et de Supabase dans
sa couche domaine.

Deux approches structurelles ont été évaluées.

## Options

### A — Feature-first (par domaine fonctionnel)
```
lib/
├── features/
│   ├── prayer/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── habits/
│       ├── data/
│       ├── domain/
│       └── presentation/
```

**Avantages** : cohésion par feature, facile de naviguer si on travaille sur un seul domaine.

**Inconvénients** : duplication potentielle des patterns de data/domain, couplage accidentel
entre features via les couches data.

### B — Clean Architecture par couche (retenu)
```
lib/
├── domain/
│   ├── entities/
│   ├── use_cases/
│   ├── repositories/
│   └── value_objects/
├── data/       (Phase 1+)
└── presentation/   (Phase 1+)
```

**Avantages** : isolation totale de la logique métier (zéro dépendance Flutter/Supabase),
testabilité 100% du domaine avec des mocks purs, contrat clair via les interfaces de
repository.

**Inconvénients** : navigation moins intuitive quand on travaille sur une seule feature end-to-end.

## Décision

**Option B retenue** — Clean Architecture par couche.

La règle non négociable est : zéro import `flutter/` ou `supabase_flutter` dans `lib/domain/`.
La couche `domain/` doit être compilable en Dart pur sans le SDK Flutter.

## Conséquences

- Tous les use cases reçoivent les interfaces de repository par injection de dépendance
- Riverpod gère l'injection en `presentation/` et `data/`
- Les tests de `domain/` n'ont pas besoin de `flutter_test` (utilisation possible de `test` seul)
- Les entités `Equatable` ne dépendent pas de Flutter (package pur Dart)
