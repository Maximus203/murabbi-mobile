import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Mapping nom d'icône Lucide (kebab-case) → [IconData].
///
/// Centralise la résolution utilisée par `CategoryTile`, `IconSelectorGrid`
/// et la preview HB-04. Les noms kebab-case sont la convention de
/// `Category.icon` (cf. seed `InMemoryCategoryRepository`).
const Map<String, IconData> _categoryIconMap = {
  'moon-star': LucideIcons.moonStar,
  'dumbbell': LucideIcons.dumbbell,
  'heart-pulse': LucideIcons.heartPulse,
  'brain': LucideIcons.brain,
  'users': LucideIcons.users,
  'book-open': LucideIcons.bookOpen,
  'briefcase': LucideIcons.briefcase,
  'sprout': LucideIcons.sprout,
  'palette': LucideIcons.palette,
  'star': LucideIcons.star,
};

/// Résout un nom d'icône catégorie en [IconData].
///
/// Retombe sur `LucideIcons.tag` si le nom est inconnu — garantit qu'une
/// catégorie persistée avec une icône retirée du catalogue reste affichable.
IconData categoryIconData(String name) =>
    _categoryIconMap[name] ?? LucideIcons.tag;
