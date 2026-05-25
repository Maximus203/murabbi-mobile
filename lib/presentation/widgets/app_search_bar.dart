import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Barre de recherche Murabbi — composant DS réutilisable (issue #94).
///
/// Conçu comme un composant **générique** : il ne connaît rien du domaine.
/// Il est branché sur HA-01 et SA-01 en V1, et reste réutilisable tel quel
/// pour les écrans CO-01 (Collections) et LB-01 (Classement) de la Phase 5
/// (issue #6) — il suffit de lui passer un `placeholder` et un `onChanged`.
///
/// DS : fond [AppColors.bgInput], radius `button`, [LucideIcons.search] à
/// gauche, [LucideIcons.x] (clear) à droite quand la query est non vide.
///
/// Gestion du controller : si [controller] est fourni, l'appelant en garde la
/// propriété (et le dispose) ; sinon le widget en crée un en interne et le
/// dispose lui-même.
class AppSearchBar extends StatefulWidget {
  /// Texte d'invite affiché quand le champ est vide.
  final String placeholder;

  /// Callback déclenché à chaque modification du texte (saisie ou clear).
  final ValueChanged<String> onChanged;

  /// Callback optionnel déclenché spécifiquement au tap sur le bouton clear.
  final VoidCallback? onClear;

  /// Controller optionnel — si `null`, un controller interne est créé.
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    required this.placeholder,
    required this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Rebuild pour afficher/masquer l'icône clear selon la query.
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s3),
            child: Icon(
              lu(LucideIcons.search),
              size: AppIconSize.sm,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s2,
                vertical: AppSpacing.s3,
              ),
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                style: AppTypography.body,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.placeholder,
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          if (hasQuery)
            IconButton(
              splashRadius: 16,
              tooltip: 'Effacer la recherche',
              onPressed: _clear,
              icon: Icon(
                lu(LucideIcons.x),
                size: AppIconSize.sm,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
