# AR-04 — Extension schéma `public.collections`

**Demandeur** : équipe mobile (Q-23)
**Urgence** : bloquant pour la validation manuelle de CO-02 sur Supabase

---

## Contexte

La Phase 5 / Q-23 ajoute deux champs optionnels à la collection :
- **Catégorie principale** — choisie dans CO-02, affichée dans CO-DETAIL
- **Icône** — nom kebab-case Lucide, résolu côté client à l'affichage

Ces champs sont déjà mappés côté mobile (`CollectionMapper`, `Collection` entity).
Tant que les colonnes n'existent pas en base, PostgREST retourne `42703`
(undefined column) et CO-01 bascule en error state.

---

## Migration SQL à appliquer

```sql
ALTER TABLE public.collections
  ADD COLUMN IF NOT EXISTS primary_category_id uuid
    REFERENCES public.categories(id)
    ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS icon text;
```

### Index recommandé

```sql
CREATE INDEX IF NOT EXISTS idx_collections_primary_category_id
  ON public.collections(primary_category_id)
  WHERE primary_category_id IS NOT NULL;
```

### RLS

Pas de nouvelle policy nécessaire : les deux colonnes héritent des policies
existantes sur `collections` (l'utilisateur lit/modifie ses propres collections).

---

## Validation

Après migration, tester dans le SQL Editor Supabase :

```sql
-- Vérifier que les colonnes existent
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'collections'
  AND column_name IN ('primary_category_id', 'icon');
-- Attendu : 2 lignes

-- Insérer une row de test
INSERT INTO public.collections (name, description, is_system, primary_category_id, icon)
VALUES ('Test AR-04', 'Validation migration', false, NULL, 'star')
RETURNING id, primary_category_id, icon;
-- Attendu : row avec icon='star'

-- Nettoyer
DELETE FROM public.collections WHERE name = 'Test AR-04';
```

---

## Impact mobile

Une fois la migration appliquée :
- CO-02 persiste `primary_category_id` et `icon` correctement
- CO-01 affiche les valeurs sans error state
- `CollectionMapper.fromRow` lit les deux colonnes (déjà implémenté)
