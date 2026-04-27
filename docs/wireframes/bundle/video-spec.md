# Murabbi — Spec sheet vidéo

## Mapping vidéo ↔ écran

| Vidéo | Écran | Type | Overlay | Texte |
|---|---|---|---|---|
| 01.mp4 (fenêtre lumière) | HM-01 carte Niyyah | Fond carte 130px | overlay-light 85% | Sombre `#1C1A16` |
| 01.mp4 | NIYYAH-EDIT | Bandeau 100px | overlay-dark gradient | Clair `#FDFBF8` |
| 02.mp4 (sable doré) | OB-01 Splash | Plein écran | aucun (logo seul) | Logo ivoire |
| 03.mp4 (dunes sunset) | OB-04 | Fond plein écran | overlay-light 75% | Sombre |
| 04.mp4 (sable+ciel) | OB-03 | Fond plein écran | overlay-light 80% | Sombre |
| 04.mp4 | CO-01 « Clarté mentale » | Thumbnail 60×60 | aucun | aucun |
| 06.mp4 (mosquée) | OB-02 | Fond plein écran | overlay-light 78% | Sombre |
| 06.mp4 | CO-01 « Matin du musulman » | Thumbnail 60×60 | aucun | aucun |
| 07.mp4 (mosquée large) | SL-DETAIL | Bandeau 200px | overlay-dark gradient | Clair |
| 08.mp4 (qamis lumière) | LEVEL-UP | Plein écran | overlay-dark 70% | Clair |
| 09.mp4 (silhouette) | SL-01 header | Bandeau 130px | overlay-dark gradient | Clair |
| 10.mp4 (sentier 1) | CO-01 « Santé essentielle » | Thumbnail 60×60 | aucun | aucun |
| 11.mp4 (sentier 2) | CO-01 « Routine du soir » | Thumbnail 60×60 | aucun | aucun |

## Code HTML appliqué

```html
<video autoplay muted loop playsinline poster="media/<NN>_fallback.png">
  <source src="media/<NN>.mp4" type="video/mp4">
</video>
```

## Fallbacks PNG

Frame 1 extraite par canvas, sauvegardée sous `media/<NN>_fallback.png`. Mêmes proportions que la vidéo source (1024×576 ou 1280×720 selon la source).

## Comportement

- `autoplay muted loop playsinline` — lecture silencieuse en boucle dès l'apparition.
- `object-fit: cover` sur tous les conteneurs vidéo.
- Couche overlay (z-index: 2) toujours présente quand du texte est superposé. Voir RÈGLE 0.3.
- `poster` sert de fallback avant lecture et en cas d'absence de support.

## Note v05

La séquence d'origine prévoyait `05.mp4` (ondulations) sur OB-03 et CO-01 « Clarté mentale ». Le fichier n'étant pas fourni dans l'upload, ces deux usages sont assurés par `04.mp4` (sable+ciel), qui partage le même registre lumineux.
