import 'package:flutter/material.dart';

/// Crée un [IconData] Lucide sans [fontPackage] pour que Flutter résolve
/// la police depuis l'app bundle (`assets/fonts/lucide.ttf`, famille `Lucide`).
///
/// À utiliser à chaque appel [Icon] qui reçoit un [LucideIcons] : le
/// `fontPackage: 'lucide_icons_flutter'` inscrit dans les constantes du package
/// oblige Flutter à chercher la police dans le namespace du package, ce que le
/// build WSL ne garantit pas. Ce wrapper lit uniquement le codePoint et
/// reconstruit un IconData dans le namespace de l'app.
IconData lu(IconData icon) => IconData(
  icon.codePoint, // ignore: non_const_argument_for_const_parameter
  fontFamily: 'Lucide',
  matchTextDirection: icon.matchTextDirection,
);
