import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;
  const SignUpUseCase(this._repository);

  Future<User> call({
    required String email,
    required String password,
    required String displayName,
  }) => _repository.signUp(
    email: email,
    password: password,
    displayName: displayName,
  );
}
