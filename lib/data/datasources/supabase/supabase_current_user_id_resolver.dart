import 'package:murabbi_mobile/core/network/current_user_id_resolver.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [CurrentUserIdResolver].
///
/// Lit `_client.auth.currentUser?.id` — synchrone côté SDK, exposé en
/// `Future<String?>` pour respecter le contrat domaine et autoriser des
/// implémentations futures asynchrones (refresh token, etc.).
///
/// Créé pour l'issue #202 (M3) — utilisé par les repositories Habit /
/// Collection / Category pour vérifier l'ownership avant tout appel
/// réseau (cf. `OwnershipGuard`).
class SupabaseCurrentUserIdResolver implements CurrentUserIdResolver {
  final sb.SupabaseClient _client;

  const SupabaseCurrentUserIdResolver(this._client);

  @override
  Future<String?> currentUserId() async {
    return _client.auth.currentUser?.id;
  }
}
