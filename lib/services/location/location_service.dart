import 'package:equatable/equatable.dart';

/// Résultat typé d'une demande de géolocalisation (cf. ADR-014).
///
/// Sealed pour switch exhaustif côté UI — l'ajout d'un nouveau cas
/// (ex: timeout) doit forcer la mise à jour des consumers.
sealed class LocationResult extends Equatable {
  const LocationResult();

  @override
  List<Object?> get props => [runtimeType];
}

/// Position obtenue avec succès — lat/lng en degrés décimaux.
class LocationSuccess extends LocationResult {
  final double latitude;
  final double longitude;

  const LocationSuccess({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

/// L'utilisateur a refusé la permission, soit ponctuellement, soit
/// "deniedForever" (besoin d'aller dans les réglages OS).
class LocationPermissionDenied extends LocationResult {
  final bool deniedForever;
  const LocationPermissionDenied({required this.deniedForever});

  @override
  List<Object?> get props => [deniedForever];
}

/// Le service de localisation est désactivé au niveau OS (mode avion,
/// switch GPS off, etc.).
class LocationServiceDisabled extends LocationResult {
  const LocationServiceDisabled();
}

/// Erreur imprévue — timeout, hardware fail, etc. Message conservé pour
/// debug.
class LocationUnknownError extends LocationResult {
  final String message;
  const LocationUnknownError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Contrat de domain pour obtenir la position courante. Pure interface —
/// l'impl `geolocator` vit dans `geolocator_location_service.dart` et
/// reste isolée (règle ADR-014 §Architecture).
abstract interface class LocationService {
  /// Demande la position courante. Gère l'enchaînement
  /// `checkPermission` → `requestPermission` → `getCurrentPosition`.
  ///
  /// Ne lève jamais : tous les cas d'erreur sont retournés sous forme de
  /// `LocationResult.*` typé.
  Future<LocationResult> getCurrentPosition();

  /// Ouvre les réglages app OS (utile après `PermissionDenied`
  /// `deniedForever=true`).
  Future<void> openAppSettings();

  /// Ouvre les réglages système de localisation (utile après
  /// `ServiceDisabled`).
  Future<void> openLocationSettings();
}
