import 'package:murabbi_mobile/data/datasources/supabase/supabase_niyyah_suggestion_data_source.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_suggestion.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_suggestion_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class NiyyahSuggestionRepositoryImpl implements NiyyahSuggestionRepository {
  final SupabaseNiyyahSuggestionDataSource _ds;

  const NiyyahSuggestionRepositoryImpl(this._ds);

  @override
  Future<List<NiyyahSuggestion>> getActiveSuggestions() => _guard(() async {
        final rows = await _ds.getActiveSuggestions();
        return rows.map(_fromRow).toList(growable: false);
      });

  NiyyahSuggestion _fromRow(Map<String, dynamic> row) => NiyyahSuggestion(
        id: row['id'] as String,
        textFr: row['text_fr'] as String,
        textAr: row['text_ar'] as String?,
        sortOrder: (row['sort_order'] as num).toInt(),
        active: row['active'] as bool? ?? true,
      );

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on sb.PostgrestException {
      rethrow;
    }
  }
}
