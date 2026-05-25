# ADR-015 — Remembered accounts (autofill emails sur AU-01)

**Statut** : Accepté · slice debug PR #41 · révisé post-audit TL B.2
**Date** : 2026-05-14

## Contexte

Demande PO pendant la phase de tests device (slice 3.C.3 Salat) : faciliter le **switching rapide entre comptes de test** sur le téléphone. L'utilisateur jongle entre plusieurs emails de test sur le même device — retaper l'email à chaque tentative ralentit la boucle de validation.

Côté audit TL §B.2 (PR #41) : feature **non spécifiée dans les wireframes Hi-Fi** (cf. `docs/audit/wireframes_audit.md §AU-01`). Décision à tracer pour ne pas s'autoriser le pattern "PR sans spec" comme précédent.

## Décision

Implémenter un **autofill local des emails** sur l'écran de connexion AU-01 :

- Chips visibles sous l'en-tête "COMPTES RÉCENTS", au-dessus du champ Email.
- Tap → pré-remplit le champ Email (le mot de passe reste à saisir).
- Bouton **`x` explicite** sur chaque chip → bottom sheet "Oublier ce compte" (long-press = raccourci alternatif).
- Stockage local **SharedPreferences** (clé `remembered_emails_v1`).
- LRU plafonné à **5 entrées** max, normalisation `lowercase + trim`.
- Pas de pseudo, pas de mot de passe, pas de session restaurée — **rien que des emails**.

## Sécurité

- ✅ **Aucun secret persisté** : emails uniquement (non-PII sensible au sens RGPD).
- ✅ **Pas de bypass auth** : l'utilisateur retape toujours son mot de passe → préservation MFA, pas de session token caché.
- ✅ **Pas de fuite logger** : aucun `print`/`debugPrint` n'écrit l'email.
- ⚠ **Limitation acceptée** : sur appareil rooté/jailbreaké, les emails sont lisibles en clair (acceptable pour ce niveau de sensibilité, équivalent autofill navigateur).
- Le claim "remembered" est honnête — `flutter_secure_storage` réservé aux tokens (§11 CLAUDE.md), pas applicable ici.

## Options rejetées

- **`flutter_secure_storage`** : surcoût natif iOS/Android pour un usage non-sensible. Réservé aux tokens.
- **Pseudo + email** : superflu pour le cas d'usage testing, augmente la surface stockée sans gain UX.
- **Sync Supabase cross-device** : hors scope, breaks le principe "local-only" et nécessite une table dédiée.
- **Troncature `local-part`** : initialement implémentée, **rejetée post-audit TL** — risque de collision visuelle entre deux providers partageant le même local-part (`cherif@gmail.com` vs `cherif@outlook.com`). Affichage **email complet** avec ellipsis dans le chip.
- **Long-press uniquement** pour oublier : **rejeté post-audit TL** — affordance non discoverable. Bouton `x` visible ajouté à droite du chip (Semantics label "Oublier $email"), long-press conservé comme raccourci alternatif.

## Conséquences

- Surface code : ~250 lignes (service + provider + widget + integration AU-01).
- Tests : 9 unit storage + 5 notifier + 4 widget + 3 régression auth_notifier = **21 tests**.
- Dette tracée :
  - Convergence `@riverpod` codegen (§5 CLAUDE.md vs réalité du repo en `AsyncNotifier`/`NotifierProvider` manuel) — à arbitrer en ADR transversal séparé.
  - Pas de bouton "Effacer toutes les suggestions" en UI (`storage.clear()` existe) — à brancher quand l'écran Settings arrivera.
- Pas d'impact sur la couche auth domain (`AuthRepository`/`AuthNotifier` inchangés, seule la couche presentation est hookée fire-and-forget après succès).

## Évolutions probables

- Migration vers une AccountPicker complète (avatar Gravatar + last login date) si le PO valide la promotion de la feature.
- Possible export vers une primitive partagée `AppAccountChips` si Habitudes / Catégories réutilisent le pattern.
