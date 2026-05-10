<!--
Template PR Murabbi Mobile.
Garde-fou cross-repo anti-drift mobile↔SQL.
Référence : murabbi-admin/docs/runbooks/cross-repo-coordination.md · CLAUDE.md §A.5 · §16 leçons V1.
-->

## Contexte

<!-- Pourquoi cette PR ? Quel besoin produit / bug / dette technique ? -->

## Changements

<!-- Liste précise des fichiers/modules modifiés. -->

## Tests

<!-- Tests ajoutés (unit / widget / integration), coverage avant/après. TDD respecté ? -->

## Comment tester

<!-- Étapes manuelles pour reproduire / valider sur l'app. -->

---

## Coordination cross-repo (obligatoire si applicable)

> Référence : `murabbi-admin/docs/runbooks/cross-repo-coordination.md` · CLAUDE.md §A.5

- [ ] Cette PR modifie `lib/domain/**`, `lib/data/datasources/supabase/**` ou `lib/data/mappers/**`
  - [ ] Migration SQL admin compagnon existe : `Migration-Ref: <admin-PR-url>` ci-dessous
  - [ ] Migration appliquée en prod (workflow `Supabase Deploy`, dispatch manuel après merge admin)
  - [ ] OU justification ci-dessous : `no SQL impact — <courte justification>`

### Header de coordination

<!--
Si la PR touche les chemins listés ci-dessus, le workflow CI `domain-migration-guard`
exige l'une des deux mentions ci-dessous dans la description PR. Utiliser EXACTEMENT
ces formats (le matcher tolère la casse mais pas les fautes de frappe).

Format compagnon (cas standard) :
    Migration-Ref: https://github.com/Maximus203/murabbi-admin/pull/<numero>

Format dérogatoire (changement domain purement Dart, ex : value object dérivé,
refactor mapper sans nouveau champ persisté, calcul local) :
    no SQL impact — <courte justification>
-->

Migration-Ref:

<!-- ou bien :
no SQL impact — <courte justification>
-->
