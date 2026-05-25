# Q-20 — FCM : credentials Firebase — projet créé, service account à finaliser

**Date** : 2026-05-23
**Issue** : #174 (MOB-006)
**Statut** : ✅ Résolu — 2026-05-24

---

## Contexte

MOB-006 implémente le service FCM (`lib/services/notification/fcm_service.dart`)
avec une architecture injectable qui isole le plugin natif `firebase_messaging`
des couches domain et test. L'implémentation est complète et testée (8/8 tests verts).

---

## Statut actuel (2026-05-23)

Le projet Firebase **`murabbi-90798`** a été créé via la console Firebase.

### Ce qui est fait

- [x] Projet Firebase créé : `murabbi-90798` (GCM Sender ID : `61286833902`)
- [x] App Android enregistrée : `com.murabbi.murabbi` (App ID : `1:61286833902:android:bc1df280dfec8d4d8e1dff`)
- [x] App iOS enregistrée : `com.murabbi.murabbi` (App ID : `1:61286833902:ios:4c4b42f5d5602b788e1dff`)
- [x] `android/app/google-services.json` — présent sur le device, gitignored
- [x] `ios/Runner/GoogleService-Info.plist` — présent sur le device, gitignored
- [x] FCM v1 API activée
- [x] `firebase_core: ^2.30.0` et `firebase_messaging: ^14.9.0` ajoutés à `pubspec.yaml`

### Ce qui a été fait (2026-05-24 — session de clôture)

Toutes les étapes ont été réalisées lors de la session PR #211 + fix/firebase-init-wiring :

- [x] **Étape 1** — Clés orphelines `66c22874` et `d4283ad0` supprimées via GCP Console
- [x] **Étape 2** — Nouvelle clé `0776ea49e1b7` créée, JSON récupéré (`murabbi-90798-0776ea49e1b7.json`)
- [x] **Étape 3** — Secret `FIREBASE_SERVICE_ACCOUNT_KEY` configuré sur le projet Supabase `ocvmtrblptbjgbpruwqs` (murabbi-prod) via `supabase secrets set`
- [x] **Étape 4** — `lib/firebase_options.dart` généré manuellement (Q-20 §4) et commité dans PR #211
- [x] **Étape 5** — `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` ajouté à `main.dart` dans `fix/firebase-init-wiring`
- [x] **Dépendances** — `firebase_core ^3.6.0` + `firebase_messaging ^15.1.0` (upgradé depuis v2/v14 pour compatibilité geolocator ^13 — cf. pubspec.yaml commentaire)

> Note : le dashboard Supabase Push Notifications (URL `/auth/push-notifications`)
> retourne 404 sur le plan FREE/NANO. Le secret est configuré via CLI — c'est
> suffisant pour les Edge Functions + Firebase Admin SDK (Option A retenue).

---

## Impact sur la livraison

- MOB-006 côté Dart : complet et testé (8/8 tests verts).
- Connexion native Firebase : ✅ opérationnelle — `Firebase.initializeApp()` câblé dans `main.dart`, background handler enregistrable.
- Supabase secret FCM : ✅ configuré — Edge Functions pourront s'authentifier auprès de FCM v1.

**Q-20 fermée.**
