import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/email_address.dart';
import 'package:murabbi_mobile/domain/value_objects/password.dart';

/// Use case d'inscription. Valide email + password via VOs et délègue au
/// repository. Le pseudo n'est PAS demandé à l'inscription (Q-18) : il est
/// auto-généré côté data layer et l'utilisateur le change à SETUP-01.
class SignUpUseCase {
  final AuthRepository _repository;
  const SignUpUseCase(this._repository);

  Future<User> call({required String email, required String password}) {
    final validatedEmail = EmailAddress(email);
    final validatedPassword = Password(password);
    return _repository.signUp(
      email: validatedEmail.value,
      password: validatedPassword.value,
    );
  }
}
