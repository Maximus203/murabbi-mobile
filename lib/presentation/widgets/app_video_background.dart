import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Lecteur vidéo en boucle, muet, en couverture (objectFit: cover).
/// Usage : fond d'écran ou bandeau décoratif.
///
/// [assetPath] : chemin asset déclaré dans pubspec.yaml
///   (ex : 'assets/media/02.mp4').
/// [height] : hauteur fixe. Si null, prend toute la hauteur disponible.
/// [borderRadius] : pour les bandeaux cards.
/// [overlay] : widget superposé au-dessus de la vidéo (textes, dégradés…).
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
            // Fond sombre anthracite-brun — visible pendant le chargement et
            // utilisé comme fond de secours si la vidéo n'est pas disponible.
            const ColoredBox(color: Color(0xFF1C1A16)),
            // Vidéo en couverture, affichée uniquement après initialisation.
            if (_initialized)
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
