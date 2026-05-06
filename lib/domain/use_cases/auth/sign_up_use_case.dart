import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/email_address.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/password.dart';

class SignUpUseCase {
  final AuthRepository _repository;
  const SignUpUseCase(this._repository);

  Future<User> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    final validatedEmail = EmailAddress(email);
    final validatedPassword = Password(password);
    final validatedName = NonEmptyString(displayName);
    return _repository.signUp(
      email: validatedEmail.value,
      password: validatedPassword.value,
      displayName: validatedName.value,
    );
  }
}
