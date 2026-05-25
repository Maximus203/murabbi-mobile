# ADR-005 — Stratégie offline / cache

**Date** : 2026-04-27
**Auteur** : Agent mobile (Phase 0)
**Statut** : Accepté (pour v1) — à réévaluer en v2

## Contexte

Murabbi est utilisé quotidiennement, souvent dans des conditions réseau dégradées
(transport, zones peu couvertes). La question est : quel niveau d'offline supporter en v1 ?

## Contraintes

- Supabase Realtime (websocket) n'est pas disponible offline
- Les prières ont une composante temps-réel (l'heure de la prière)
- Le tracker Salat est l'écran le plus critique — il doit fonctionner offline

## Options évaluées

### A — Offline-first avec Drift/Isar (SQLite local)
Base locale complète, sync en background. Maximum de résilience, mais complexité élevée
et durée de développement incompatible avec la Phase 0.

### B — Cache en mémoire (Riverpod keepAlive)
Pas de persistance entre sessions. Perte des données si l'app est tuée.

### C — Cache local léger + Supabase realtime (retenu pour v1)
- `flutter_secure_storage` pour les données de session
- `shared_preferences` pour les préférences utilisateur non sensibles (thème, plages horaires)
- Cache Riverpod `keepAlive: true` pour les listes rarement mutées (catégories, collections système)
- Données critiques (logs Salat, logs habitudes) : write-through vers Supabase + queue locale
  si pas de réseau (implémentation en Phase 4)

## Décision

**Option C retenue pour v1.** La stratégie offline-first complète (Drift) est reportée en v2.

## Conséquences

- Phase 0-3 : pas de cache local — `flutter_secure_storage` pour les tokens uniquement
- Phase 4 : implémentation d'une queue locale pour les mutations Salat/habits offline
- v2 : évaluation Drift si les retours terrain montrent un besoin fort d'offline-first
- L'architecture `datasource` (ADR-004) permet d'introduire un datasource local sans
  modifier les interfaces de repository ni la couche domaine
