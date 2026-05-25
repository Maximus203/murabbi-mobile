import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/network/current_user_id_resolver.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_current_user_id_resolver.dart';

/// Provider du [CurrentUserIdResolver] — implémentation Supabase par défaut.
///
/// Overridé en test pour injecter une valeur fixe (cf. issue #202 / M3).
final currentUserIdResolverProvider = Provider<CurrentUserIdResolver>((ref) {
  return SupabaseCurrentUserIdResolver(ref.watch(supabaseClientProvider));
});
