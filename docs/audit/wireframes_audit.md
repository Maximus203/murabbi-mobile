# Audit wireframes — Murabbi Mobile
> Phase 0 · Lecture complète des wireframes Hi-Fi  
> Sources : `docs/wireframes/bundle/` (JSX + CSS) · `docs/wireframes/mobile/` (HTML standalone)  
> Statut : **COMPLET** — Q-01 fermée (2026-04-28)

---

## 1. Inventaire des 32 écrans

| ID | Titre | Section | Fonction |
|----|-------|---------|----------|
| OB-01 | Splash | Onboarding | Logo Murabbi + tagline sur fond vidéo — premier affichage |
| OB-02 | Onboarding 1 — Salat | Onboarding | Slide "Cinq prières · un rythme" (PentagonIllo) |
| OB-03 | Onboarding 2 — Habitudes | Onboarding | Slide "Des habitudes qui s'empilent" (StackIllo) |
| OB-04 | Onboarding 3 — Horizon | Onboarding | Slide "Un horizon de dix ans" (HorizonIllo) + CTA "Commencer" |
| AU-01 | Connexion | Auth | Email + mdp + Google OAuth |
| AU-02 | Inscription | Auth | Nom + email + mdp + confirmer + Google OAuth |
| AU-03 | Mot de passe oublié | Auth | Formulaire email (2 états : saisie / lien envoyé) |
| SETUP-01 | Config prière | Setup | Localisation + méthode de calcul + DST |
| SETUP-02 | Permission notifications | Setup | Prompt native iOS/Android pour les notifs |
| HM-01 | Accueil (Dashboard) | Core | Score ring, niyyah du jour, stats 2×2, prochain rappel |
| SL-01 | Salat | Core | 5 prières du jour avec statuts + bandeau vidéo + récap points |
| HB-01 | Mes Habitudes | Core | Liste par catégories + filtres + toggle complétion |
| HB-02 | Créer habitude | Core | Form nom + catégorie + fréquence + plage horaire + jours + aperçu notif |
| HB-03 | Catégories | Core | Liste des catégories avec compteur d'habitudes |
| HB-04 | Créer catégorie | Core | Form nom + couleur (9) + icône (10) + points (slider 1–10) + aperçu |
| CO-01 | Collections | Core | Collections système + mes collections + statut activée |
| CO-02 | Créer collection | Core | Form titre + description + catégorie + icône + sélection habitudes |
| LB-01 | Classement | Core | Podium top 3 + liste rang 4–N + ligne "Vous" mise en valeur |
| HB-DETAIL | Détail habitude | Détail | Streak / Record / Taux 30j + heatmap 30j + historique + actions |
| CO-DETAIL | Détail collection | Détail | Description + liste habitudes avec pts + potentiel journalier |
| SL-DETAIL | Détail prière | Détail | Modal vidéo fullscreen + mark status (4 boutons) + toggle rattrapée + semaine |
| NIYYAH-EDIT | Éditer niyyah | Détail | Textarea 200c + fond vidéo + CTA "Confirmer" |
| ST-01 | Paramètres | Settings | Profil + Compte + Pratique + Confidentialité + Déconnexion + Suppression |
| ST-02 | Modifier profil | Settings | Nom + email (verrouillé) + pseudonyme classement |
| ST-03 | Supprimer compte | Settings | Confirmation "DELETE" + liste données supprimées (30 jours) |
| LEVEL-UP | Level-up | Overlay | Fond vidéo dark + nouveau niveau + citation |
| CAL-01 | Calendrier / Historique | Historique | Vue mois avec heatmap + filtres Tout/Salat/Habitudes + détail du jour |
| EMPTY-HB | Habitudes — vide | Empty | SVG target + 2 CTA (créer / collections) |
| EMPTY-CO | Collections — vide | Empty | Card texte + suggestions système |
| EMPTY-LB | Classement — vide | Empty | SVG podium + message "fin de semaine" |
| EMPTY-CAL | Calendrier — vide | Empty | SVG calendrier + message "validez votre première prière" |
| AU-03-OK | Lien envoyé (état succès) | Auth | Variante succès de AU-03 (card verte inline) |

---

## 2. Inventaire des composants UI distincts

| Composant | Écrans |
|-----------|--------|
| `BottomNav` (5 tabs: Home/Salat/Habitudes/Collections/Classement) | HM-01, SL-01, HB-01, CO-01, LB-01, CAL-01, EMPTY-* |
| `HeaderTitle` (titre + action optionnelle) | HB-01, CO-01, LB-01, ST-01 |
| `HeaderBack` (chevron + titre + action optionnelle) | HB-02..04, HB-DETAIL, CO-02, CO-DETAIL, SL-DETAIL, NIYYAH-EDIT, ST-02..03, CAL-01 |
| `ProgressRing` (svg ring, value 0–100) | HM-01 |
| `StatCard` (label + value + trend) | HM-01 × 4 |
| `SalatRow` (icône + nom AR + nom FR + heure + bouton statut) | SL-01 × 5 |
| `HabitRow` (dot couleur + nom + freq + toggle done) | HB-01 |
| `SectionHeader` (dot + label catégorie + compteur) | HB-01 × 4 |
| `CategoryRow` (dot + nom + badge système + compteur + chevron) | HB-03 |
| `CollectionCard` (vidéo + titre + tags + bouton activer/activée) | CO-01, EMPTY-CO |
| `CheckboxRow` (checkbox + label + sous-label) | CO-02 |
| `PodiumCol` (avatar + nom + score + barre podium) | LB-01 × 3 |
| `LeaderRow` (rang + avatar + nom + score + surlignage "you") | LB-01 × N |
| `HabitItemSimple` (dot + nom + freq + pts) | CO-DETAIL |
| `StatusBtn` (icône statut + label + état actif) | SL-DETAIL × 4 |
| `Toggle` (iOS-style switch) | SL-DETAIL, SETUP-01 |
| `SettingRow` (icône + label + valeur + chevron/external) | ST-01 |
| `OnboardSlide` (vidéo + overlay + illustration + titre + body + dots + CTA) | OB-02, OB-03 |
| `card-video` (vidéo + overlay + contenu) | HM-01, SL-01, SL-DETAIL, LEVEL-UP, NIYYAH-EDIT |
| `Logo`, `Wordmark` | AU-01, OB-01 |
| `Dots` (pagination dots) | OB-02..04 |
| `Chip` (filter/select) | HB-01, CO-02, HB-02, CAL-01 |
| `badge-level`, `badge-system` | HM-01, ST-01, HB-02, HB-03 |
| `StickyBottom` (barre d'action fixe sans nav) | HB-02, HB-04, CO-02, CO-DETAIL, NIYYAH-EDIT |

---

## 3. Inventaire des actions utilisateur

| Écran | Actions |
|-------|---------|
| OB-02..04 | Tap CTA "Continuer"/"Commencer" → slide suivant / AU-01 ; Tap "Passer" → AU-01 |
| AU-01 | Saisir email + mdp → Se connecter ; "Mot de passe oublié ?" → AU-03 ; Google → OAuth ; "Créer" → AU-02 |
| AU-02 | Saisir 4 champs → Créer compte ; Google → OAuth ; back → AU-01 |
| AU-03 | Saisir email → "Envoyer le lien" → état succès ; "Se connecter" → AU-01 |
| SETUP-01 | Saisir ville → Choisir méthode → Toggle DST → "Continuer" → SETUP-02 ; "Configurer plus tard" → skip |
| SETUP-02 | "Activer les notifications" → prompt OS ; "Plus tard" → skip → HM-01 |
| HM-01 | Tap niyyah Edit → NIYYAH-EDIT ; Tap reminder card → SL-01 ; Tap cloche header → ? (Q-07) |
| SL-01 | Tap bouton statut prière → cycle statut ; Tap SalatRow → SL-DETAIL |
| HB-01 | Tap "+" → HB-02 ; Tap chip filtre → filtre ; Tap toggle → `HabitLogStatus.done` ; Tap row → HB-DETAIL |
| HB-02 | Saisir nom ; Select catégorie ; "Gérer mes catégories" → HB-03 ; Select fréquence ; Select plage ; Select jours ; "Créer l'habitude" → HB-01 |
| HB-03 | Tap "+" → HB-04 ; Tap "Nouvelle catégorie" → HB-04 ; Tap row → ? (édition catégorie non wireframée) |
| HB-04 | Saisir nom ; Select couleur ; Select icône ; Slider pts (1–10) ; "Créer la catégorie" → HB-03 |
| CO-01 | Tap "+" → CO-02 ; Tap "Activer" → activation ; Tap card → CO-DETAIL |
| CO-02 | Saisir titre + description ; Select catégorie + icône ; Checker habitudes ; "Créer la collection" → CO-01 |
| LB-01 | Scroll ; Tap row → ? (profil public non wireframé — incohérence #16) |
| HB-DETAIL | "Modifier" → HB-02 (édition) ; "Supprimer" → confirmation → supprimer → HB-01 |
| CO-DETAIL | "Activer cette collection" → CO-01 (collection activée) |
| SL-DETAIL | Tap X → retour SL-01 ; Tap StatusBtn × 4 ; Toggle rattrapée |
| NIYYAH-EDIT | Saisir intention (200c) ; "Confirmer" → HM-01 ; Tap X → retour |
| ST-01 | Tap profil/Modifier → ST-02 ; Tap Notifications → ? (Q-07) ; Tap Horaires → SETUP-01 ; "Se déconnecter" → AU-01 ; "Supprimer" → ST-03 |
| ST-02 | Modifier nom/pseudonyme ; "Modifier la photo" ; "Enregistrer" → ST-01 |
| ST-03 | Saisir "DELETE" → débloquer → "Supprimer définitivement" |
| LEVEL-UP | "Continuer" → fermer overlay → HM-01 |
| CAL-01 | Tap ◀ / ▶ → mois ; Tap chip filtre ; Tap jour → détail du jour |

---

## 4. États visibles par écran

| Écran | États |
|-------|-------|
| SL-01, SL-DETAIL | Par prière : `pending` / `ontime` / `late` / `missed` + toggle `isMakeup` |
| HB-01 | Vide → EMPTY-HB ; Chargement (non wireframé) ; Peuplé ; Filtré |
| HB-02 | Saisie ; Validation OK ; Erreur champ vide |
| HB-04 | Saisie ; Couleur sélectionnée ; Aperçu |
| CO-01 | Vide → EMPTY-CO ; Avec collections ; Collection activée / non activée |
| LB-01 | Vide → EMPTY-LB ; Avec données |
| CAL-01 | Vide → EMPTY-CAL ; Avec données ; Jour sélectionné |
| AU-03 | Saisie ; Succès (lien envoyé) |
| ST-03 | Input vide (bouton disabled) ; "DELETE" saisi (bouton enabled) |
| LEVEL-UP | Overlay plein écran (déclenché par changement de niveau) |
| Toutes les listes | État chargement non documenté dans les wireframes (**incohérence #8**) |

---

## 5. Données affichées et saisies par écran

| Écran | Données affichées | Données saisies |
|-------|-------------------|-----------------|
| HM-01 | `displayName`, `dailyPoints`, `dailyGoal`, `currentLevel`, `weeklyRank`, `streak`, `salatToday 3/5`, `habitsToday 8/12`, `nextPrayer{name,time,countdown}`, `dailyNiyyah` | — |
| SL-01 | `PrayerDay` (5 prières × `{nameAr, nameFr, scheduledTime, status}`), date hijri + grégorien, nb complétées, points gagnés | statut prière (toggle) |
| SL-DETAIL | Prayer `{nameAr, nameFr, scheduledTime, countdown}`, `status` actuel, semaine courante (7 statuts) | `PrayerStatus` × 4 boutons + `isMakeup` toggle |
| HB-01 | `List<Habit>` par `Category` + `HabitLog` du jour par habitude | toggle `HabitLogStatus.done` |
| HB-02 | `List<Category>` (chips) | nom, catégorie, fréquence, plage horaire from/to, jours actifs (7) |
| HB-03 | `List<Category>` + compteur habitudes/catégorie | — |
| HB-04 | 9 couleurs hex, 10 icônes Lucide | nom, couleur, icône, points (1–10) |
| HB-DETAIL | `Habit{streak, record, tauxJ30}`, heatmap 30j `List<HabitLog>`, historique liste | — |
| CO-01 | `List<Collection>{title, tags[catégorie, nbHabitudes, pts/jour], isActive, videoUrl}` | — (action: activer) |
| CO-02 | `List<Category>`, `List<Habit>` (sélection) | titre, description, catégorie, icône, `habitIds[]` |
| CO-DETAIL | `Collection{description, habits[name,freq,pts]}`, potentiel journalier total | — (action: activer) |
| LB-01 | `List<UserScore>{weeklyPoints, weeklyRank, displayName, initial}`, semaine, nb participants | — |
| NIYYAH-EDIT | `dailyNiyyah` actuelle | texte (200c max) |
| ST-01 | `User{displayName, email, avatar, currentLevel}`, préférences `{notifs, theme, calcMethod, city, dailyGoal, weekStart, language}` | — |
| ST-02 | `User{displayName, email, username}` | `displayName`, `username` |
| CAL-01 | `List<DailySummary>{date, salatCount/5, habitsCount/total, score, summaryText}` | filtre type |
| LEVEL-UP | `Level{name, label, quote}` | — |

---

## 6. Incohérences détectées (16)

**#1 — HB-04 — Catégorie sans champ `icon`**  
Le wireframe HB-04 propose 10 icônes Lucide pour les catégories. L'entité `Category` ne possède pas de champ `icon`. → Ajouter `String? iconName`.

**#2 — HM-01, NIYYAH-EDIT — Entité `DailyNiyyah` absente**  
La carte niyyah + NIYYAH-EDIT nécessitent un stockage. Aucune entité ni repository ni use case ne couvre la niyyah.  
→ Manquent : `DailyNiyyah`, `NiyyahRepository`, `GetTodayNiyyah`, `SetTodayNiyyah`.

**#3 — HM-01, ST-01 — Champ `dailyGoal` absent**  
"objectif 60" sur HM-01 et configurable dans ST-01. Ni `User` ni `UserScore` ne stockent `dailyGoal`.

**#4 — ST-01, SETUP-01 — Préférences utilisateur non modélisées**  
`prayerCalculationMethod`, `city`, `country`, `timezone`, `weekStartsOn`, `language`, `theme` absents de toute entité. Décision technique : Supabase (`user_preferences`) ou local (`flutter_secure_storage`) ?

**#5 — SL-DETAIL — Statut `makeup` non modélisé**  
Toggle "Marquer comme rattrapée". `PrayerStatus` ne contient pas de valeur `makeup`. → Flag `isMakeup: bool` par prière dans `PrayerDay` (Q-06).

**#6 — HB-02 — Fréquences `mensuel` et `custom` non modélisées**  
6 options dans le wireframe. L'entité `Habit` ne couvre que `frequency: int` + `activeDays: Set<int>`. Mensuel/Custom débordent ce modèle (Q-02).

**#7 — LB-01 — `getLeaderboard()` sans paramètre de période**  
L'affichage montre la semaine. `ScoreRepository.getLeaderboard({required int limit})` ne prend pas de semaine. → Signature à revoir (Q-08).

**#8 — Toutes les listes — État chargement non documenté**  
HB-01, CO-01, LB-01, CAL-01 n'ont pas d'état skeleton/spinner dans les wireframes. À implémenter selon les bonnes pratiques, non validé visuellement.

**#9 — HB-DETAIL — Métriques `streak`, `record`, `tauxJ30` non persistées**  
Ces trois valeurs sont calculées (non stockées directement). Use case `GetHabitStats(habitId)` manquant.

**#10 — LEVEL-UP — Aucun use case de déclenchement**  
L'overlay LEVEL-UP se déclenche au franchissement d'un palier. Aucun use case `CheckAndEmitLevelUp` ni stream n'est modélisé.

**#11 — CAL-01 — Entité `DailySummary` et use case `GetMonthSummary` manquants**  
CAL-01 affiche `salatCount/5`, `habitsCount/total`, `score`, `summaryText` par jour. Aucun use case agrégé ne couvre cette vue.

**#12 — CO-01 — `pts/jour` calculé à la volée, non persisté**  
Les tags "12 pts/jour" viennent de la somme des `HabitPoints`. Ce calcul doit être fait dans le use case ou le provider, documenté pour ne pas créer d'attribut fantôme.

**#13 — ST-01 — Écran Notifications non wireframé**  
ST-01 → "Notifications" pointe vers un écran de réglages non livré dans les wireframes (Q-07).

**#14 — SL-01, SETUP-01 — Heures de prière absentes de `PrayerDay`**  
`SalatRow` affiche l'heure calculée (ex. "06:14"). `PrayerDay` ne stocke pas ces heures. Calcul local (`adhan`) ou API externe (Q-05).

**#15 — HB-03 — Édition catégorie non wireframée**  
Tap sur une `CategoryRow` → destination non définie. Modifier une catégorie (nom, couleur, icône) est implicite mais l'écran est absent.

**#16 — LB-01 — Tap sur un rang : profil public absent**  
Tap sur une LeaderRow → écran de destination non documenté. Périmètre hors V1 probable, à confirmer.

---

## 7. Questions métier ouvertes (Q-02 à Q-12)

| Code | Sujet | Bloquant | Recommandation |
|------|-------|----------|----------------|
| **Q-02** | Fréquences habitudes en V1 | OUI — HB-02 | V1 = Quotidien / N×/semaine / Hebdo. Mensuel + Custom → V2 |
| **Q-03** | Niyyah : local ou Supabase | OUI — HM-01/NIYYAH-EDIT | Supabase `daily_niyyah(user_id, date, text)`, RLS stricte |
| **Q-04** | Streak global sur HM-01 | OUI — HM-01 | Streak "journée complète" (Salat + Habitudes du jour) via trigger Supabase |
| **Q-05** | Calcul horaires de prière | OUI — SL-01/SETUP-01 | Package `adhan` (offline), cache local, refresh quotidien |
| **Q-06** | PrayerStatus `makeup` | OUI — SL-DETAIL | Flag `isMakeup: bool` par prière dans `PrayerDay`, pas de 5e enum |
| **Q-07** | Écran Paramètres Notifications | non — V2 | Déléguer aux réglages système iOS/Android en V1 |
| **Q-08** | Leaderboard : scope et période | OUI — LB-01 | Global + semaine calendaire lun-dim, recalculée chaque dimanche |
| **Q-09** | Level-up : push ou in-app | non | Push (F9) + overlay in-app LEVEL-UP |
| **Q-10** | `dailyGoal` : valeur et mutabilité | OUI — HM-01 | Configurable, défaut 60 pts, stocké dans `user_preferences` |
| **Q-11** | Résumé texte CAL-01 : auto ou saisi | non | Auto-généré côté client (template fixe), non persisté |
| **Q-12** | Suppression compte : délai 30j | OUI — ST-03 | Soft-delete + Auth désactivé immédiatement + cron 30j |

---

## 8. Use cases manquants identifiés

| Use case | Déclenché par |
|----------|---------------|
| `GetTodayNiyyah(userId)` | HM-01 (affichage) |
| `SetTodayNiyyah(userId, text)` | NIYYAH-EDIT (confirmation) |
| `GetHabitStats(habitId)` → `{streak, record, tauxJ30}` | HB-DETAIL |
| `CheckAndEmitLevelUp(userId)` | Après `markPrayer` / `toggleHabitLog` |
| `GetMonthSummary(userId, year, month)` → `List<DailySummary>` | CAL-01 |
| `GetPrayerSchedule(userId, date)` → horaires calculés | SL-01, SL-DETAIL, SETUP-01 |

---

## 9. Récapitulatif

| Métrique | Valeur |
|----------|--------|
| Écrans inventoriés | 32 |
| Composants UI distincts | 24 |
| Incohérences détectées | 16 |
| Attributs manquants dans le domaine | 8 |
| Use cases manquants | 6 |
| Questions métier ouvertes | 11 (Q-02 à Q-12) |
| Questions bloquantes | 7 (Q-02, Q-03, Q-04, Q-05, Q-06, Q-08, Q-10) |

---

*Audit produit en Phase 0 · Sources lues le 2026-04-28*  
*Q-01 (wireframes manquants) → **fermée***
