# Q-24 — Avatar photo : champ `avatarUrl` absent de l'entité `User`

**Statut** : 🟡 En attente de décision PO — UI-2 bloqué

## Contexte

Le sprint UX a identifié un item UI-2 : afficher la photo de profil de
l'utilisateur dans l'avatar circulaire du dashboard (HM-01) à la place de
l'initiale fallback.

Actuellement, `lib/domain/entities/user.dart` ne possède pas de champ
`avatarUrl`. L'avatar affiche uniquement l'initiale du displayName (ou `?`
si l'utilisateur est null).

## Question métier

Faut-il ajouter un champ `avatarUrl` (ou `photoUrl`) à l'entité `User` ?

## Options envisagées

- **Option A — Ajouter `avatarUrl` à `User`**
  - Ajouter `final String? avatarUrl;` à `lib/domain/entities/user.dart`
  - Alimenter depuis `users.avatar_url` en base (colonne à vérifier ou créer
    dans le schéma Supabase — `../docs/schema/database_schema.md`)
  - Mapper dans `UserModel` (data layer)
  - Afficher via `CachedNetworkImage` dans `_UserAvatar` (HM-01)
  - Conséquences : migration DB si la colonne n'existe pas, tests à mettre à jour

- **Option B — Reporter à la Phase 5 Polish**
  - Garder l'initiale fallback pour l'instant
  - L'avatar photo est un "nice to have" — pas bloquant pour la Phase 3
  - Conséquences : dette cosmétique connue, aucun risque

## Ma recommandation

Option B pour l'instant — la colonne `avatar_url` doit être confirmée dans le
schéma Supabase avant tout mapping Dart. Ce champ est probablement présent
(Google OAuth remonte une `photoUrl`) mais il faut vérifier la migration RLS
et la politique de stockage (Supabase Storage ou URL externe Google).

## Bloquant ?

Non — UI-2 est parké. L'initiale fallback reste en place.
Reprendre en Phase 5 (Polish) ou sur décision PO explicite.
