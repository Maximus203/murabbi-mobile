import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Mappe un slug d'icône de catégorie (stocké en base, ex. `moon-star`) vers
/// un [IconData] Lucide concret.
///
/// Issue #125 : la liste HA-01 affichait la même icône `target` pour toutes
/// les habitudes. On dérive désormais l'icône de la catégorie de l'habitude.
///
/// Le slug est volontairement faible (chaîne libre côté base) : tout slug
/// inconnu ou vide retombe sur [LucideIcons.target] — l'ancien défaut, qui
/// reste un fallback neutre acceptable.
IconData categoryIconFromSlug(String? slug) {
  switch (slug) {
    case 'moon-star':
      return LucideIcons.moonStar;
    case 'dumbbell':
      return LucideIcons.dumbbell;
    case 'heart-pulse':
      return LucideIcons.heartPulse;
    case 'brain':
      return LucideIcons.brain;
    case 'users':
      return LucideIcons.users;
    case 'book':
    case 'book-open':
      return LucideIcons.bookOpen;
    case 'sun':
      return LucideIcons.sun;
    case 'sparkles':
      return LucideIcons.sparkles;
    default:
      return LucideIcons.target;
  }
}
