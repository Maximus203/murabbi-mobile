import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repository;
  const SignOutUseCase(this._repository);

  Future<void> call() => _repository.signOut();
}
