# Q-20 — Validation rétroactive "RememberedAccounts autofill" (AU-01)

**Statut** : `closed` — décision actée verbalement 2026-05-14, formalisation rétroactive.
**Slice associée** : PR #41 (`feat/remembered-accounts-autofill`).
**Référence** : ADR-015 `docs/adr/ADR-015-remembered-accounts.md`.

## Contexte

Pendant la phase de tests device de la slice 3.C.3 Salat, **le PO a demandé verbalement** un autofill local des emails sur AU-01 pour faciliter le switching rapide entre comptes de test. Feature non spécifiée dans les wireframes Hi-Fi (cf. `wireframes_audit.md §AU-01` avant cette mise à jour) → décision métier inventée par l'agent sans question PO formelle, en violation de la doctrine §1.3 / §9 du CLAUDE.md.

L'audit TL §B.2 (PR #41) a remonté ce gap → cette question PO ferme la dette rétroactivement.

## Décisions à formaliser

### Décision A — Persistance des emails dans `SharedPreferences`

**Acceptée.** Emails (non sensibles au sens RGPD) stockés en clair dans `SharedPreferences`, clé versionnée `remembered_emails_v1`. Pas de mot de passe, pas de token. Acceptable pour ce niveau de sensibilité (équivalent autofill navigateur). `flutter_secure_storage` (§11 CLAUDE.md) réservé aux tokens.

**Réserve mineure** : sur device rooté / jailbreaké, les emails sont lisibles en clair. Acceptable car non-sensible.

### Décision B — Affichage : email complet vs troncature local-part

**Initialement** : troncature `local-part` (chip affichait `"cherif"` pour `cherif@example.com`).
**Rejetée post-audit TL** : risque de collision visuelle si deux providers partagent le même local-part (`cherif@gmail.com` vs `cherif@outlook.com`).

**Acceptée (finale)** : email complet avec `TextOverflow.ellipsis` + `ConstrainedBox(maxWidth: 180)`. Préservation lisibilité + a11y (Semantics label déjà complet).

### Décision C — Affordance "oublier ce compte"

**Initialement** : long-press uniquement → bottom sheet de confirmation.
**Rejetée post-audit TL** : long-press non discoverable, pas d'indice visuel.

**Acceptée (finale)** : **bouton `x` explicite** à droite du chip (Semantics "Oublier $email"), avec long-press conservé comme raccourci alternatif. Affordance visible + a11y conforme.

### Décision D — Plafond LRU = 5 emails

**Acceptée.** Plafond fixé à 5 entrées max (`RememberedAccountsStorage.maxAccounts`) — garde l'UI compacte (5 chips dans un `Wrap`), suffisant pour le cas d'usage testing.

## Statut

✅ **Closed** — toutes les décisions intégrées dans la PR #41 et tracées dans ADR-015.

Cette question existe pour la traçabilité doctrinale (§9 CLAUDE.md "tu critiques les wireframes"). Aucune action runtime restante.
