import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/repositories/daily_summary_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Retourne le [DailySummary] de l'utilisateur pour aujourd'hui,
/// ou null si aucune activité n'a encore été enregistrée ce jour.
class GetDailySummaryUseCase {
  final DailySummaryRepository _repository;

  const GetDailySummaryUseCase(this._repository);

  Future<DailySummary?> call(UserId userId) =>
      _repository.getTodaySummary(userId);
}
