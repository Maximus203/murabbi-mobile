import 'package:murabbi_mobile/data/datasources/supabase/supabase_niyyah_suggestion_data_source.dart';
import 'package:murabbi_mobile/data/mappers/niyyah_suggestion_mapper.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_suggestion.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_suggestion_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase du [NiyyahSuggestionRepository].
///
/// Délègue à [SupabaseNiyyahSuggestionDataSource] et traduit les rows en
/// entités via [NiyyahSuggestionMapper]. Pattern `PrayerRepositoryImpl`.
class NiyyahSuggestionRepositoryImpl implements NiyyahSuggestionRepository {
  final SupabaseNiyyahSuggestionDataSource _ds;

  const NiyyahSuggestionRepositoryImpl(this._ds);

  @override
  Future<List<NiyyahSuggestion>> getActiveSuggestions() => _guard(() async {
    final rows = await _ds.getActiveSuggestions();
    return rows
        .map(NiyyahSuggestionMapper.fromRow)
        .toList(growable: false);
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on sb.PostgrestException catch (e) {
      throw Exception(
        'NiyyahSuggestion database error: ${e.code ?? ''} ${e.message}',
      );
    } catch (e) {
      rethrow;
    }
  }
}
