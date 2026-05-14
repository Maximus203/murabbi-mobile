import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/services/location/geolocator_location_service.dart';
import 'package:murabbi_mobile/services/location/location_service.dart';

/// Provider Riverpod du [LocationService] (cf. ADR-014). Overrideable
/// en tests pour injecter un fake retournant un `LocationResult` figé.
final locationServiceProvider = Provider<LocationService>((ref) {
  return const GeolocatorLocationService();
});
