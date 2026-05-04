import 'package:equatable/equatable.dart';

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

/// Cover synthesized from the collection's category color + the first letter
/// of its name. Used when no image was uploaded yet (most collections at
/// install time) and as a graceful degradation if the URL fails to load.
final class CollectionCoverFallback extends CollectionCover {
  /// Category accent color in `#RRGGBB` format. Drives the gradient on screen.
  final String categoryColorHex;

  /// Single uppercase character — the first letter of the collection name.
  /// Arabic / non-cased glyphs pass through unchanged (`toUpperCase` is a no-op).
  final String initial;

  CollectionCoverFallback({
    required this.categoryColorHex,
    required String initial,
  }) : initial = initial.toUpperCase() {
    if (this.initial.isEmpty) {
      throw ArgumentError.value(initial, 'initial', 'initial cannot be empty');
    }
    if (this.initial.length != 1) {
      throw ArgumentError.value(
        initial,
        'initial',
        'initial must be a single character',
      );
    }
    if (!_isHexColor(categoryColorHex)) {
      throw ArgumentError.value(
        categoryColorHex,
        'categoryColorHex',
        'expected #RRGGBB',
      );
    }
  }

  static bool _isHexColor(String s) {
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(s);
  }

  @override
  List<Object?> get props => [categoryColorHex, initial];
}
