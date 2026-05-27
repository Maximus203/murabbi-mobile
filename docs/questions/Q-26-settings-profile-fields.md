# Q-26 — ST-02 : champs éditables vs issue #168

**Date** : 2026-05-26
**Statut** : ⏳ En attente décision PO
**Priorité** : Bloquant pour activer "Enregistrer" dans ST-02

## Contexte

Le wireframe ST-02 montre deux champs éditables :
1. **Nom complet** (ex. "Cherif Benkacem")
2. **Pseudonyme (classement)** (ex. "Cherif")

### Problèmes identifiés

| Champ | Mapping schema | Blocage |
|---|---|---|
| Nom complet | Aucune colonne `display_name` / `full_name` dans `users` v1.3.0 | Migration SQL requise |
| Pseudonyme | `users.pseudo` — rendu immuable par `pseudo_immutable_trigger` (issue #168 / admin#125) | Décision produit à confirmer |

## Options

**Option A** — Ajouter `display_name text NULL` dans `users` :
- "Nom complet" = `display_name` (éditable)
- "Pseudonyme (classement)" = `pseudo` (read-only per #168)
- Nécessite : migration SQL + mapper Dart + UpdateProfileUseCase v2
- Recommandée par l'agent (bonne sémantique)

**Option B** — Traiter "Nom complet" comme alias de `pseudo` :
- "Nom complet" = `pseudo` (éditable, revient sur #168)
- "Pseudonyme (classement)" = supprimé ou affiché en read-only
- Nécessite : révision de la décision #168

**Option C** — Garder tout en lecture seule (statu quo) :
- ST-02 = écran de consultation uniquement
- Bouton "Enregistrer" supprimé ou gardé désactivé
- Aucune migration requise

## État actuel (implémenté)

ST-02 affiche les trois champs en lecture seule.
Le bouton "Enregistrer" est présent (wireframe) mais désactivé (`onPressed: null`).
Le code est structuré pour activer chaque champ par tranche une fois la décision prise.

## Action requise

Cherif : choisis une option ci-dessus.
Je n'active aucun champ en écriture avant ta validation.
