import 'package:flutter/material.dart';

/// Mise à l'échelle responsive — référence 390 dp (iPhone 14).
///
/// Tous les tokens [AppIconSize] et [AppComponentSize] définissent les valeurs
/// nominales à 390 dp. [AppResponsive.scale] adapte proportionnellement au
/// viewport courant, borné entre [kMinFactor] et [kMaxFactor] (±20 %).
///
/// Usage : `size: context.rs(AppIconSize.rg)`
class AppResponsive {
  AppResponsive._();

  /// Largeur du viewport de référence — iPhone 14 (390 dp logiques).
  static const double kRefWidth = 390.0;

  /// Facteur minimal (petits téléphones ≈ 312 dp → 0.8×).
  static const double kMinFactor = 0.8;

  /// Facteur maximal (grands téléphones / tablettes ≈ 468 dp+ → 1.2×).
  static const double kMaxFactor = 1.2;

  /// Retourne [base] mis à l'échelle proportionnellement à la largeur d'écran.
  ///
  /// Résultat borné dans [[base] × [kMinFactor], [base] × [kMaxFactor]].
  static double scale(BuildContext context, double base) {
    final w = MediaQuery.sizeOf(context).width;
    return base * (w / kRefWidth).clamp(kMinFactor, kMaxFactor);
  }
}

/// Extension de commodité — `context.rs(base)` au lieu de
/// `AppResponsive.scale(context, base)`.
extension AppResponsiveContext on BuildContext {
  /// Applique la mise à l'échelle responsive sur [base].
  ///
  /// Exemple : `Icon(LucideIcons.bell, size: context.rs(AppIconSize.rg))`
  double rs(double base) => AppResponsive.scale(this, base);
}
