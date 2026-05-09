# Q-19 — Désalignement de l'enum `PrayerStatus` entre domain mobile et schéma Supabase

**Date ouverture** : 2026-05-09
**Date clôture** : 2026-05-09
**Statut** : **CLOS — 2026-05-09** (Option A retenue : SQL +makeup -skipped, mapping domain aligné)
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

## Décision PO finale — 2026-05-09 (Option A : aligner SQL sur le domain mobile)

**Option retenue** : étendre le check SQL pour autoriser `'makeup'` et retirer
`'skipped'` (sémantique mobile non utilisée). Le domain mobile reste
canonique : `{ onTime, late, missed, pending, makeup }` avec `pending`
représenté par `null` côté SQL.

**Mapping final verrouillé** :

| Valeur SQL  | Valeur domain | Sémantique |
|---|---|---|
| `null`      | `pending`     | non encore loggée                          |
| `'ontime'`  | `onTime`      | priée à l'heure (entre l'adhan et la suivante) |
| `'late'`    | `late`        | priée tardivement mais avant la suivante   |
| `'missed'`  | `missed`      | manquée (au-delà de la prière suivante)    |
| `'makeup'`  | `makeup`      | rattrapée post-coucher (qadâ', +1 point scoring) |

`'skipped'` est **retiré** du SQL (jamais émis par le client mobile, pas de
sémantique UX prévue).

**Implémentation appliquée** :

1. **Côté admin / SQL** — PR [murabbi-admin#46](https://github.com/Maximus203/murabbi-admin) (mergée 2026-05-09) :
   migration `20260509000000_align_mobile_domain.sql` qui remplace le
   check par `fajr in ('ontime','late','missed','makeup')` (et idem
   pour `dhuhr`, `asr`, `maghrib`, `isha`).

2. **Côté mobile / mapping** — PR [murabbi-mobile#24](https://github.com/Maximus203/murabbi-mobile/pull/24)
   (mergée 2026-05-09) : `prayer_day_mapper.dart` aligné sur la table
   ci-dessus. `'skipped'` reste géré en lecture comme valeur legacy → throw
   `PrayerFailure.unknownStatus` (jamais écrit par le client). Tests
   `prayer_day_mapper_test.dart` couvrent le round-trip pour les 5
   valeurs canoniques + le cas legacy.

**Conséquences validées** :

- Le scoring `+1` pour `makeup` est désormais persisté SQL → reconstructible
  historiquement (cf. `score_calculator_use_case.dart`).
- L'UI Salat (slice 3.C) peut exposer le statut `makeup` sans risque
  d'écriture SQL refusée.
- `'skipped'` legacy : si une ligne pré-migration existait avec cette
  valeur, le mapper lève fail-fast et l'app remonte une erreur explicite
  plutôt que de fabriquer un statut silencieux (cf. règle racine S-10
  fail-fast > silently-correct).

**Pas de régression** : aucune ligne `'skipped'` en base au moment de la
migration (vérifié via `select count(*) from prayer_days where 'skipped'
in (fajr, dhuhr, asr, maghrib, isha)` = 0 sur l'env staging).
