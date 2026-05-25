import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/presentation/theme/app_media.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de résolution des URLs vidéo in-app depuis Supabase Storage.
///
/// ADR-017 : les vidéos in-app (01/07/08/09/10/11) sont hébergées dans le
/// bucket Supabase [AppMedia.mediaBucket]. Ce service expose une URL publique
/// signée pour chaque clé.
///
/// Usage :
/// ```dart
/// final url = ref.read(videoServiceProvider).getRemoteVideoUrl(AppMedia.niyyahVideoKey);
/// ```
///
/// Note : ce service ne gère pas le cycle de vie des vidéos (initialisation,
/// dispose). C'est la responsabilité du widget [AppVideoPlayer].
class VideoService {
  /// Client Supabase injecté (cf. [supabaseClientProvider]).
  final SupabaseClient _supabase;

  /// Crée un [VideoService] avec le client Supabase fourni.
  VideoService(this._supabase);

  /// Retourne l'URL publique d'une vidéo in-app depuis Supabase Storage.
  ///
  /// [key] : clé du fichier dans le bucket [AppMedia.mediaBucket]
  ///   (ex. [AppMedia.niyyahVideoKey]).
  ///
  /// L'URL est publique (le bucket `app-media` est en lecture publique —
  /// ADR-017 §Conséquences). Aucun appel réseau n'est effectué ici : la
  /// méthode retourne une URL construite localement.
  String getRemoteVideoUrl(String key) {
    return _supabase.storage.from(AppMedia.mediaBucket).getPublicUrl(key);
  }
}

/// Provider du [VideoService].
///
/// Utilise le [supabaseClientProvider] comme source unique du client.
/// Accessible uniquement depuis la couche `presentation/` via providers
/// (règle ADR-001 : `presentation → services`, jamais `domain` ni `data`
/// directement).
final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService(ref.watch(supabaseClientProvider));
});
