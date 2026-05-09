# Q-19 — Désalignement de l'enum `PrayerStatus` entre domain mobile et schéma Supabase

**Date ouverture** : 2026-05-09
**Statut** : **OUVERTE** (non bloquante pour la slice 3.B data layer — mapping défensif appliqué)
**Auteur** : Architecte mobile senior
**Slice** : 3.B Phase 3 — Salat data layer

## Contexte

Lors de l'implémentation de la couche data Salat (slice 3.B), j'ai détecté un
désalignement entre les valeurs supportées côté domain mobile et celles
définies dans le schéma Supabase.

**Domain mobile** (`lib/domain/entities/prayer_status.dart`) :
```dart
enum PrayerStatus { onTime, late, missed, pending, makeup }
```

**Schéma Supabase** (`murabbi-admin/supabase/migrations/20260426000000_initial_mobile_schema.sql`) :
```sql
fajr text check (fajr in ('ontime','late','missed','skipped') or fajr is null)
```

| Valeur SQL    | Valeur domain          | Mapping retenu (slice 3.B)              |
|---------------|------------------------|------------------------------------------|
| `null`        | `pending`              | OK — null = "non encore loggée"          |
| `'ontime'`    | `onTime`               | OK                                       |
| `'late'`      | `late`                 | OK                                       |
| `'missed'`    | `missed`               | OK                                       |
| `'skipped'`   | (aucune correspondance)| Lecture → throw `unknownStatus` (fail-fast) |
| (aucune)      | `makeup`               | Écriture → throw `unsupportedStatus`     |

## Question

1. Faut-il **étendre l'enum SQL** pour ajouter `'makeup'` (rattrapage post-coucher) ?
   La logique de scoring (`score_calculator_use_case.dart`) attribue 1 point à
   `makeup`, donc cette information doit être persistée pour reconstruire le
   score historiquement.

2. Faut-il **étendre l'enum domain** pour ajouter `skipped` ? À quoi correspondrait
   cette valeur côté UX mobile ? (Hypothèse : "passée volontairement, ne pas
   compter dans le calcul de complétion".)

3. Si on retire `makeup` du domain, comment représenter le rattrapage côté
   scoring ? Une seconde colonne SQL `makeup_count` par jour ?

## Impact si non résolue

**Court terme (slice 3.B)** : aucun. Le mapper applique un comportement défensif
documenté (fail-fast sur les valeurs inconnues, écriture refusée pour `makeup`).

**Moyen terme (slice 3.C UI prière)** : si l'utilisateur peut déclencher le
statut `makeup` depuis l'UI, l'écriture SQL échouera. Il faudra soit retirer
ce statut de l'UI, soit étendre le schéma. Décision attendue avant slice 3.C.

## Recommandation

Étendre le schéma Supabase pour aligner SQL et domain :
```sql
fajr text check (fajr in ('ontime','late','missed','skipped','makeup') or fajr is null)
```
et retirer `'skipped'` du SQL si la valeur n'a pas de sémantique côté mobile
(ou l'ajouter au domain si elle en a une).

À valider par le PO avant la slice 3.C.

## Décision PO

_(à compléter)_
