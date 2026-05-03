import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class GetUserScoreUseCase {
  final ScoreRepository _repository;
  const GetUserScoreUseCase(this._repository);

  Future<UserScore> call(UserId userId) => _repository.getUserScore(userId);
}
