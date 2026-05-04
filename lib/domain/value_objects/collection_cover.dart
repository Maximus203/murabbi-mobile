import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';

/// Visual cover of a collection — either a hosted image or a deterministic
/// fallback (gradient + initial), per `product_decisions_v1.md § Q-13-cover`.
///
/// Sealed type: presentation code can `switch` exhaustively without a default
/// branch. Adding a new variant here is a compile-time break in every caller —
/// that's the point.
sealed class CollectionCover extends Equatable {
  const CollectionCover();
}

/// Cover backed by a real image hosted on Supabase Storage.
///
/// `url` is non-empty after construction — empty / whitespace-only inputs
/// throw [ArgumentError] so callers can't accidentally render a broken
/// `<img src="">`. The repository layer is expected to map a NULL/empty
/// `cover_image_url` column to "no image", not to an empty `CollectionCoverImage`.
final class CollectionCoverImage extends CollectionCover {
  final String url;

  CollectionCoverImage(String raw) : url = raw.trim() {
    if (url.isEmpty) {
      throw ArgumentError.value(
        raw,
        'url',
        'CollectionCoverImage url cannot be empty',
      );
    }
  }

  @override
  List<Object?> get props => [url];
}

/// Cover synthesized from the collection's category color + the first
/// grapheme cluster of its name. Used when no image was uploaded yet
/// (most collections at install time) and as a graceful degradation if the
/// URL fails to load.
final class CollectionCoverFallback extends CollectionCover {
  /// Category accent color in `#RRGGBB` format. Drives the gradient on screen.
  /// Typed as [HexColor] so the invariant lives at the source (cf. PR #12 fix).
  final HexColor categoryColor;

  /// First user-perceived character (grapheme cluster) of the collection
  /// name. Computed via `String.characters.first` to handle emoji and
  /// combining marks correctly — never a half surrogate.
  final String initial;

  CollectionCoverFallback({
    required this.categoryColor,
    required this.initial,
  }) {
    if (initial.isEmpty) {
      throw ArgumentError.value(initial, 'initial', 'initial cannot be empty');
    }
  }

  @override
  List<Object?> get props => [categoryColor, initial];
}
