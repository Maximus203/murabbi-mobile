import 'package:flutter/material.dart';
import 'package:murabbi_mobile/core/errors/failure_message.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Widget partagé qui rend un [Failure] (ou tout `Object` d'erreur) avec
/// son libellé FR canonique issu de [FailureMessage] (#201, M9).
///
/// Remplace les `Text(e.toString())` éparpillés dans les écrans : un seul
/// point de vérité pour le mapping erreur → message, et un style aligné
/// design system (couleur [AppColors.danger], typographie [AppTypography.body]).
class AppErrorText extends StatelessWidget {
  /// L'erreur à afficher. Typiquement une instance d'un `Failure` sealed
  /// (`AuthFailure`, `ScoreFailure`, etc.) ; tout autre `Object` retombe
  /// sur le libellé générique de [FailureMessage].
  final Object failure;

  /// Alignement horizontal du texte. Par défaut centré (cas usuel d'un
  /// `AsyncValue.error` plein écran).
  final TextAlign textAlign;

  const AppErrorText(
    this.failure, {
    super.key,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      FailureMessage.from(failure),
      textAlign: textAlign,
      style: AppTypography.body.copyWith(color: AppColors.danger),
    );
  }
}
