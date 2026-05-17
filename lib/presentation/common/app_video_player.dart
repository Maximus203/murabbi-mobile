import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Widget vidéo unifié supportant deux sources — ADR-017.
///
/// - [assetPath] : vidéo bundlée dans l'APK (ex. [AppMedia.splashVideo]).
/// - [url] : URL publique d'une vidéo Supabase Storage
///   (ex. depuis [VideoService.getRemoteVideoUrl]).
///
/// Exactement **un** des deux paramètres doit être fourni.
///
/// Comportements :
/// - **Loading** : fond sombre anthracite (`Color(0xFF1C1A16)`) pendant
///   l'initialisation du lecteur.
/// - **Erreur** : fallback identique au loading (jamais de crash). L'erreur
///   est loggée dans la console debug uniquement.
/// - [autoPlay] : démarre la lecture automatiquement après init (défaut : `true`).
/// - [looping] : lecture en boucle (défaut : `true`).
/// - [fit] : mode d'ajustement de la vidéo (défaut : [BoxFit.cover]).
/// - [overlay] : widget superposé au-dessus de la vidéo (textes, dégradés…).
/// - [borderRadius] : arrondi du clip (défaut : [BorderRadius.zero]).
/// - [height] : hauteur fixe ; si null, prend toute la hauteur disponible.
class AppVideoPlayer extends StatefulWidget {
  /// Chemin asset déclaré dans pubspec.yaml — ex. 'assets/videos/02_murabbi.mp4'.
  /// Mutuellement exclusif avec [url].
  final String? assetPath;

  /// URL publique d'une vidéo remote — ex. depuis Supabase Storage.
  /// Mutuellement exclusif avec [assetPath].
  final String? url;

  /// Mode d'ajustement de la vidéo dans son conteneur.
  final BoxFit fit;

  /// Démarre la lecture automatiquement après initialisation.
  final bool autoPlay;

  /// Lecture en boucle.
  final bool looping;

  /// Widget superposé au-dessus de la vidéo.
  final Widget? overlay;

  /// Arrondi du clip.
  final BorderRadius borderRadius;

  /// Hauteur fixe. Si null, prend toute la hauteur disponible.
  final double? height;

  /// Crée un [AppVideoPlayer].
  ///
  /// Exactly one of [assetPath] or [url] must be provided.
  const AppVideoPlayer({
    super.key,
    this.assetPath,
    this.url,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
    this.looping = true,
    this.overlay,
    this.borderRadius = BorderRadius.zero,
    this.height,
  }) : assert(
          (assetPath != null) != (url != null),
          'Exactly one of assetPath or url must be provided.',
        );

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final VideoPlayerController ctrl;

    if (widget.assetPath != null) {
      ctrl = VideoPlayerController.asset(widget.assetPath!);
    } else {
      ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url!));
    }

    _controller = ctrl;

    try {
      await ctrl.initialize();
      if (!mounted) return;
      ctrl.setVolume(0);
      if (widget.looping) await ctrl.setLooping(true);
      if (widget.autoPlay) await ctrl.play();
      setState(() => _initialized = true);
    } catch (_) {
      // Fallback silencieux — le fond sombre reste affiché.
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
            // Vidéo en couverture, affichée uniquement après initialisation
            // sans erreur.
            if (_initialized && !_hasError && _controller != null)
              FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
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
