import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/widgets/app_chip.dart';

/// Rangée de chips de filtre à sélection unique — composant DS réutilisable
/// (issue #94).
///
/// Conçu comme un composant **générique** : il prend une simple liste de
/// libellés et un index sélectionné, sans rien connaître du domaine. Branché
/// sur HA-01 (Toutes/Actives/Inactives) et SA-01 (Toutes/À faire/Faites/
/// Manquées) en V1, il reste réutilisable tel quel pour CO-01 et LB-01 en
/// Phase 5 (issue #6).
///
/// Rendu : [Wrap] horizontal scrollable, un [AppChip] par libellé, le chip
/// d'index [selectedIndex] est marqué `selected`.
class AppFilterChips extends StatelessWidget {
  /// Libellés des filtres, dans l'ordre d'affichage.
  final List<String> labels;

  /// Index du chip actuellement sélectionné (0-based).
  final int selectedIndex;

  /// Callback déclenché au tap sur un chip, avec son index.
  final ValueChanged<int> onChanged;

  const AppFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s2),
            AppChip(
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}
