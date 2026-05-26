# Q-24 — Inventaire des moments rares & interfaces éphémères

**Date d'ouverture :** 2026-05-25
**Statut :** En attente de réponses PO (A–E)

---

## Inventaire

### 1. Onboarding
- `setup_01_onboarding_screen.dart` — 4 slides, une seule fois à l'inscription
- Statut : ✅ Implémenté — à auditer visuellement

### 2. Célébrations in-app (overlays plein écran)

| Moment | Fichier | Statut | Trigger |
|---|---|---|---|
| Passage de niveau | `level_up_screen.dart` | ✅ Implémenté | `levelUpNotifierProvider` sur changement `totalPoints` |
| Streak 7 jours | *(à créer)* | ❌ Manquant | `currentStreak == 7` |
| Streak 30 jours | *(à créer)* | ❌ Manquant | `currentStreak == 30` |
| Streak 365 jours | *(à créer)* | ❌ Manquant | `currentStreak == 365` |
| 1er mois d'utilisation | *(à créer)* | ❌ Non défini | `createdAt` + 30 jours |

**Identité visuelle streak (mockup G1) :**
- Fond beige clair (≠ fond vidéo sombre du level-up)
- Icône flamme dans cercle
- Label "X JOURS CONSÉCUTIFS" + titre poétique ("Une semaine ancrée.")
- Sous-titre motivationnel
- Calendrier "7 DERNIERS JOURS" avec checkmarks L M M J V S D
- Bouton sombre "Continuer"

### 3. Interruptions / rappels habitudes

| Moment | Nature | Statut |
|---|---|---|
| Notification push "Heure de ton habitude" | Notification OS (flutter_local_notifications) | ✅ Service existant, scheduling non câblé |
| Écran de rappel in-app (app ouverte à l'heure) | Modal ou bottom sheet | ❌ Manquant |
| Deep link depuis notification → écran habitude | go_router | ❌ Non câblé |

### 4. Notifications OS — types à implémenter

- Rappel habitude (heure planifiée)
- Rappel salat (avant chaque prière, si activé)
- Rappel niyyah du matin
- "Tu n'as pas encore validé tes habitudes aujourd'hui" (soir)
- Streak en danger — "Il te reste X heures pour maintenir ta série"
- Félicitation push (streak atteint, niveau monté)

**Infrastructure existante :** `LocalNotificationService`, `NotificationPlatform`,
entités `Notification` / `ScheduledNotification` dans `lib/domain/entities/`.
Le scheduling réel n'est pas encore câblé aux habitudes/prières.

### 5. Widgets home screen

| Widget | Plateforme | Contenu cible |
|---|---|---|
| Petit (2×2) | iOS + Android | Prochaine prière + countdown |
| Moyen (2×4) | iOS + Android | Prochaine prière + streak + complétion habits |
| Grand (4×4) | iOS | Résumé du jour complet |

Statut : ❌ Non commencé.
Paquets envisagés : `home_widget` (Flutter cross-platform) ou natif
(Android AppWidget / iOS WidgetKit).

### 6. Live Activities (iOS)

Cas d'usage : countdown "Fajr dans 12 min" sur écran verrouillé / Dynamic Island.
Statut : ❌ Non commencé.
Paquet envisagé : `live_activities` + ActivityKit iOS 16+.
Android équivalent : notification expandable persistante.

### 7. Autres moments in-app

| Moment | Statut | Note |
|---|---|---|
| Dialogue déconnexion | ✅ Implémenté | AppDialog dans HM-01 |
| Overlay vérification email | ✅ Implémenté | `au_04_email_verification_gate` |
| CTA "Configurer prières" | ✅ Implémenté | `_NextPrayerCard` |
| Premier lancement sans compte (Guest mode ?) | ❌ Non défini | À décider |
| Écran erreur réseau global | ❌ Manquant | `offline_banner` existe, pas d'écran complet |
| Écran maintenance / force-update | ❌ Manquant | À prévoir Phase 6 |

---

## Questions ouvertes PO

### A — Seuils de célébration streak
Quels jalons déclenchent un écran de célébration ?
- **Option A :** 7j / 30j / 365j ← lecture du mockup G1
- Option B : 7j / 21j / 100j / 365j

### B — Identité visuelle streak vs level-up
Le mockup montre un fond beige sobre (≠ vidéo sombre level-up).
Confirmes-tu ces deux identités visuelles distinctes ?

### C — Widgets : périmètre V1
- Option A : iOS uniquement
- Option B : iOS + Android ensemble

### D — Live Activities : périmètre V1
- Option A : iOS uniquement (Android = notification persistante)
- Option B : Hors scope V1

### E — Rappel in-app quand app déjà ouverte
Quand une habitude arrive à son heure et que l'app est ouverte :
- **Option A :** Bottom sheet "C'est l'heure de [habitude] — Valider maintenant"
- Option B : Aucune interruption in-app (notification OS suffit)

---

*Parking — en attente réponses PO avant implémentation.*
*Priorité suivante côté code : interface d'accueil HM-01 (perfectionnement composants).*
