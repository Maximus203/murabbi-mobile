import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_daily_summary_data_source.dart';
import 'package:murabbi_mobile/data/repositories/daily_summary_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/daily_summary_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>((ref) {
  return DailySummaryRepositoryImpl(
    SupabaseDailySummaryDataSource(Supabase.instance.client),
  );
});
