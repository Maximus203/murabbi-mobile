import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

/// Catégorie regroupant des habitudes (Sport, Spirituel, …).
///
/// La pondération en points est portée par chaque [Habit] via `HabitPoints`,
/// pas par la catégorie (cf. Q-12 verrouillée — `product_decisions_v1.md`).
/// Voir `docs/adr/ADR-009-category-points-removal.md`.
class Category extends Equatable {
  final CategoryId id;
  final NonEmptyString name;

  /// Accent color of the category, used by [BuildCollectionCoverUseCase] for
  /// the fallback gradient and by the design system for category badges.
  ///
  /// Typed as [HexColor] so a stray `"red"` / `""` / `"3A6B8C"` is rejected
  /// at construction time rather than later in the rendering pipeline
  /// (cf. issue #12 — Copilot fix #1 on PR #11).
  final HexColor color;

  final String icon;
  final bool isSystem;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.isSystem,
  });

  @override
  List<Object?> get props => [id, name, color, icon, isSystem];
}
