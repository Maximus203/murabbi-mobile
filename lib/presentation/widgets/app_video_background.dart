import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:video_player/video_player.dart';

/// Lecteur vidéo en boucle, muet, en couverture (objectFit: cover).
/// Usage : fond d'écran ou bandeau décoratif.
///
/// [assetPath] : chemin asset déclaré dans pubspec.yaml
///   (ex : 'assets/media/02.mp4').
/// [height] : hauteur fixe. Si null, prend toute la hauteur disponible.
/// [borderRadius] : pour les bandeaux cards.
/// [overlay] : widget superposé au-dessus de la vidéo (textes, dégradés…).
///
/// Tant que la vidéo n'est pas initialisée — ou si l'asset est absent /
/// échoue à charger — un placeholder thémé clair (issue #115) est affiché à
/// la place, jamais un bloc noir opaque.
class AppVideoBackground extends StatefulWidget {
  final String assetPath;
  final double? height;
  final BorderRadius borderRadius;
  final Widget? overlay;

  const AppVideoBackground({
    super.key,
    required this.assetPath,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.overlay,
  });

  @override
  State<AppVideoBackground> createState() => _AppVideoBackgroundState();
}

class _AppVideoBackgroundState extends State<AppVideoBackground> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  /// `true` si l'asset vidéo est absent ou n'a pas pu être décodé. Dans ce
  /// cas le placeholder thémé reste affiché en permanence (#115).
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (mounted) {
          _controller.setLooping(true);
          _controller.setVolume(0);
          _controller.play();
          setState(() => _initialized = true);
        }
      }).catchError((Object _) {
        // Asset manquant ou format non supporté : on bascule sur le
        // placeholder thémé plutôt que de laisser un bloc opaque.
        if (mounted) {
          setState(() => _failed = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder thémé clair — visible pendant le chargement et
            // utilisé comme fond de secours si la vidéo n'est pas disponible.
            // #115 : jamais de bloc noir opaque.
            const _VideoPlaceholder(),
            // Vidéo en couverture, affichée uniquement après initialisation.
            if (_initialized && !_failed)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            // L'overlay est toujours rendu (pendant et après le chargement).
            if (widget.overlay != null) widget.overlay!,
          ],
        ),
      ),
    );
  }
}

/// Placeholder décoratif thémé affiché à la place de la vidéo tant qu'elle
/// n'est pas chargée — ou définitivement si l'asset est absent (#115).
///
/// Dégradé doux dans la palette ocre/sable de l'app + icône discrète, pour
/// rester cohérent avec le design system même hors-ligne.
class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgInput,
            AppColors.accent.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.image,
          size: 32,
          color: AppColors.accent.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
