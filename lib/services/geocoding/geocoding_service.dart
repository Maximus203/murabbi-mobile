import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:murabbi_mobile/core/utils/logger.dart';

/// Résultat d'un appel de géocodage inverse.
sealed class GeocodingResult {
  const GeocodingResult();
}

/// Géocodage réussi — contient le libellé de ville.
final class GeocodingSuccess extends GeocodingResult {
  /// Libellé formaté : "Ville, Pays" (ex. "Paris, France").
  final String label;
  const GeocodingSuccess(this.label);
}

/// Géocodage échoué — erreur réseau ou réponse inattendue.
final class GeocodingFailure extends GeocodingResult {
  final String message;
  const GeocodingFailure(this.message);
}

/// Service de géocodage inverse basé sur Nominatim (OpenStreetMap).
///
/// Convertit des coordonnées (lat, lng) en nom de ville lisible.
/// Pas de clé API requise — conforme aux CGU Nominatim (1 req/s max).
///
/// ADR-013 §Localisation : Nominatim choisi pour son coût nul et sa précision
/// suffisante pour l'affichage du contexte de localisation dans SA-02.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Résout les coordonnées en libellé "Ville, Pays".
  ///
  /// Utilise Nominatim en français (`accept-language=fr`).
  /// Retourne [GeocodingSuccess] si la réponse est exploitable,
  /// [GeocodingFailure] sinon (réseau indisponible, réponse vide…).
  Future<GeocodingResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'json',
      'accept-language': 'fr',
      'zoom': '10', // niveau ville
    });

    try {
      final response = await _client.get(
        uri,
        headers: {
          // CGU Nominatim : user-agent obligatoire.
          'User-Agent': 'Murabbi-Mobile/1.0 (assistanat8@gmail.com)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        appLog.w(
          'GeocodingService: HTTP ${response.statusCode} for ($latitude, $longitude)',
        );
        return const GeocodingFailure('Réponse HTTP inattendue');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (json == null) {
        return const GeocodingFailure('Réponse vide');
      }

      final label = _extractLabel(json);
      if (label == null) {
        appLog.w(
          'GeocodingService: no city in response for ($latitude, $longitude)',
        );
        return const GeocodingFailure('Ville non trouvée');
      }

      return GeocodingSuccess(label);
    } catch (e, st) {
      appLog.e(
        'GeocodingService.reverseGeocode failed',
        error: e,
        stackTrace: st,
      );
      return GeocodingFailure(e.toString());
    }
  }

  /// Extrait "Ville, Pays" depuis la réponse Nominatim.
  ///
  /// Cascade de priorité : city → town → village → county → state.
  static String? _extractLabel(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;
    if (address == null) return null;

    final city =
        address['city'] as String? ??
        address['town'] as String? ??
        address['village'] as String? ??
        address['county'] as String? ??
        address['state'] as String?;

    final country = address['country'] as String?;

    if (city == null) return null;
    if (country == null) return city;
    return '$city, $country';
  }
}

/// Provider singleton du [GeocodingService].
///
/// Non-autoDispose : le service est léger et partagé par SA-01/SA-02.
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});
