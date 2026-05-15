import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Symbole Murabbi seul (sans texte).
///
/// [size] : dimension carrée du symbole (défaut : 48).
/// [color] : `null` = utilise les couleurs SVG source ;
///           non-`null` = applique un colorFilter monochrome.
class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({super.key, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_symbol.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

/// Lockup vertical : symbole + wordmark « Murabbi » en SVG.
///
/// [width] : largeur totale du lockup (hauteur auto-proportionnelle, défaut : 120).
/// [color] : `null` = utilise les couleurs SVG source ;
///           non-`null` = applique un colorFilter monochrome.
class AppWordmark extends StatelessWidget {
  final double width;
  final Color? color;

  const AppWordmark({super.key, this.width = 120, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_lockup_vertical.svg',
      width: width,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
