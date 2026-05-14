# Q-21 — Stratégie de mapping `Category.id` au switch in-memory → Supabase

**Statut** : `open` — bloque le wiring `SupabaseCategoryRepository` (slice à venir).
**Slice associée** : PR #43 (`feat/phase-3-slice-d-habits`, dev scaffold in-memory).
**Référence** : audit TL §B.2 PR #43 §3.5.

## Contexte

Le scaffold in-memory de la PR #43 utilise des **IDs textuels** pour les 5 catégories système :

```dart
CategoryId('cat-religion'), CategoryId('cat-sport'),
CategoryId('cat-sante'), CategoryId('cat-mental'), CategoryId('cat-social'),
```

Le **futur seed Supabase admin** (Q-SEED-01.C / Q-SEED-02 actés 2026-05-14, côté `murabbi-admin`) utilisera des **UUIDs v4** + une colonne `slug` distincte pour identifier sémantiquement chaque catégorie.

→ **Drift garanti** au switch in-memory → Supabase : les `CategoryId` actuels ne correspondront à aucun UUID Supabase. Toute habitude créée en scaffold dev référence un `categoryId` inexistant en prod.

## Options

### Option A — UUIDs déterministes côté SQL

Le seed SQL admin utilise des **UUIDs déterministes** dérivés du slug (ex: namespace v5 + slug hash). Le scaffold mobile bascule sur les mêmes UUIDs (mais en perd la lisibilité — `f47ac10b-58cc-4372-a567-0e02b2c3d479` au lieu de `cat-religion`).

**Avantages** : pas de changement d'entité domain.
**Inconvénients** : IDs opaques côté code, lisibilité dev dégradée, source de vérité doublée (slug en SQL + UUID dérivé en code).

### Option B — Champ `slug` sur `Category` + mapping côté repo

Ajouter `slug: NonEmptyString` à l'entité `Category`. Le `SupabaseCategoryRepository` lit `id` (UUID) + `slug` séparément. Le code mobile qui référence une catégorie par sa sémantique ("religion") passe par le slug, pas par l'UUID.

**Avantages** :
- Lisibilité préservée (`category.slug == 'religion'` reste explicite).
- Source de vérité unique côté SQL (UUID = PK, slug = unique constraint).
- Switch scaffold → Supabase **sans casser le code** (le slug est stable).

**Inconvénients** : 1 champ supplémentaire sur l'entité + sa migration. Slice dédiée.

### Option C — Re-création complète au switch

Détruire les habitudes créées en scaffold dev au moment du switch Supabase (perte d'état dev acceptable car volatile par construction).

**Avantages** : zéro travail de migration.
**Inconvénients** : régression UX si un dev / tester perd ses habitudes de test au déploiement. Pas adapté si du beta-testing utilise le scaffold.

## Recommandation PO (audit TL)

**Option B** — ajouter `slug: NonEmptyString` à `Category` dans une slice dédiée **bloquant le wiring Supabase** (`feat/data-categories-supabase-datasource`). Plan :

1. **Slice migration entité** : ajouter `slug` à `Category` (freezed v15 + tests entité + mise à jour `InMemoryCategoryRepository` pour exposer le slug).
2. **Slice data layer** : `SupabaseCategoryRepository` lit/écrit slug, le scaffold in-memory devient un dev-toggle.
3. **Slice consommation** : le code mobile qui référence une catégorie système le fait via slug (`getCategoryBySlug('religion')`).

## Décision PO

**À prendre** — bloquante avant tout merge de `feat/data-categories-supabase-datasource`.

Cette question reste **`open`** jusqu'à la validation du PO sur l'option retenue.
