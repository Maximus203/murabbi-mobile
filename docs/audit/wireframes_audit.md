# Audit Wireframes Murabbi — Phase 0

> Corpus analysé : `Murabbi Wireframes.html` (v3 base), `Murabbi v1.5.html` (addendum), `Murabbi Extras Mobile.html` (extras iOS/Android), et leurs 13 fichiers JSX (primitives, screens-core, screens-detail, screens-onboarding, v15-screens, v15-execute, design-system-sheet, extras-tokens, extras-frames, extras-widgets, extras-lockscreen-live, extras-notifications, extras-inapp-icons). Bundle daté avril 2026, dossier source : `wireframes/bundle/Murabbi Mobile v1.5/`.

---

## 1. Inventaire des écrans

### 1.1 Écrans mobile applicatifs (corpus v3 + v1.5)

| ID | Titre | Source | Statut | Fonction |
|---|---|---|---|---|
| **OB-01** | Splash logo | `screens-onboarding.jsx:ScreenOB01` | v3-base | Écran d'amorce (vidéo + logo + tagline) au lancement |
| **OB-02** | Onboarding · Cinq prières | `screens-onboarding.jsx:ScreenOB02` | v3-base | Slide 1/3 — pédagogie Salat |
| **OB-03** | Onboarding · Habitudes | `screens-onboarding.jsx:ScreenOB03` | v3-base | Slide 2/3 — pédagogie habitudes & collections |
| **OB-04** | Onboarding · Horizon 10 ans | `screens-onboarding.jsx:ScreenOB04` | v3-base | Slide 3/3 — vision long terme · CTA "Commencer" |
| **AU-01** | Connexion | `screens-onboarding.jsx:ScreenAU01` | v3-base | Login email + Google OAuth + lien mot de passe oublié |
| **AU-02** | Inscription | `screens-onboarding.jsx:ScreenAU02` | v3-base | Signup email + Google OAuth + CGU |
| **AU-03** | Mot de passe oublié | `screens-onboarding.jsx:ScreenAU03` | v3-base | Saisie email + écran succès "lien envoyé" (15 min) |
| **SETUP-01** | Configuration prière | `screens-onboarding.jsx:ScreenSETUP01` | v3-base | Localisation + méthode de calcul + DST automatique |
| **SETUP-02** | Permission notifications | `screens-onboarding.jsx:ScreenSETUP02` | v3-base | Demande système iOS/Android |
| **HM-01** | Dashboard / Accueil | `screens-core.jsx:ScreenHM01` | v3-base | Score du jour, Niyyah, stats 2x2, prochain rappel |
| **HM-01 v1.5** | Dashboard enrichi | `v15-screens.jsx:ScreenHM01v15` | v1.5-override | Idem + section habitudes 6/9 enrichie (objectif/timer/sous-tâches) |
| **SL-01** | Salat · liste 5 prières | `screens-core.jsx:ScreenSL01` | v3-base | Liste Fajr/Dhuhr/Asr/Maghrib/Isha + cycle statut + résumé |
| **SL-DETAIL** | Détail prière | `screens-detail.jsx:ScreenSLDetail` | v3-base | Marquage statut (à l'heure/retard/manquée/reset) + rattrapage + heatmap semaine |
| **NIYYAH-EDIT** | Édition intention du jour | `screens-detail.jsx:ScreenNiyyahEdit` | v3-base | Textarea 200 char + compteur |
| **HB-01** | Liste habitudes | `screens-core.jsx:ScreenHB01` | v3-base | Filtres + sections par catégorie + check inline |
| **HB-01 v1.5** | Liste habitudes enrichie | `v15-screens.jsx:ScreenHB01v15` | v1.5-override | Idem + mini-barre objectif + badge timer actif |
| **HB-02** | Créer/Modifier habitude | `screens-core.jsx:ScreenHB02` | v3-base | Nom, catégorie, fréquence, plage, jours actifs, aperçu notif |
| **HB-02 v1.5** | Édition habitude étendue | `v15-screens.jsx:ScreenHB02v15` | v1.5-override | Idem + 3 sections pliables : objectif chiffré, sous-tâches, timer in-app |
| **HB-03** | Catégories | `screens-core.jsx:ScreenHB03` | v3-base | Liste catégories système + perso · accès création |
| **HB-04** | Créer catégorie | `screens-core.jsx:ScreenHB04` | v3-base | Nom + 9 couleurs + 10 icônes + slider points (1-10) + aperçu |
| **HB-DETAIL** | Détail habitude (v3) | `screens-detail.jsx:ScreenHBDetail` | v3-base | Streak/Record/Taux 30j + heatmap 30j + historique 7j + edit/suppr |
| **HB-DETAIL · objectif** | Détail habitude · objectif chiffré | `v15-screens.jsx:ScreenHBDetailV15` | v1.5-new | Carte "Aujourd'hui" 3/5 + CTA reprendre + stats 2x2 + graph 30j barres |
| **HB-DETAIL · sous-tâches** | Détail habitude · sous-tâches | `v15-screens.jsx:ScreenHBDetailV15Subtasks` | v1.5-new | Carte "Aujourd'hui" liste cochable + CTA disabled jusqu'à completion |
| **HB-DETAIL · timer** | Détail habitude · timer | `v15-screens.jsx:ScreenHBDetailV15Timer` | v1.5-new | Display 20:00 + CTA "Démarrer" + graph 30j |
| **HB-EXECUTE A.1** | Exec · Timer initial | `v15-execute.jsx:HBExecuteTimerInitial` | v1.5-new | Bottom sheet · anneau 240 · CTA "Démarrer" |
| **HB-EXECUTE A.2** | Exec · Timer en cours | `v15-execute.jsx:HBExecuteTimerRunning` | v1.5-new | Anneau animé 12:34 · pause/arrêter · validation disabled |
| **HB-EXECUTE A.3** | Exec · Timer en pause | `v15-execute.jsx:HBExecuteTimerPaused` | v1.5-new | Anneau figé · reprendre/arrêter |
| **HB-EXECUTE B.1** | Exec · Compteur 0/5 | `v15-execute.jsx:HBExecuteCounter_Empty` | v1.5-new | Display 0/5 · -/+  · saisir total · disabled |
| **HB-EXECUTE B.2** | Exec · Compteur 3/5 | `v15-execute.jsx:HBExecuteCounter_Partial` | v1.5-new | État partiel · disabled |
| **HB-EXECUTE B.3** | Exec · Compteur 5/5 atteint | `v15-execute.jsx:HBExecuteCounter_Reached` | v1.5-new | État succès vert · enabled |
| **HB-EXECUTE B.4** | Exec · Compteur 7/5 dépassé | `v15-execute.jsx:HBExecuteCounter_Exceeded` | v1.5-new | Au-dessus du target |
| **HB-EXECUTE C.1** | Exec · Sous-tâches partiel | `v15-execute.jsx:HBExecuteSubtasks_Partial` | v1.5-new | 3/5 cochées · disabled |
| **HB-EXECUTE C.2** | Exec · Sous-tâches complet | `v15-execute.jsx:HBExecuteSubtasks_All` | v1.5-new | 5/5 cochées · enabled |
| **HB-EXECUTE D** | Exec · Combiné | `v15-execute.jsx:HBExecuteCombined` | v1.5-new | Timer 160 + objectif + sous-tâches empilés |
| **CO-01** | Collections | `screens-core.jsx:ScreenCO01` | v3-base | Sections Système + Mes collections · cards activables |
| **CO-02** | Créer collection | `screens-core.jsx:ScreenCO02` | v3-base | Titre + description + catégorie + icône + sélection habitudes (multi) + résumé pts/jour |
| **CO-DETAIL** | Détail collection | `screens-detail.jsx:ScreenCODetail` | v3-base | Description + liste habitudes incluses + pts potentiel + CTA activer |
| **LB-01** | Classement | `screens-core.jsx:ScreenLB01` | v3-base | Podium 1-2-3 + table rang 4-9, ligne "vous" surlignée |
| **CAL-01** | Calendrier / Historique | `screens-detail.jsx:ScreenCAL01` | v3-base | Sélecteur mois + filtres Tout/Salat/Habitudes + grille 30 jours + récap jour |
| **ST-01** | Paramètres | `screens-detail.jsx:ScreenST01` | v3-base | Profil + Compte + Pratique + Confidentialité + À propos + Logout + Zone sensible |
| **ST-02** | Modifier profil | `screens-detail.jsx:ScreenST02` | v3-base | Avatar + nom + email (lock) + pseudonyme classement |
| **ST-03** | Supprimer compte | `screens-detail.jsx:ScreenST03` | v3-base | Confirmation typage "DELETE" + liste données supprimées |
| **LEVEL-UP** | Modale niveau franchi | `screens-detail.jsx:ScreenLevelUp` | v3-base | Plein écran sombre · "Aspirant · Niveau 2" · bouton continuer |
| **EMPTY-HABITS** | Habitudes vide | `screens-detail.jsx:EmptyHabits` | v3-base | Empty state + CTA créer / voir collections |
| **EMPTY-COLLECTIONS** | Collections vide | `screens-detail.jsx:EmptyCollections` | v3-base | Empty state + suggestions système |
| **EMPTY-LEADERBOARD** | Classement vide | `screens-detail.jsx:EmptyLeaderboard` | v3-base | Empty state · "disponible dimanche soir" |
| **EMPTY-CALENDAR** | Calendrier vide | `screens-detail.jsx:EmptyCalendar` | v3-base | Empty state · "valider première prière" |

**Total écrans applicatifs : 47** (28 écrans uniques v3 + 7 nouveaux v1.5 + 12 variantes/états/empty). Le CDC mentionnait 28 — l'extension v1.5 (HB-DETAIL × 3 + HB-EXECUTE × 8) a porté le total au-delà.

### 1.2 Écrans extras (mockups iOS/Android)

| Code | Catégorie | Source | Fonction |
|---|---|---|---|
| **A1–A4** | App icons | `extras-inapp-icons.jsx:AppIconShowcase` | Light/Dark/Tinted/Sage |
| **B1–B9** | Widgets iOS | `extras-widgets.jsx:WidgetB1..B9` | Score, Prochaine prière, Streak, Vue d'ensemble, À venir, Salat 5, Tableau, Calendrier mois, Add Widget sheet |
| **C1–C4** | Widgets Android (Pixel) | `extras-widgets.jsx:WidgetC1..C4` | Équivalents B1/B4/B7 + picker |
| **D1–D3** | Lock screen widgets iOS | `extras-lockscreen-live.jsx:LSRect/LSCirc/LSInline` | Inline / circulaire / rectangulaire |
| **E1–E4** | Live Activities | `extras-lockscreen-live.jsx:LADynamicIsland*` | Dynamic Island compact / pair / expanded / lock card |
| **F1–F15** | Notifications | `extras-notifications.jsx:NotifA1..A15` | Rappels habitudes, Salat, streaks, niveau, contenu, récap, in-app, group, permission |
| **G1–G4** | Moments in-app | `extras-inapp-icons.jsx:InApp*` | Streak 7j, Level-up, Empty, Day done |

---

## 2. Inventaire des composants UI distincts

### 2.1 Primitives (`primitives.jsx`)
- **Phone shell** : container 390×844 + StatusBar (heure + signal/wifi/battery)
- **HeaderBack** : back chevron + titre central + action droite
- **HeaderTitle** : titre H1 + action droite (pas de back)
- **BottomNav** : 5 tabs (Accueil / Salat / Habitudes / Collections / Classement)
- **Logo** : cercle + 6 points + centre (mark abstrait)
- **Wordmark** : "Murabbi" Geist 500
- **ProgressRing** : cercle SVG % avec texte central
- **Icon** : 40+ icônes Lucide-style (1.5px stroke)
- **Ar** : composant inline pour texte arabe (Noto Sans Arabic)

### 2.2 Composants core v3 (`screens-core.jsx`, `screens-detail.jsx`)
- **StatCard** (label + value + trend up/down/flat + caption)
- **SalatRow** (icône moment du jour + nom AR/FR + heure mono + statut bouton)
- **salat-btn** : bouton rond statut (pending/ontime/late/missed avec icônes)
- **HabitRow v3** (dot catégorie + nom + fréquence + check)
- **SectionHeader** (dot + label uppercase + count droite)
- **CategoryRow** (dot + nom + badge "Système" + count + chevron)
- **CollectionCard** (vidéo poster 60x60 + titre + tags + CTA Activer/Activée)
- **CheckboxRow** (checkbox 22 + label + sub)
- **PodiumCol** (avatar carré + nom + score + barre verticale 1/2/3)
- **LeaderRow** (rank mono + avatar + nom + score, variante "you")
- **HabitItemSimple** (dot + nom + freq + +pts)
- **StatusBtn** (icône statut + label, état actif)
- **Toggle** (interrupteur 44x26 ocre/fond)
- **SettingRow** (icône + label + valeur + chevron/external + variante danger)
- **SectionLabel** (titre uppercase pour groupes settings)
- **Stat** (mini : label + value)
- **dot-status** : pastille couleur (s-ontime/s-late/s-missed/s-pending)
- **chip / chip active** : pastilles filtres horizontaux
- **badge-system** : pastille "Système"
- **badge-level** : badge "Niveau X · Aspirant"
- **card / card-video** : cards génériques avec ou sans vidéo en background
- **input / input-wrap / with-icon-left / with-icon-right** : composition champ
- **field-label / label / caption / display / h1 / h2 / h3 / body** : typo
- **btn-primary / btn-secondary / btn-ghost / btn-destructive / btn-icon** : boutons
- **link-tertiary** : lien texte tertiaire
- **divider-text** : séparateur "OU"
- **video-overlay-light/dark** : overlays sur vidéos (multiples opacités)
- **sticky-bottom** : zone fixe footer (avec/sans nav)
- **cal-grid / cal-cell / cal-num / cal-mark** : grille calendrier
- **Dots** : indicateur de progression carrousel onboarding (active 18×6, inactive 6×6)
- **PentagonIllo / StackIllo / HorizonIllo** : illustrations SVG des slides onboarding

### 2.3 Composants v1.5 (`v15-screens.jsx`, `v15-execute.jsx`)
- **MiniProgressBar** (4-6px, gradient ocre clair → ocre → sauge selon ratio)
- **TimerBadge** (pill ocre · icône timer · mono temps · "restant")
- **PulseDot** (point animé 1.4s pulse)
- **V15Toggle** (toggle 38×22 plus compact)
- **CollapsibleSection** (chevron + label uppercase + count optionnel + toggle optionnel)
- **MiniCheckbox** (24×24 carrée arrondie)
- **HM01HabitMicroRow** (row dense pour dashboard avec priorité timer > objectif > sous-tâches)
- **HabitRowV15** (row liste avec mini-barre / badge timer empilés sous le titre)
- **SubtaskItem** (drag-handle + input + delete)
- **Github30dGraph** (30 barres verticales 8×40, 4 niveaux : 0/25/75/100% en sauge)
- **BottomSheet** (modal 92% hauteur, drag handle, fond blur)
- **SheetHeader** (titre H1 + ligne meta + close X)
- **StickyValidate** (footer CTA + caption + état disabled)
- **TimerRing** (anneau circulaire 240×240, stroke 4, mono 56pt centré)
- **RoundBtn** (bouton rond 64×64, variants primary/secondary/ghost)

### 2.4 Composants extras
- **WidgetShell / WidgetHeader / Ring / DotRow / Legend** : shell widgets iOS
- **AndroidWidgetShell** : variante coins 28px
- **IPhoneFrame / DynamicIsland / PixelFrame** : frames device pour mises en situation
- **LSRect / LSCirc / LSInline** : geometries lock screen iOS
- **LADynamicIslandCompact / Expanded / Pair / LockCard** : Live Activity
- **IOSNotif / AndroidNotif** : shells notifications avec icône, titre, body, actions
- **LockContextIOS / BannerContextIOS / StackContextIOS / PixelLockContext** : mises en situation
- **FauxAppIcon** : aperçu icône app (continuous corner)

---

## 3. Inventaire des actions utilisateur (par écran)

| Écran | Action | Type | Cible / effet |
|---|---|---|---|
| OB-01 | Auto-progress | timer | OB-02 après lecture vidéo (implicite) |
| OB-02/03/04 | Tap "Passer" | nav | Saut vers AU-01 |
| OB-02/03 | Tap "Continuer" | nav | Slide suivante |
| OB-04 | Tap "Commencer" | nav | AU-01 ou AU-02 |
| AU-01 | Saisie email/password | form | — |
| AU-01 | Tap "Se connecter" | form | Validation + nav HM-01 |
| AU-01 | Tap "Continuer avec Google" | nav | OAuth flow |
| AU-01 | Tap "Mot de passe oublié ?" | nav | AU-03 |
| AU-01 | Tap "Créer" | nav | AU-02 |
| AU-01 | Tap eye icon | ui | Toggle password visibility |
| AU-01 | Tap chip "Comptes récents" | ui | Autofill du champ email (cf. ADR-015 — feature ajoutée post-wireframes, PR #41) |
| AU-01 | Long-press chip OU tap icône `x` | ui | Bottom-sheet "Oublier ce compte" → retire de la liste LRU (cf. ADR-015) |
| AU-02 | Tap "Créer mon compte" | form | Signup + nav SETUP-01 (supposé) |
| AU-02 | Tap CGU/Privacy | nav-ext | Lien externe |
| AU-03 | Tap "Envoyer le lien" | form | Email reset envoyé (15 min) |
| SETUP-01 | Saisie ville | form | Recherche localisation |
| SETUP-01 | Tap méthode calcul | form | Sélecteur (MWL, ISNA, Egyptian, Karachi, Umm al-Qura, Tehran, Jafari) |
| SETUP-01 | Toggle DST | toggle | — |
| SETUP-01 | "Configurer plus tard" | nav | Skip vers SETUP-02 |
| SETUP-02 | "Activer notifications" | nav | Demande système puis HM-01 |
| HM-01 | Tap cloche header | nav | Notifications ? (non documenté) |
| HM-01 | Tap edit niyyah | nav | NIYYAH-EDIT |
| HM-01 | Tap stat card | nav | Drill-down vers détail (?) |
| HM-01 | Tap "Prochain rappel" | nav | SL-DETAIL |
| HM-01 v1.5 | Tap habit row check | action | Validation simple (sans modal) |
| HM-01 v1.5 | Tap timer pill | nav | HB-EXECUTE A.2 (timer en cours) |
| HM-01 v1.5 | Tap habit avec objectif | nav | HB-EXECUTE B.x |
| HM-01 v1.5 | Tap habit avec sous-tâches | nav | HB-EXECUTE C.x |
| SL-01 | Tap salat-btn | action | Cycle de statut (pending → ontime → late → missed → pending) — supposé |
| SL-01 | Tap row | nav | SL-DETAIL |
| SL-DETAIL | Tap statut | action | Marque la prière dans le statut choisi |
| SL-DETAIL | Toggle "Marquer rattrapée" | toggle | Différé |
| SL-DETAIL | Tap X | nav | Retour SL-01 |
| NIYYAH-EDIT | Saisie textarea (max 200) | form | — |
| NIYYAH-EDIT | Tap "Confirmer" | form | Sauvegarde + retour HM-01 |
| HB-01 | Tap chip filtre (Toutes/Aujourd'hui/À faire) | filter | Filtrage liste |
| HB-01 | Tap + header | nav | HB-02 |
| HB-01 | Tap row | nav | HB-DETAIL |
| HB-01 | Tap check rond | action | Validation simple |
| HB-01 v1.5 | Tap row avec objectif/timer/sous-tâches | nav | HB-EXECUTE |
| HB-02 | Saisie nom | form | — |
| HB-02 | Tap chip catégorie | select | Sélection unique |
| HB-02 | Tap "Gérer mes catégories" | nav | HB-03 |
| HB-02 | Tap chip fréquence | select | Quotidien/3×/5×/Hebdo/Mensuel/Custom |
| HB-02 | Tap heures plage | form | Picker time (start/end) |
| HB-02 | Tap jour L-D | toggle | Activer/désactiver chaque jour |
| HB-02 | Tap "Créer l'habitude" | form | Save + retour |
| HB-02 v1.5 | Toggle section "Objectif chiffré" | toggle | Active/désactive section |
| HB-02 v1.5 | Saisie valeur + select unité | form | 10 unités prédéfinies + "Personnalisé…" |
| HB-02 v1.5 | Toggle section "Sous-tâches" | toggle | — |
| HB-02 v1.5 | Add/edit/delete sous-tâche | form | Max 15 |
| HB-02 v1.5 | Drag sous-tâche (grip) | drag | Réordonnancement |
| HB-02 v1.5 | Toggle "Toutes obligatoires" | toggle | Mode validation |
| HB-02 v1.5 | Toggle "Timer in-app" | toggle | Disabled si unité non temporelle |
| HB-03 | Tap row catégorie | nav | Détail (non livré) ou édition |
| HB-03 | Tap "+ Nouvelle catégorie" | nav | HB-04 |
| HB-03 | Tap + header | nav | HB-04 |
| HB-04 | Saisie nom | form | — |
| HB-04 | Tap couleur (9 options) | select | — |
| HB-04 | Tap icône (10 options) | select | — |
| HB-04 | Drag slider points (1-10) | drag | — |
| HB-04 | Tap "Créer la catégorie" | form | Save |
| HB-DETAIL v3 | Tap "Modifier" | nav | HB-02 (mode édition) |
| HB-DETAIL v3 | Tap "Supprimer" | action | Confirmation puis suppression |
| HB-DETAIL v1.5 | Tap CTA "Reprendre"/"Démarrer"/"Cocher" | nav | HB-EXECUTE A/B/C |
| HB-EXECUTE | Drag handle / X | nav | Fermer modal |
| HB-EXECUTE A | Tap Démarrer/Pause/Reprendre/Arrêter | action | Contrôle timer |
| HB-EXECUTE B | Tap +/- | action | Incrément/décrément |
| HB-EXECUTE B | Saisir total + "Mettre à jour" | form | Override valeur |
| HB-EXECUTE C | Tap row sous-tâche | toggle | Cocher/décocher |
| HB-EXECUTE all | Tap "Valider l'habitude" | form | Validation finale + +pts + close |
| CO-01 | Tap "Activer" | action | Active collection (instancie habitudes) |
| CO-01 | Tap row | nav | CO-DETAIL |
| CO-01 | Tap + header | nav | CO-02 |
| CO-02 | Saisie titre/description | form | — |
| CO-02 | Tap chip catégorie | select | — |
| CO-02 | Tap icône | select | — |
| CO-02 | Tap CheckboxRow | toggle | Sélection habitude |
| CO-02 | Tap "Créer la collection" | form | Save |
| CO-DETAIL | Tap "Activer cette collection" | action | Active + retour |
| LB-01 | Tap row participant | nav (?) | Profil public ? Non documenté |
| CAL-01 | Tap chevrons mois | nav | Mois précédent/suivant |
| CAL-01 | Tap chip filtre (Tout/Salat/Habitudes) | filter | — |
| CAL-01 | Tap cellule jour | select | Affiche récap du jour |
| ST-01 | Tap profil | nav | ST-02 |
| ST-01 | Tap Notifications/Apparence/etc. | nav | Sous-écrans non livrés |
| ST-01 | Tap "Politique" / "Conditions" | nav-ext | Liens externes |
| ST-01 | Tap "Se déconnecter" | action | Logout + AU-01 |
| ST-01 | Tap "Supprimer mon compte" | nav | ST-03 |
| ST-02 | Saisie nom/pseudo | form | — |
| ST-02 | Tap "Modifier la photo" | nav | Picker système |
| ST-02 | Tap "Enregistrer" | form | Save |
| ST-03 | Saisie "DELETE" | form | Active CTA |
| ST-03 | Tap "Supprimer définitivement" | action | Trigger 30j cooldown puis suppression |
| LEVEL-UP | Tap "Continuer" | nav | Retour HM-01 |

---

## 4. Inventaire des états par écran

| Écran | États documentés |
|---|---|
| OB-01 | Auto-loop video |
| OB-02/03/04 | Slide active (dot indicator), Skip |
| AU-01 | Form vide, en cours, success → HM-01 ; password masqué/visible. États error et loading **non documentés** |
| AU-02 | Form, validation client, success. Error **non documenté** |
| AU-03 | Form initial, success (carte verte "Lien envoyé"). Error/email-not-found **non documenté** |
| SETUP-01 | Initial, recherche ville, sélection méthode |
| SETUP-02 | Pre-prompt (visuel cloche), permission acceptée/refusée non documenté |
| HM-01 | Default (3/5 prières, 8/12 habitudes). Empty state global **non documenté** (premier login) |
| HM-01 v1.5 | Habit avec objectif partiel/atteint, timer running, sous-tâches partielles, simple done |
| SL-01 | 3 statuts simultanés visibles (ontime/late/pending). Loading initial **non documenté** |
| SL-DETAIL | Statut courant : ontime/late/missed/pending ; rattrapage off |
| HB-01 | 8/12 complétées (state mixte) |
| HB-01 v1.5 | Habit standard, avec objectif (mini-bar), avec timer actif, dépassée (6500/5000) |
| HB-02 v1.5 | Section objectif on/off, timer compatible/incompatible (disabled), sous-tâches on/off, allRequired on/off |
| HB-DETAIL v3 | Mix de statuts dans heatmap, historique 7 jours |
| HB-DETAIL v1.5 objectif | 3/5 partiel · CTA "Reprendre" actif |
| HB-DETAIL v1.5 sous-tâches | 3/5 cochées · CTA disabled "Cochez toutes les sous-tâches obligatoires" |
| HB-DETAIL v1.5 timer | Timer non démarré, CTA "Démarrer" |
| HB-EXECUTE A | Initial / Running / Pause |
| HB-EXECUTE B | 0/5 (vide disabled), 3/5 (partiel disabled), 5/5 (atteint enabled, vert), 7/5 (dépassé) |
| HB-EXECUTE C | 3/5 (disabled), 5/5 (enabled). Variante allRequired=false **mentionnée mais non illustrée seule** |
| HB-EXECUTE D | Combiné partiel disabled |
| CO-01 | Au moins une collection activée (state nominal) ; section Système + Mes collections |
| CO-02 | 3 sélectionnées (compteur live + total pts/jour) |
| LB-01 | Default (47 participants, vous #7) |
| CAL-01 | Mois courant, jour 26 sélectionné, mix de couleurs |
| ST-01 | Profil rempli |
| ST-03 | Champ vide (CTA disabled) / "DELETE" saisi (CTA enabled) |
| LEVEL-UP | Niveau franchi (Aspirant N2). Pas de variante par niveau |
| Empty States | EmptyHabits, EmptyCollections, EmptyLeaderboard, EmptyCalendar livrés |
| **Manquants transverses** | Loading skeleton, Error retry, Offline banner, No-network mode, Permission refusée |

---

## 5. Inventaire des données par écran

| Écran | Données affichées | Données saisies |
|---|---|---|
| OB-01 | logo, tagline | — |
| OB-02/03/04 | titre, body, illustration | — |
| AU-01 | logo, wordmark, **chips "Comptes récents"** (liste plafonnée à 5 emails normalisés LRU, `SharedPreferences` clé `remembered_emails_v1` — ADR-015) | email, password |
| AU-02 | — | nom complet, email, password, password confirm |
| AU-03 | — | email |
| SETUP-01 | — | ville, méthode calcul, DST |
| SETUP-02 | — | permission system |
| HM-01 | greeting (prénom), date FR + Hijri, score 42/60, niveau (Aspirant N2), niyyah text, streak (14j +2), salat 3/5, habitudes 68% (+4%), classement #7, prochain rappel (Asr 15h42, dans 1h18) | — |
| HM-01 v1.5 | + Liste 6 habitudes du jour (nom, dot catégorie, état done/objectif/timer/subtasks) | — |
| SL-01 | Date, ratio prières, 5 prières (icône période, nom AR, nom FR, heure, statut), résumé pts | — |
| SL-DETAIL | Nom AR, nom FR, heure, countdown ("dans 1h 18min"), statut courant, semaine 7j heatmap | toggle rattrapée, statut |
| NIYYAH-EDIT | longueur courante / max | texte intention |
| HB-01 | Compteur global (8/12), 4 sections catégories avec ratios (3/4, 2/3, etc.), liste habitudes (nom, freq, dot, done) | — |
| HB-01 v1.5 | + actual/target/unit, timer remaining | — |
| HB-02 | Tous champs habitude + aperçu notif (logo, "Murabbi", "maintenant", titre, body) | nom, catégorie, fréquence, plage start/end, jours actifs[7] |
| HB-02 v1.5 | + sections collapsibles | objectif {value, unit, customLabel?}, subtasks[{title, order}], allRequired bool, timerEnabled bool |
| HB-03 | Compteur (5 catégories · 12 habitudes), liste catégories (couleur, nom, badge système, count) | — |
| HB-04 | Aperçu live (icône, nom, "X pts par habitude") | nom, couleur (1/9), icône (1/10), points (1-10) |
| HB-DETAIL v3 | streak/record/taux 30j, heatmap 30j, historique 7j (date relative, statut) | — |
| HB-DETAIL v1.5 | + Aujourd'hui (actual/target ou liste subtasks ou MM:SS), stats 4 (streak/record/taux/total), graph 30j data[], moyenne 30j | — |
| HB-EXECUTE | nom habitude, catégorie + couleur, plage, ligne mono summary | timer running/elapsed, actual count, subtask checks |
| CO-01 | Vidéo poster, titre, tags (catégorie + N habitudes + N pts/jour), état activé | — |
| CO-02 | total sélectionnés, total pts/jour computed | titre, description, catégorie, icône, sélection habitudes |
| CO-DETAIL | description, liste habitudes, total pts potentiel | — |
| LB-01 | Période ("Semaine du 21 au 27 avril"), N participants, podium 1-2-3 (avatar/nom/score), table rang 4-9 (rank, nom, score, "you" flag) | — |
| CAL-01 | Mois (label), grille 30 jours (statut couleur), filtre, jour sélectionné (label, salat ratio, habitudes ratio, score, commentaire textuel) | filtre |
| ST-01 | nom, email, niveau, version app, settings (notifs, apparence, méthode prière, objectif quotidien, démarrage semaine, langue) | — |
| ST-02 | avatar (initiale), email (lock), nom, pseudo | nom, pseudo, photo |
| ST-03 | liste données supprimées | confirmation "DELETE" |
| LEVEL-UP | nouveau niveau (rang + numéro), citation | — |

**Note** : la ligne mono dans HB-EXECUTE SheetHeader contient `"20 min · timer · sauge"` — la mention "sauge" est inexpliquée (tag interne ? thème ?) → **question Q-04**.

---

## 6. Extras iOS / Android (widgets, lock, live, notifications, in-app)

### `extras-tokens.jsx`
Tokens visuels partagés (palette, polices, statuts 4 états : ontime/late/missed/pending — équivalents `Validé/En retard/Manquée/En attente`).

### `extras-frames.jsx`
- `IPhoneFrame` (cadre device iPhone 14 Pro), `DynamicIsland`, `PixelFrame` (Android).

### `extras-widgets.jsx` — 9 widgets iOS + 4 widgets Android
| Code | Taille | Données | Note |
|---|---|---|---|
| B1 | small 2x2 | Score % + pts + libellé | Anneau accent |
| B2 | small 2x2 | Prochaine prière (AR + FR) + heure + countdown | — |
| B3 | small 2x2 | Streak n jours + 7 derniers points (DotRow) | — |
| B4 | medium 4x2 | Anneau + ratios prières/habitudes | — |
| B5 | medium 4x2 | 3 prochaines actions horodatées | Liste prochaine action |
| B6 | medium 4x2 | 5 prières du jour (statut chacune) | Bordure accent sur prière courante |
| B7 | large 4x4 | Score + Salat 5×1 + 4 habitudes + streak | "Tableau de bord" |
| B8 | large 4x4 | Heatmap 30 jours + légende statut | Calendrier mois |
| B9 | sheet | Carrousel "Add Widget" | Picker iOS |
| C1–C4 | Android | Équivalents B1/B4/B7 + picker Pixel | Coins 28px |

**Mises en situation** : `IOSHomeContext`, `PixelHomeContext` (combos sur écran d'accueil simulé).

### `extras-lockscreen-live.jsx` — Lock screen iOS + Live Activities
- **Lock widgets** :
  - `LSInline` : pill "Asr · 16:32" / "14 jours · 42 pts"
  - `LSCirc` × 3 : ring score, prochaine prière, streak
  - `LSRect` × 2 : score+ratio prières, Asr countdown
- **Live Activities** :
  - `LADynamicIslandCompact` (E1) : icône soleil + countdown
  - `LADynamicIslandPair` (E2) : split glyphe + soleil
  - `LADynamicIslandExpanded` (E3) : carte 78%, AR/FR, countdown, barre plage
  - `LALockCard` (E4) : carte plein cadre + 2 actions (Validé/Plus tard)

### `extras-notifications.jsx` — 15 notifications mockées
| Code | Type | Plateforme | Contenu |
|---|---|---|---|
| F1 | Rappel habitude | iOS lock | "Lecture du Coran" + actions Validé/Plus tard |
| F2 | Rappel habitude | Android lock | "30 squats" |
| F3 | Salat | iOS in-app banner | Asr foreground |
| F4 | Salat | Pixel lock | 3 actions À l'heure/Manquée/Plus tard |
| F5 | Salat | iOS expanded | Header dégradé + progression jour + 3 actions |
| F6 | Streak 7j | — | Minimal |
| F7 | Streak 30j | — | Minimal |
| F8 | Streak 1 an | — | Riche image header |
| F9 | Niveau | — | "Murid · niveau 1/5" |
| F10 | Contenu nouvelle collection | iOS | "Routine Ramadan" |
| F11 | Contenu | Android | Equivalent F10 |
| F12 | Récap hebdo | — | Dimanche 20h, dégradé sombre |
| F13 | In-app toast | — | "Habitude validée · +3 pts" pill |
| F14 | Group | iOS | 3 rappels stackés |
| F15 | Permission | iOS system | Prompt "Murabbi souhaite vous envoyer..." |

### `extras-inapp-icons.jsx` — Moments in-app + App icons
- **G1** : Streak 7 jours (matin du 8e jour)
- **G2** : Niveau 1 — Murid (au franchissement 120 pts) — **note** : LEVEL-UP est aussi dans `screens-detail.jsx`, doublon design ?
- **G3** : Empty state habitudes (premier accès vide)
- **G4** : Journée complète (après dernier item validé)
- **A1–A4** : 4 variantes app icon (Light, Dark, Tinted, Sage)

### `design-system-sheet.jsx`
Planche tokens (couleurs, typo, statuts) — composant de doc, pas un écran applicatif.

---

## 7. Incohérences et oublis détectés

### 7.1 Données / modèle
1. **Niveaux** : seuls "Aspirant N2" (HM-01) et "Murid N1" (G2 et F9) sont nommés. Le CDC évoque un système 5 niveaux, **les 5 noms et seuils points ne sont pas listés** → Q-01.
2. **Score & points** : objectif 60 pts/jour visible, mais pas de règle d'attribution claire. SL-01 dit "+12 pts ce matin" pour 2 ontime + 1 late : la grille points n'est pas exposée → Q-02.
3. **Catégories système (5)** : Religion, Sport, Santé, Mental, Social. Mais HB-04 propose 9 couleurs / 10 icônes pour catégories perso → contraintes d'unicité (couleur déjà utilisée ?) non documentées → Q-03.
4. **HB-EXECUTE SheetHeader** mentionne `"sauge"` dans la ligne mono — **terme orphelin** sans correspondance dans le CDC → Q-04.
5. **HabitTarget · "Personnalisé…"** : 11ᵉ option dans le select unité, mais aucun écran ne montre le picker custom (label libre ?) → Q-05.
6. **Sous-tâches max 15** annoncé dans la spec, mais HB-02 v1.5 ne montre pas l'état "limite atteinte" (CTA add disabled ?) → Q-06.
7. **Rattrapage Salat** : toggle "Marquer comme rattrapée" présent mais aucun écran ne montre l'effet sur le scoring (perte points ? même points si rattrapée ?) → Q-07.
8. **Calendrier** : un seul "mark" couleur par jour (un statut agrégé) — mais une journée mixe Salat ontime/late + habitudes done/missed. Quelle agrégation ? → Q-08.
9. **Leaderboard** : "47 participants" sur quelle base ? Global ? Amis ? Région ? La spec ne précise pas la portée du classement → Q-09.
10. **Pseudonyme** : ST-02 dit "apparaîtra publiquement sur le classement". Si non rempli ? Conflit ? Modération ? → Q-10.
11. **Collection · activation** : tap "Activer" instancie les habitudes — mais que se passe-t-il si l'utilisateur a déjà certaines de ces habitudes ? Doublons ? Skip ? → Q-11.
12. **CO-DETAIL · "Potentiel journalier 14 points"** : 2+3+4+5 = 14 sur la liste affichée. La somme des `category_points × N habitudes catégorie` est cohérente, mais HB-04 fixe les points à la **catégorie**, pas à l'habitude. **Incohérence** : peut-on avoir des points par habitude ? → Q-12.
13. **Heatmap HB-DETAIL v3** : 4 couleurs (success/warning/danger/empty) mais l'unité est binaire (fait/non fait). Pour habitudes avec objectif chiffré, la sémantique de "warning" est ambiguë (partiel ?). → Q-13.
14. **Onboarding** : le flow OB-01 (splash) compte ou pas dans les "4 slides" ? L'index HTML montre OB-01 + OB-02..04 → 4 écrans mais 3 dots. Splash exclu de la pagination → confirmer → Q-14.
15. **Calcul horaires prière** : 7 méthodes citées ; aucune indication du fournisseur (Aladhan API ? local lib ?). Stockage offline des horaires ? → Q-15 (technique mais impacte UX).
16. **NIYYAH-EDIT** : limite 200 caractères. Persistence : par jour ? Reset à minuit ? Historique des intentions ? → Q-16.
17. **Streak** : règles de réinitialisation non documentées. Une habitude ratée casse le streak global ? Ou un seuil minimum (ex. 80% des habitudes) ? → Q-17.
18. **Suppression compte** : 30 jours cooldown annoncé. Pendant cette période, l'utilisateur peut-il se reconnecter pour annuler ? Aucun écran "annulation" → Q-18.
19. **Email lock** dans ST-02 : si l'utilisateur s'est inscrit en Google, comment changer email ? Pas de flow → Q-19.

### 7.2 États non documentés
- **Loading** : aucun skeleton sur les écrans de listes (HB-01, CO-01, LB-01).
- **Error** : aucun écran d'erreur réseau (échec login, sync échoue, fetch leaderboard timeout).
- **Offline** : pas de banner / pas de vue dégradée.
- **Permission refusée** (notif, location SETUP-01) : flow de récupération non livré.
- **HM-01 utilisateur 0 jour** : premier login après onboarding — quoi afficher ? Pas de niyyah, 0 stats, 0 habitudes.
- **HB-EXECUTE C avec allRequired=false** : illustré uniquement via captions, pas d'artboard dédié.
- **Leaderboard "vous hors top 10"** : quel display ? Pagination ? Section "Vous : #47" séparée ?
- **Catégorie système modifiée** : badge "Système" suggère lecture seule, pas d'écran de l'interdiction.
- **Habitude désactivée** (toggle off ? archive ?) : pas d'écran. Soft-delete vs vraie suppression.

### 7.3 Interactions ambiguës
- **SL-01 tap salat-btn** : cycle implicite ou ouvre SL-DETAIL ? Les wireframes montrent les deux (rond cliquable + row cliquable).
- **HM-01 stat cards** : cliquables ? Vers où (CAL-01 ? SL-01 ? LB-01) ?
- **HB-01 v1.5 row avec timer running** : tap sur le pill rouvre HB-EXECUTE A.2 ou tap autre part ouvre HB-DETAIL ?
- **HB-DETAIL · suppression** : aucune confirmation modal documentée (juste un bouton btn-destructive).
- **CO-01 toggle Activée→Désactiver** : peut-on désactiver une collection ? L'écran ne montre que "Activer" ou "Activée" en lecture.
- **Onboarding "Passer"** : skip vers où ? AU-01 ? AU-02 ? Ou directement HM-01 (mode invité non défini) ?

### 7.4 Cas limites non traités
- 0 habitude / 100 habitudes / 1000 habitudes (perf liste).
- 0 prière du jour réalisée vs 5/5.
- Streak > 999 jours (display overflow).
- Leaderboard avec 1 seul participant.
- Niyyah avec emoji / RTL / saisie multi-langues.
- Pseudonyme dupliqué.
- Habitude créée hors plage horaire actuelle (validation possible "anytime" ?).
- Suppression d'une catégorie contenant des habitudes (cascade ? interdit ?).

### 7.5 Accessibilité / qualité
- Tap targets : MiniCheckbox (24×24), salat-btn (taille non explicite mais visible ~28px) — **proche des 44pt min Apple HIG**, à valider.
- Contraste : `text-tertiary` `#A89880` sur `bg-primary` `#F5F2ED` → ratio à mesurer (probablement < 4.5:1).
- Screen reader : labels AR (الفجر) sans `lang="ar"` ni alt texte FR.
- Mode sombre : non livré (DS limité au mode clair). Le CDC évoque mode "Apparence" dans ST-01 → Q-20.
- Vidéos en arrière-plan (Niyyah, OB) : impact batterie + données mobiles + reduced-motion non géré.
- Polices : Geist Mono pour chiffres → chargement web font, fallback ?

### 7.6 Performance
- HB-01 : liste plate sans pagination ni virtualisation.
- LB-01 : table linéaire, pas de scroll infini.
- CAL-01 : un seul mois chargé, mais navigation chevrons → fetch par mois ?
- Vidéos : 11 fichiers MP4 dans `media/` (poids ?) — fallback statique mentionné mais lossy non précisé.

---

## 8. Questions métier ouvertes pour le PO (Cherif)

### Q-01 · Système de niveaux (5 paliers)
**Contexte** : HM-01 affiche "Aspirant · Niveau 2", G2/F9 mentionnent "Murid · Niveau 1/5". Le CDC parle de 5 niveaux mais les 5 noms et seuils ne sont nulle part dans les wireframes.
**Question** : Quels sont les 5 noms (Murid, Aspirant, ?, ?, ?) et les seuils en points cumulés pour chaque palier ?
**Options** : A) Échelle progressive 0/120/500/1500/5000 pts ; B) Échelle temporelle (1 mois / 3 mois / 1 an / 3 ans / 10 ans cumulés actifs) ; C) Hybride.
**Recommandation** : Définir une suite Fibonacci-like (120/300/750/1800/4500) avec des noms évoquant le tasawwuf : Murid → Aspirant → Talib → Salik → Murabbi.
**Bloquant** : Oui — impacte `users.level` et le service de scoring.

### Q-02 · Grille de scoring détaillée
**Contexte** : SL-01 : "+12 pts" pour 2 ontime + 1 late. HB-04 : slider 1-10 pts par habitude. Mais aucune table.
**Question** : Quels points sont attribués pour : Salat ontime / late / missed / rattrapée ? Habitude validée ? Bonus streak ? Pénalités ?
**Recommandation** : Salat 5/3/0/2 ; habitude = points catégorie ; bonus +5% par tranche de 7 jours streak. À valider.
**Bloquant** : Oui.

### Q-03 · Catégories perso · contraintes
**Contexte** : HB-04 expose 9 couleurs et 10 icônes.
**Question** : (a) Couleur unique par utilisateur ou réutilisable ? (b) Limite de catégories perso ? (c) L'utilisateur peut-il modifier/supprimer une catégorie système ?
**Recommandation** : (a) Couleur libre, (b) max 10 perso, (c) système en lecture seule.
**Bloquant** : Non (recommandation par défaut).

### Q-04 · Terme "sauge" dans HB-EXECUTE
**Contexte** : SheetHeader affiche `"20 min · timer · sauge"`.
**Question** : Que signifie "sauge" ? Tag de couleur de validation (#6B8C6B) ? Type de session ? Erreur de copywriter ?
**Recommandation** : Retirer du SheetHeader (parasite UX) — c'est sans doute un résidu interne de la nomenclature couleur.
**Bloquant** : Non.

### Q-05 · Unité personnalisée
**Contexte** : HB-02 v1.5 expose 10 unités + "Personnalisé…".
**Question** : Le mode personnalisé permet quoi exactement ? Label libre + arithmétique d'incrément (ex. "raka'at" pas à pas de 1) ?
**Recommandation** : Label libre (max 20 char) + step défini par l'utilisateur, valeur par défaut 1.
**Bloquant** : Non.

### Q-06 · Limite sous-tâches
**Contexte** : Spec annonce max 15.
**Question** : Comportement à la 15ᵉ : CTA "Ajouter" disabled ou caché ? Message ?
**Recommandation** : CTA disabled + caption "Limite de 15 sous-tâches atteinte".
**Bloquant** : Non.

### Q-07 · Rattrapage Salat · scoring
**Contexte** : Toggle SL-DETAIL.
**Question** : Une prière "rattrapée" rapporte-t-elle moins de points qu'à l'heure ? Idem qu'une "en retard" ?
**Recommandation** : Rattrapée = 2 pts (entre late=3 et missed=0).
**Bloquant** : Oui — impacte service scoring.

### Q-08 · Couleur agrégée du jour (CAL-01)
**Contexte** : 1 couleur par cellule jour.
**Question** : Quelle règle d'agrégation ? (a) majoritaire, (b) pire statut, (c) pondéré par points ?
**Recommandation** : (b) pire statut visible par défaut (encourage perfection), avec opacity proportionnelle au % réalisé.
**Bloquant** : Oui (modèle de vue calendrier).

### Q-09 · Portée du classement
**Contexte** : LB-01 montre 47 participants.
**Question** : Classement global (tous users), amis (graph social non documenté), ou ville/pays ?
**Recommandation** : V1 : classement par cohorte d'inscription ou par tranches d'âge anonymes (max 100 par cohorte). Pas de social V1.
**Bloquant** : Oui — impacte modèle `users` (cohort_id) et requêtes leaderboard.

### Q-10 · Pseudonyme
**Contexte** : ST-02 "apparaîtra publiquement sur le classement".
**Question** : Unicité requise ? Modération a priori (banlist) ? Comportement si vide ?
**Recommandation** : Unicité oui, banlist basique, fallback "Anonyme #<id>".
**Bloquant** : Oui (contrainte DB).

### Q-11 · Activation collection · doublons habitudes
**Contexte** : CO-01 "Activer" instancie les habitudes.
**Question** : Si l'utilisateur a déjà "Lecture du Coran" personnelle et active "Matin du musulman" qui contient cette habitude, on duplique, on skip ou on fusionne ?
**Recommandation** : Skip silencieux + toast "1 habitude déjà active a été ignorée".
**Bloquant** : Non.

### Q-12 · Points par habitude vs par catégorie
**Contexte** : HB-04 = points par catégorie. CO-DETAIL liste pts par habitude (5/3/4/2). HabitItemSimple expose `pts` per-habit.
**Question** : Source de vérité ? Catégorie OU habitude ?
**Recommandation** : Hybride — points par défaut hérités de la catégorie, override par habitude possible (champ `points_override` nullable).
**Bloquant** : Oui — impacte schéma `habits.points` et service scoring.

### Q-13 · Heatmap habitudes avec objectif chiffré
**Contexte** : Heatmap HB-DETAIL v3 binaire ; HB-DETAIL v1.5 graph 30j à 4 niveaux.
**Question** : Pour la heatmap mensuelle (CAL-01) avec habitudes objectif chiffré, "warning" = partiel ?
**Recommandation** : success = 100%, warning = 50-99%, danger = 1-49%, empty = 0%. Aligner sur le graph 30j.
**Bloquant** : Non.

### Q-14 · Onboarding · 3 ou 4 écrans
**Contexte** : OB-01 splash + OB-02/03/04 slides ; dots = 3.
**Question** : Splash compte-t-il dans le flow utilisateur (skippable ?) ou est-ce uniquement un loading screen ?
**Recommandation** : OB-01 = splash (1.5s auto-progress, non skippable, non compté dans dots). 3 slides effectifs.
**Bloquant** : Non.

### Q-15 · Source horaires de prière
**Contexte** : 7 méthodes de calcul listées.
**Question** : Calcul local (lib `adhan-dart`) ou API distante (Aladhan) ? Granularité (1 jour, 1 semaine, 1 an) ? Cache offline ?
**Recommandation** : `adhan-dart` local + cache 30 jours par batch. Pas de dépendance réseau pour les horaires.
**Bloquant** : Non (technique).

### Q-16 · Persistence Niyyah
**Contexte** : NIYYAH-EDIT 200 char.
**Question** : Une intention par jour (reset 00:00 local) ? Historique consultable ?
**Recommandation** : Une `daily_niyyah` par user/jour, historique préservé (lecture seule), affichée dans CAL-01 récap jour.
**Bloquant** : Oui (table `daily_niyyahs`).

### Q-17 · Règle de streak
**Contexte** : "Streak 14j" sur HM-01 et par habitude.
**Question** : Un streak global existe-t-il (en plus du per-habit) ? Quelle règle de cassure ? (a) 1 prière manquée casse, (b) <80% du jour, (c) jour off (jours actifs) sans pénalité.
**Recommandation** : Per-habit-streak (par habitude, jours actifs uniquement). Streak global = jours consécutifs avec ≥1 habitude validée et ≥3 prières.
**Bloquant** : Oui.

### Q-18 · Cooldown 30j suppression
**Contexte** : ST-03 dit "supprimées sous 30 jours".
**Question** : L'utilisateur peut-il se reconnecter pour annuler dans la fenêtre ? Si oui, par quel flow ?
**Recommandation** : Reconnexion email/Google = écran "Restaurer mon compte ?" avant HM-01.
**Bloquant** : Non (ajustable post-V1).

### Q-19 · Email Google · changement
**Contexte** : ST-02 email locked.
**Question** : Comment l'utilisateur Google peut-il changer son email ? Migration vers email/password ?
**Recommandation** : V1 : pas de changement d'email pour Google users (changer le compte Google côté Google). Caption explicite.
**Bloquant** : Non.

### Q-20 · Mode sombre
**Contexte** : DS livré en clair uniquement. ST-01 expose "Apparence : Clair".
**Question** : Mode sombre prévu V1 ?
**Recommandation** : V1 = clair uniquement, ST-01 affiche "Apparence : Clair (système)" en lecture seule, mode sombre planifié V2.
**Bloquant** : Non.

---

*Fin du rapport — Audit Phase 0, Murabbi Mobile, mai 2026.*
