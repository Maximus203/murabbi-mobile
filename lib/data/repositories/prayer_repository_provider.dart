import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/salat_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_salat_data_source.dart';
import 'package:murabbi_mobile/data/repositories/prayer_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';

/// Provider Riverpod du datasource Salat (slice 3.B Phase 3).
final salatDataSourceProvider = Provider<SalatDataSource>((ref) {
  return SupabaseSalatDataSource(
    ref.watch(supabaseClientProvider),
    wrapper: ref.watch(supabaseClientWrapperProvider),
  );
});

/// Provider Riverpod du `PrayerRepository`. La couche presentation consomme
/// uniquement ce provider (l'interface domain), jamais l'impl ni le
/// datasource directement.
final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepositoryImpl(ref.watch(salatDataSourceProvider));
});
