# Besoin admin — Q-21 : colonne `slug` sur la table `categories`

**Priorité** : Haute — bloque le wiring `SupabaseCategoryRepository` côté mobile
**Repo concerné** : `murabbi-admin/supabase/migrations/`
**Référence mobile** : commit `625b7c8`, Q-21, ADR-009

---

## Contexte

Le mobile a migré vers la **Q-21 Option B** : l'entité `Category` expose un champ
`slug: String?` (ex. `"religion"`, `"sport"`) qui sert d'identifiant sémantique
stable entre le scaffold in-memory et la prod Supabase.

Le `SupabaseCategoryRepository.getCategoryBySlug(userId, slug)` cherche une
catégorie via la colonne `slug` dans Supabase. **Cette colonne n'existe pas encore**
dans le schéma actuel de la table `categories`.

---

## Migration SQL à appliquer

```sql
-- murabbi-admin/supabase/migrations/YYYYMMDD_categories_add_slug.sql

ALTER TABLE categories
  ADD COLUMN IF NOT EXISTS slug text;

-- Contrainte UNIQUE pour garantir l'unicité sémantique des slugs
ALTER TABLE categories
  ADD CONSTRAINT categories_slug_unique UNIQUE (slug);

COMMENT ON COLUMN categories.slug IS
  'Identifiant sémantique stable de la catégorie (ex. "religion", "sport"). '
  'Non-null pour les catégories système, null pour les catégories admin/utilisateur. '
  'Utilisé par le mobile pour découpler le code des UUIDs Supabase (Q-21 Option B).';

-- Index pour la recherche par slug (getCategoryBySlug mobile)
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug)
  WHERE slug IS NOT NULL;
```

---

## Seed des 5 catégories système

Mettre à jour le seed admin pour peupler la colonne `slug` sur les 5 catégories
système existantes :

| name      | slug       |
|-----------|------------|
| Religion  | religion   |
| Sport     | sport      |
| Santé     | sante      |
| Mental    | mental     |
| Social    | social     |

```sql
UPDATE categories SET slug = 'religion' WHERE name = 'Religion' AND is_system = true;
UPDATE categories SET slug = 'sport'    WHERE name = 'Sport'    AND is_system = true;
UPDATE categories SET slug = 'sante'    WHERE name = 'Santé'    AND is_system = true;
UPDATE categories SET slug = 'mental'   WHERE name = 'Mental'   AND is_system = true;
UPDATE categories SET slug = 'social'   WHERE name = 'Social'   AND is_system = true;
```

---

## Ce que le mobile attend

Une fois la migration appliquée, la colonne `slug` sera lue par
`CategoryMapper.fromRow` (le champ est déjà mappé côté Dart, nullable, aucun
crash si absent).

**Notification requise** : signaler au mobile quand la migration est déployée
sur `staging` pour que la slice `feat/data-categories-supabase-datasource`
puisse être testée end-to-end.
