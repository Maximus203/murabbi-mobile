import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  final AuthRepository _repository;
  const WatchAuthStateUseCase(this._repository);

  Stream<User?> call() => _repository.authStateChanges;
}
