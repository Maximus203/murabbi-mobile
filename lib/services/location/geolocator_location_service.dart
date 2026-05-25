import 'package:geolocator/geolocator.dart';
import 'package:murabbi_mobile/services/location/location_service.dart';

/// Implémentation `geolocator` du [LocationService] (cf. ADR-014).
///
/// **Règle d'isolation** : ce fichier est le **seul** autorisé à importer
/// `package:geolocator/geolocator.dart`. Toute autre couche utilise
/// l'interface [LocationService] et reçoit un `LocationResult` typé.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return const LocationServiceDisabled();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationPermissionDenied(deniedForever: true);
      }
      if (permission == LocationPermission.denied) {
        return const LocationPermissionDenied(deniedForever: false);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationSuccess(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return LocationUnknownError(e.toString());
    }
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
