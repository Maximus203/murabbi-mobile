import 'package:murabbi_mobile/domain/repositories/pseudonym_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';

/// Q-10 — délègue la vérification banlist au repository (call admin).
class CheckPseudoAvailableUseCase {
  final PseudonymRepository _repository;
  const CheckPseudoAvailableUseCase(this._repository);

  Future<bool> call(Pseudonym pseudo) => _repository.isAllowed(pseudo);
}
