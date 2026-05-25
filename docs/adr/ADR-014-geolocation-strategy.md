# ADR-014 — Geolocation strategy for prayer settings (SA-02)

**Statut** : Accepté · slice 3.C.3 follow-up
**Date** : 2026-05-13

## Contexte

SA-02 (Réglages des prières) demande à l'utilisateur sa latitude / longitude pour calculer les horaires via `adhan_dart` (ADR-013). En V1 la saisie est manuelle. La décision PO Q-21 (option B1) exige l'ajout d'un bouton **"Utiliser ma position"** qui remplit automatiquement les deux champs via le GPS de l'appareil.

## Décision

Ajout du package **`geolocator`** (^13.0.0, BSD-3-Clause, Baseflow) comme abstraction multi-plateforme du GPS natif.

### Architecture

```
presentation (SA-02)
       ▼
LocationService (interface domain)
       ▼
GeolocatorLocationService (impl) ──► geolocator native
```

- **Interface** : `LocationService` (`lib/services/location/location_service.dart`) — méthode unique `getCurrentPosition()` retournant `LocationResult` (sealed : `Success(lat, lng) / PermissionDenied / ServiceDisabled / Unknown(e)`).
- **Impl** : `GeolocatorLocationService` wrap les appels natifs et traduit les exceptions / status en `LocationResult` typés.
- **Provider Riverpod** : `locationServiceProvider` — overrideable en tests (fake retournant un `LocationResult` figé).
- **Règle d'isolation** : *seul* le fichier d'impl peut importer `package:geolocator/geolocator.dart`. Toute autre couche utilise l'interface.

### Flow UX sur SA-02

1. Tap "Utiliser ma position" → bouton passe en loading.
2. Service tente d'obtenir la position courante.
3. Sur `Success` → pré-remplit lat / lng + clearError.
4. Sur `PermissionDenied` → snackbar "Autorise la localisation dans les réglages" + lien settings (`Geolocator.openAppSettings()`).
5. Sur `ServiceDisabled` → snackbar "Active la localisation système" + lien (`Geolocator.openLocationSettings()`).
6. Sur `Unknown` → snackbar générique.

### Permissions natives

- **Android** : `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION` dans `AndroidManifest.xml`. La précision fine est utile pour la lat/lng exacte (les calculs `adhan_dart` sont sensibles à ~0.5°).
- **iOS** : `NSLocationWhenInUseUsageDescription` dans `Info.plist` avec un message FR clair ("Murabbi utilise ta position pour calculer les horaires de prière de ton lieu").
- Pas de background location (besoin uniquement quand l'utilisateur configure ses settings).

## Options rejetées

- **Geocoding ville (Nominatim / Google Geocoding)** : demande un service réseau + clé API + politique de cache. Reporté V2.
- **`location` package (Bloom)** : moins maintenu, API moins clean que `geolocator`.
- **Native channel manuel** : surcoût pour aucun gain.

## Conséquences

- Surface code mobile +~150 lignes (service + UI button + tests).
- 2 deps natives à configurer (Android manifest, iOS Info.plist).
- Couverture device manuelle requise : tester refus permission, service GPS désactivé, succès rapide indoor (basé sur cell tower) vs lent outdoor (GPS frais).
- Aucun impact sur la couche calcul (PrayerTimesService reçoit toujours des lat/lng nues).
