import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// D-28 — Squelette de chargement Murabbi (ligne animée).
///
/// Affiche un rectangle grisé animé (shimmer) pendant le chargement des
/// données. Remplace le spinner seul pour les listes (SA-01, HA-01).
///
/// Le shimmer est implémenté avec [TweenAnimationBuilder] + [LinearGradient]
/// en translation continue — aucune dépendance externe requise (flutter_animate
/// absent du pubspec au moment de D-28).
///
/// Accessibilité : le widget est enveloppé dans [ExcludeSemantics] — un
/// squelette de chargement n'a pas de sens pour les lecteurs d'écran.
/// Le composant parent doit fournir un label [Semantics] "Chargement…" sur
/// le bloc entier.
class AppSkeletonLine extends StatelessWidget {
  /// Largeur du rectangle — `double.infinity` pour occuper tout l'espace.
  final double width;

  /// Hauteur du rectangle en dp.
  final double height;

  /// Rayon des coins (par défaut : chip).
  final double borderRadius;

  const AppSkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = AppRadius.chip,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: _ShimmerBox(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// D-28 — Squelette de chargement Murabbi (card avec plusieurs lignes).
///
/// Agrège 2-3 [AppSkeletonLine] dans un [AppCard] pour simuler le rendu d'une
/// ligne de liste (titre + sous-titre + badge). Utilisé dans SA-01 (liste
/// prières) et HA-01 (liste habitudes) à la place du seul
/// [CircularProgressIndicator].
///
/// Nombre de lignes contrôlé par [lineCount] (2 ou 3 typiquement).
class AppSkeletonCard extends StatelessWidget {
  /// Nombre de lignes simulées dans la card (2 ou 3).
  final int lineCount;

  const AppSkeletonCard({super.key, this.lineCount = 2});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement…',
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne principale (titre) — 60% de la largeur.
            const AppSkeletonLine(height: 16),
            const SizedBox(height: AppSpacing.s2),
            // Ligne secondaire (sous-titre) — plus courte.
            const FractionallySizedBox(
              widthFactor: 0.6,
              child: AppSkeletonLine(height: 12),
            ),
            if (lineCount >= 3) ...[
              const SizedBox(height: AppSpacing.s2),
              // Ligne tertiaire (badge / méta) — très courte.
              const FractionallySizedBox(
                widthFactor: 0.25,
                child: AppSkeletonLine(height: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Implémentation interne du shimmer
// ---------------------------------------------------------------------------

/// Rectangle animé shimmer — fond dégradé qui translate de gauche à droite.
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final shimmerX = _anim.value;
        return Container(
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(shimmerX - 1, 0),
              end: Alignment(shimmerX, 0),
              colors: const [
                AppColors.bgInput,
                AppColors.bgShimmerHighlight,
                AppColors.bgInput,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
