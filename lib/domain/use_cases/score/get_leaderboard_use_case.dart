import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';

class GetLeaderboardUseCase {
  final ScoreRepository _repository;
  const GetLeaderboardUseCase(this._repository);

  Future<List<UserScore>> call({required int limit}) =>
      _repository.getLeaderboard(limit: limit);
}
