import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_niyyah_data_source.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final niyyahRepositoryProvider = Provider<NiyyahRepository>((ref) {
  return NiyyahRepositoryImpl(
    SupabaseNiyyahDataSource(Supabase.instance.client),
  );
});
