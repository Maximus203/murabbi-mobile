# Q-20 — FCM : credentials Firebase manquants (MOB-006)

**Date** : 2026-05-23
**Issue** : #174 (MOB-006)
**Statut** : À valider par le PO

---

## Contexte

MOB-006 implémente le service FCM (`lib/services/notification/fcm_service.dart`)
avec une architecture injectable qui isole le plugin natif `firebase_messaging`
des couches domain et test. L'implémentation est complète et testée (8/8 tests verts).

Cependant, **la connexion native Firebase n'est pas encore branchée** car les
fichiers de credentials suivants ne sont pas disponibles dans le repo :

- `android/app/google-services.json` — projet Firebase Android
- `ios/Runner/GoogleService-Info.plist` — projet Firebase iOS
- `lib/core/firebase_options.dart` — généré par `flutterfire configure`

Ces fichiers sont gitignorés (cf. `.gitignore`) par sécurité.

---

## Question

Cherif, peux-tu fournir ou créer le projet Firebase pour Murabbi ?

Si le projet Firebase n'existe pas encore :

```bash
# 1. Installer Firebase CLI (si pas déjà fait)
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# 2. Se connecter
firebase login

# 3. Créer le projet Firebase
firebase projects:create murabbi-mobile

# 4. Générer les fichiers de config Flutter
flutterfire configure --project=murabbi-mobile
# → génère lib/core/firebase_options.dart
# → génère android/app/google-services.json
# → génère ios/Runner/GoogleService-Info.plist
```

Les deux fichiers de credentials (`google-services.json`, `GoogleService-Info.plist`)
doivent rester **hors du repo** (gitignored). Seul `firebase_options.dart`
est commitable (il ne contient pas de secret, cf. documentation FlutterFire).

---

## Impact sur la livraison

- MOB-006 côté Dart : complet et testé (8/8 tests verts).
- La connexion native (background handler réel, initialisation Firebase) :
  bloquée sur la fourniture de ces credentials.
- Le reste de la Vague 3 G4 (MOB-004, MOB-005, MOB-007) n'est pas bloqué.

---

## Ma recommandation

Tu crées le projet Firebase (gratuit pour Murabbi en V1 avec le Spark plan),
tu génères les fichiers et tu me fournis `firebase_options.dart` par un canal
sécurisé. Je complète la connexion native en 30 min.

**Bloquant ?** Non pour la PR draft — oui pour le déploiement store.
Je continue avec l'option stub documentée et je marque `[WAITING Q-20]`.
