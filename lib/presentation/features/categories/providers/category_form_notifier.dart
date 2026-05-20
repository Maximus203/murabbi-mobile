import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

/// État du formulaire HB-04 (création/édition catégorie).
///
/// Immutable — chaque champ modifié produit un nouvel état via [copyWith].
class CategoryFormState extends Equatable {
  /// Nom saisi (brut, non trimmé).
  final String name;

  /// Couleur sélectionnée dans [ColorPickerGrid] — toujours un token DS.
  final Color color;

  /// Nom d'icône Lucide sélectionné dans [IconSelectorGrid].
  final String icon;

  const CategoryFormState({
    required this.name,
    required this.color,
    required this.icon,
  });

  /// État initial pour une création — premier token de la palette + icône par défaut.
  factory CategoryFormState.empty() => CategoryFormState(
    name: '',
    color: AppColors.categoryPalette.first,
    icon: kCategoryIconNames.first,
  );

  /// Nom valide : non vide après trim et ≤ 32 caractères (HB-04 spec).
  bool get isNameValid {
    final trimmed = name.trim();
    return trimmed.isNotEmpty && trimmed.length <= 32;
  }

  /// Le formulaire peut être enregistré uniquement si le nom est valide.
  bool get canSubmit => isNameValid;

  CategoryFormState copyWith({
    String? name,
    Color? color,
    String? icon,
  }) {
    return CategoryFormState(
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  @override
  List<Object?> get props => [name, color, icon];
}

/// Les 10 icônes Lucide proposées dans [IconSelectorGrid] (HB-04).
///
/// Noms canoniques kebab-case — alignés sur la convention `Category.icon`
/// utilisée par le seed (`moon-star`, `dumbbell`, …).
const List<String> kCategoryIconNames = [
  'moon-star',
  'dumbbell',
  'heart-pulse',
  'brain',
  'users',
  'book-open',
  'briefcase',
  'sprout',
  'palette',
  'star',
];

/// Notifier du formulaire HB-04.
///
/// La catégorie initiale est fournie via l'argument de la `family` ([arg]) :
/// `null` → mode création, non-null → mode édition (pré-remplissage).
class CategoryFormNotifier
    extends FamilyNotifier<CategoryFormState, Category?> {
  @override
  CategoryFormState build(Category? arg) {
    final initial = arg;
    if (initial == null) return CategoryFormState.empty();
    return CategoryFormState(
      name: initial.name.value,
      color: _hexToColor(initial.color.value),
      icon: initial.icon,
    );
  }

  void setName(String value) => state = state.copyWith(name: value);

  void setColor(Color value) => state = state.copyWith(color: value);

  void setIcon(String value) => state = state.copyWith(icon: value);
}

/// Famille de providers du formulaire HB-04, paramétrée par la catégorie
/// initiale (`null` → création, non-null → édition).
final categoryFormNotifierProvider =
    NotifierProvider.family<CategoryFormNotifier, CategoryFormState, Category?>(
      CategoryFormNotifier.new,
    );

/// Convertit un token `#RRGGBB` (HexColor) en [Color].
Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
