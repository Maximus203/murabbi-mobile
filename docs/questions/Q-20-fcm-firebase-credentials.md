# Q-20 — FCM : credentials Firebase — projet créé, service account à finaliser

**Date** : 2026-05-23
**Issue** : #174 (MOB-006)
**Statut** : Partiellement résolu — action manuelle Cherif requise

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

### Ce qui reste — ACTION MANUELLE CHERIF REQUISE

Deux clés de service account orphelines ont été créées lors de la session de
configuration et doivent être supprimées puis remplacées par une clé valide.

**Étape 1 — Supprimer les clés orphelines**

Ouvre : https://console.cloud.google.com/iam-admin/serviceaccounts?project=murabbi-90798

→ Clique sur `firebase-adminsdk-fbsvc@murabbi-90798.iam.gserviceaccount.com`
→ Onglet **Clés**
→ Supprime les deux clés orphelines (private key jamais récupérée) :
  - `66c22874c0600731f2e9fbc41f0a36de04a70b4f`
  - `d4283ad02f819201ff281ce10efca9cbe74f058d`

**Étape 2 — Créer une nouvelle clé JSON**

→ Toujours dans l'onglet **Clés** → **Ajouter une clé** → **JSON**
→ Télécharge le fichier (c'est la seule et unique occasion de récupérer le private key)
→ Ce fichier JSON est nécessaire pour que Supabase s'authentifie auprès de FCM v1

**Étape 3 — Configurer Supabase Push Notifications**

→ Dashboard Supabase → **Project Settings** → **Auth** → **Push Notifications**
→ Colle le contenu JSON complet de la clé de service account dans le champ FCM

**Étape 4 — Générer `firebase_options.dart` et committer**

Ce fichier est commitable (aucun secret — contient uniquement les app IDs publics).

```bash
# Prérequis
dart pub global activate flutterfire_cli
firebase login   # s'authentifier avec le compte Google propriétaire de murabbi-90798

# Génération (depuis la racine de murabbi-mobile)
flutterfire configure --project=murabbi-90798
# → génère lib/core/firebase_options.dart
```

Puis committer `lib/core/firebase_options.dart` et fermer Q-20.

---

## Impact sur la livraison

- MOB-006 côté Dart : complet et testé (8/8 tests verts).
- Connexion native Firebase (initialisation au démarrage, background handler) :
  bloquée sur `firebase_options.dart` + configuration Supabase push.
- `pubspec.yaml` à jour avec `firebase_core` et `firebase_messaging`.

**Bloquant pour le déploiement store — non bloquant pour le développement local.**
