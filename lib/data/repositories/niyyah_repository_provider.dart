import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_niyyah_data_source.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';

final niyyahRepositoryProvider = Provider<NiyyahRepository>((ref) {
  return NiyyahRepositoryImpl(
    SupabaseNiyyahDataSource(
      ref.watch(supabaseClientProvider),
      wrapper: ref.watch(supabaseClientWrapperProvider),
    ),
  );
});
