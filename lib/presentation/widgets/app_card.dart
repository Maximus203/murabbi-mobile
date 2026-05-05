import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';

/// Carte Murabbi — surface élevée, radius 16, bordure 0.5px, **ZÉRO ombre**
/// portée (P-5). DS sheet § Cartes.
///
/// Padding interne par défaut : 20px (DS spec). Override via [padding].
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s5),
    this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    final card = Container(
      decoration: BoxDecoration(
        color: background ?? AppColors.bgSurface,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppBorderWidth.hairline,
        ),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}
