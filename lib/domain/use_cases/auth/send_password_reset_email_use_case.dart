import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/email_address.dart';

class SendPasswordResetEmailUseCase {
  final AuthRepository _repository;
  const SendPasswordResetEmailUseCase(this._repository);

  Future<void> call({required String email}) {
    final validatedEmail = EmailAddress(email);
    return _repository.sendPasswordResetEmail(email: validatedEmail.value);
  }
}
