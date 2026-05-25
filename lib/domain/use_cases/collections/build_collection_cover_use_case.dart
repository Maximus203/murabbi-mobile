import 'package:characters/characters.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_cover.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';

/// Resolves a [Collection] to a [CollectionCover] suitable for display.
///
/// Source of truth: `product_decisions_v1.md § Q-13-cover`.
///
/// Decision tree:
///
/// 1. `collection.coverImageUrl` is non-null and non-empty (after trim) →
///    [CollectionCoverImage].
/// 2. Otherwise → [CollectionCoverFallback] with:
///    - `categoryColor` = `category.color` if a [Category] is provided,
///      else `#A19D93` (sandstone neutral, CDC §P-3).
///    - `initial` = first **grapheme cluster** of `collection.name.value`,
///      uppercased. Uses `String.characters.first` (not `substring(0, 1)`)
///      so emoji / Arabic / combining marks render as a single user-perceived
///      character — fix #2 of issue #12.
///
/// Pure logic: no I/O, no async, no platform dependency. The presentation
/// layer is responsible for actually rendering the gradient + initial.
class BuildCollectionCoverUseCase {
  /// CDC §P-3 fallback color when the collection's category is unknown.
  /// Mobile default for the "no category context" case (e.g. collection
  /// listing without joined category data).
  static final HexColor _sandstoneNeutral = HexColor('#A19D93');

  CollectionCover call({required Collection collection, Category? category}) {
    final url = collection.coverImageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return CollectionCoverImage(url);
    }

    final color = category?.color ?? _sandstoneNeutral;
    final name = collection.name.value;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return CollectionCoverFallback(categoryColor: color, initial: initial);
  }
}
