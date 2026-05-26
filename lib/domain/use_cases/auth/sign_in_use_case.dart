import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/email_address.dart';
import 'package:murabbi_mobile/domain/value_objects/password.dart';

class SignInUseCase {
  final AuthRepository _repository;
  const SignInUseCase(this._repository);

  Future<User> call({required String email, required String password}) {
    final validatedEmail = EmailAddress(email);
    final validatedPassword = Password(password);
    return _repository.signIn(
      email: validatedEmail.value,
      password: validatedPassword.value,
    );
  }
}
