import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_niyyah_suggestion_data_source.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_suggestion_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_suggestion_repository.dart';

final niyyahSuggestionRepositoryProvider =
    Provider<NiyyahSuggestionRepository>((ref) {
  return NiyyahSuggestionRepositoryImpl(
    SupabaseNiyyahSuggestionDataSource(
      ref.watch(supabaseClientProvider),
      wrapper: ref.watch(supabaseClientWrapperProvider),
    ),
  );
});
