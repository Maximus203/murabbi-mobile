import 'package:equatable/equatable.dart';

/// A 6-digit hexadecimal color in the canonical `#RRGGBB` form.
///
/// Used wherever the design system needs a typed color reference
/// ([Category.color], [CollectionCoverFallback.categoryColor], …)
/// so a stray `"red"` / `""` / `"3A6B8C"` is rejected at construction
/// time rather than blowing up downstream when a UI tries to parse it.
///
/// Casing is preserved (we don't normalise to upper- or lower-case): the
/// design tokens in `data_extensions.md` are written `#3A6B8C` and we want
/// equality to round-trip with the seed values without surprises.
class HexColor extends Equatable {
  static final RegExp _pattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  final String value;

  HexColor(String raw) : value = raw {
    if (!_pattern.hasMatch(raw)) {
      throw ArgumentError.value(
        raw,
        'value',
        'HexColor must match #RRGGBB (got "$raw")',
      );
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
