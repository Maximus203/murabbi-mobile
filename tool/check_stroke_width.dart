// ignore_for_file: avoid_print
//
// `avoid_literal_stroke_width` — garde-fou CI (cf. ADR-017, issue #32).
//
// Interdit tout `strokeWidth: <nombre littéral>` dans `lib/`. Les épaisseurs
// de trait doivent passer par les tokens sémantiques `AppBorderWidth`
// (`thin` 0.5 / `focusRing` 1.5 / `indicatorStroke` 2.0) — cf.
// `docs/architecture/design-tokens.md`.
//
// Périmètre :
//  - Scanne uniquement `lib/`. `test/` est toléré (golden tests, comparaisons
//    numériques) — issue #32.
//  - Détecte les *call-sites* : `strokeWidth: 2`, `strokeWidth: 1.5`, etc.
//  - Ignore les *déclarations* de champ/paramètre des widgets custom
//    (ex. `AppProgressRing`) : `final double strokeWidth;`,
//    `this.strokeWidth = 6,`, `required this.strokeWidth`. La valeur
//    hardcodée serait côté appelant, pas côté déclaration.
//  - Ignore la forme conforme `strokeWidth: AppBorderWidth.xxx`.
//
// Usage :
//   dart run tool/check_stroke_width.dart
//
// Exit code 0 si propre, 1 si au moins un littéral est trouvé.
// Branché en CI avant `flutter analyze` (cf. ADR-017 §Conséquences).

import 'dart:io';

/// Tokens publiés par `AppBorderWidth` avec leur valeur — sert à suggérer
/// le remplacement le plus proche du littéral fautif.
const Map<String, double> _tokens = <String, double>{
  'AppBorderWidth.thin': 0.5,
  'AppBorderWidth.focusRing': 1.5,
  'AppBorderWidth.indicatorStroke': 2.0,
};

/// `strokeWidth:` suivi d'un nombre littéral (int ou double, signe optionnel).
/// Le `:` distingue un argument nommé d'une déclaration (`strokeWidth;`,
/// `strokeWidth =`). On exclut donc d'office les déclarations de champ.
final RegExp _literalStroke = RegExp(r'strokeWidth:\s*(-?\d+(?:\.\d+)?)\b');

/// Suggère le token `AppBorderWidth` dont la valeur est la plus proche.
String _suggestToken(double value) {
  var best = _tokens.keys.first;
  var bestDelta = double.infinity;
  for (final entry in _tokens.entries) {
    final delta = (entry.value - value).abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      best = entry.key;
    }
  }
  return best;
}

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln(
      'check_stroke_width: dossier `lib/` introuvable — '
      'lance ce script depuis la racine du repo.',
    );
    exit(2);
  }

  final violations = <String>[];

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _literalStroke.firstMatch(line);
      if (match == null) continue;

      final value = double.parse(match.group(1)!);
      final suggestion = _suggestToken(value);
      final normalizedPath = file.path.replaceAll(r'\', '/');
      violations.add(
        '$normalizedPath:${i + 1}\n'
        '  ${line.trim()}\n'
        '  ❌ `strokeWidth` littéral interdit dans lib/ (issue #32).\n'
        '  → Utilise le token : strokeWidth: $suggestion',
      );
    }
  }

  if (violations.isEmpty) {
    print('check_stroke_width: OK — aucun strokeWidth littéral dans lib/.');
    exit(0);
  }

  stderr.writeln(
    'check_stroke_width: ${violations.length} violation(s) détectée(s) — '
    'règle `avoid_literal_stroke_width` (ADR-017).\n',
  );
  for (final v in violations) {
    stderr.writeln(v);
    stderr.writeln('');
  }
  exit(1);
}
