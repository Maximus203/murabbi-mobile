# ADR-011 — Soft-delete account avec cooling period 30 jours

**Statut** : Accepté
**Date** : 2026-05-06
**Décideur** : Cherif (PO) + agent senior
**Lié** : Q-18 (schema `users`), ADR-004 (Supabase data source)

## Contexte

Le SDK client Supabase ne fournit pas `auth.admin.deleteUser`. Une suppression
RGPD-compliante nécessite une cascade sur toutes les tables liées (habits,
habit_logs, scores, niyyahs, prayer_days, etc.) qui ne peut pas être
exécutée depuis le client (privilèges admin requis, intégrité référentielle).

Deux options :
- **A** — RPC SQL `delete_account(user_id uuid)` côté admin, exécutée par
  `SECURITY DEFINER` avec cascade explicite.
- **B** — Soft-delete via flag `deletion_requested_at` côté `users`, plus
  un job batch admin qui hard-delete passé un délai de cooling.

L'option A est plus immédiate mais oblige à tout définir avant V1. Le PO a
tranché : l'admin n'aura pas la RPC à temps pour Phase 2 mobile. On
adopte l'option B.

## Décision

**Soft-delete avec cooling period 30 jours.**

### Schéma `users` (verrouillé Q-18)

```sql
deletion_requested_at timestamptz  -- NULL = compte actif
```

### Comportement client (Phase 2 mobile)

1. **`DeleteAccountUseCase`** :
   ```sql
   UPDATE users
      SET deletion_requested_at = now()
    WHERE id = auth.uid()
      AND deletion_requested_at IS NULL;
   ```
   Puis `supabase.auth.signOut()`.

2. **Login bloqué** si `users.deletion_requested_at IS NOT NULL` :
   `signIn`, `signInWithGoogle`, `getCurrentUser` lèvent
   `AuthFailure.accountDeleted` au lieu de retourner un `User`.

3. **Pas de cancellation** côté Phase 2 — l'utilisateur ne peut pas
   annuler la suppression depuis le mobile (à reconsidérer en Phase 5+
   selon retours utilisateurs).

### Comportement admin (post-V1, hors scope mobile)

Job batch scheduled (issue admin #20) qui :
- Sélectionne `WHERE deletion_requested_at < now() - interval '30 days'`
- Exécute la cascade RGPD : suppression `auth.users` (= cascade FK sur
  toutes les tables liées) + audit log
- Cooling period = délai légal de rétractation + tampon contre les
  suppressions accidentelles

## Conséquences

### Positives
- Pas de dépendance bloquante côté admin pour livrer Phase 2 mobile.
- Conformité RGPD : la donnée est hard-deletée sous 30 jours (= droit à
  l'effacement, art. 17 RGPD, dans les délais raisonnables).
- Fenêtre de récupération en cas de suppression accidentelle (à exploiter
  Phase 5+ via support).

### Négatives / à surveiller
- L'utilisateur perd l'accès immédiat mais sa donnée existe physiquement
  encore 30 j → mention obligatoire dans la politique de confidentialité.
- Risque qu'un ré-signup avec le même email échoue durant la fenêtre de
  cooling (l'`auth.users` n'a pas encore été cascade-supprimé). À tester
  côté admin lors de la livraison du job batch.
- Le flag `deletion_requested_at` est lisible par le client — RLS
  `users_select_self` autorise le user à voir son propre statut. Pas de
  fuite d'information.

### Migration
Aucune migration mobile nécessaire — le schéma `users` arrive avec la
migration admin Q-18 (issue admin #20). Le mobile code contre la spec et
ses tests utilisent des mocks. Intégration prod = bootstrap admin ↔ mobile.

## Références
- Q-18 dans `murabbi-admin/docs/decisions/product_decisions_v1.md`
- Issue admin #20 — migration `users` + job batch hard-delete
- ADR-004 — Supabase data source pattern
- RGPD art. 17 — droit à l'effacement
