import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
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
/// - **Loading / Erreur / Web** : un fallback thémé chaud (dégradé sable/ocre)
///   est affiché — jamais de bloc noir opaque (issues #137 / #130). L'erreur
///   est avalée silencieusement (pas de crash).
/// - **Web** (`kIsWeb`) : le contrôleur `video_player` n'est **jamais**
///   initialisé — sur Flutter web il gèle le thread principal du navigateur
///   (issue #130). Le fallback statique reste affiché.
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
    // #130 : sur Flutter web, `video_player` gèle le renderer du navigateur.
    // On n'initialise pas le contrôleur — le fallback thémé reste affiché.
    if (!kIsWeb) {
      _initController();
    }
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
      // Fallback silencieux — le placeholder thémé reste affiché.
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
            // Fallback thémé chaud (dégradé sable/ocre) — visible pendant le
            // chargement, sur web, et si la vidéo échoue. #137 : jamais de
            // bloc noir opaque, cohérent avec la palette de l'app.
            const _VideoFallback(),
            // Vidéo en couverture, affichée uniquement après initialisation
            // sans erreur (jamais sur web).
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

/// Fond de secours thémé affiché à la place de la vidéo tant qu'elle n'est
/// pas chargée — ou définitivement sur web / en cas d'échec (#137 / #130).
///
/// Dégradé chaud dans la palette ocre/sable de l'app pour rester cohérent
/// avec le design system, jamais un bloc noir.
class _VideoFallback extends StatelessWidget {
  const _VideoFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentHover],
        ),
      ),
    );
  }
}
