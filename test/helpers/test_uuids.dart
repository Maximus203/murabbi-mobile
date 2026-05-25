// Constantes UUID de test — format PostgreSQL uuid valide.
// À importer dans les fichiers de test à la place des pseudo-IDs ad-hoc.
// Schéma de nommage : 1 préfixe répété par entité + ordinal sur les 12 derniers chiffres.
// ── Utilisateurs ──────────────────────────────────────────────────────────────
/// Utilisateur principal (remplace 'user-1', 'u-1', 'uid-1', 'user-001', 'user-uuid-001')
const kUserIdAlpha = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

/// Utilisateur secondaire (remplace 'user-uuid-002', 'user-2')
const kUserIdBeta = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaab';

// ── Catégories ────────────────────────────────────────────────────────────────
/// Catégorie Religion (remplace 'cat-religion', 'cat-uuid-001', 'cat-1')
const kCategoryIdReligion = 'cccccccc-cccc-cccc-cccc-cccccccccc01';

/// Catégorie Sport (remplace 'cat-sport')
const kCategoryIdSport = 'cccccccc-cccc-cccc-cccc-cccccccccc02';

/// Catégorie Santé
const kCategoryIdSante = 'cccccccc-cccc-cccc-cccc-cccccccccc03';

/// Catégorie Mental
const kCategoryIdMental = 'cccccccc-cccc-cccc-cccc-cccccccccc04';

/// Catégorie Social
const kCategoryIdSocial = 'cccccccc-cccc-cccc-cccc-cccccccccc05';

/// Catégorie générique (remplace 'cat-1' dans les tests non catégorie-spécifiques)
const kCategoryIdAlpha = 'cccccccc-cccc-cccc-cccc-cccccccccc06';

// ── Habitudes ─────────────────────────────────────────────────────────────────
/// Habitude principale (remplace 'habit-1', 'h-1', 'habit-uuid-001', 'habit-001', 'h-sub', 'h-combo')
const kHabitIdAlpha = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01';

/// Habitude secondaire (remplace 'h-2', 'habit-2')
const kHabitIdBeta = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb02';

/// Habitude tertiaire (remplace 'h-3', 'habit-3')
const kHabitIdGamma = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03';

// ── Logs d'habitudes ──────────────────────────────────────────────────────────
/// Log principal (remplace 'habit-log-1', 'log-1')
const kHabitLogIdAlpha = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01';

// ── Collections ───────────────────────────────────────────────────────────────
/// Collection principale (remplace 'coll-uuid-001', 'c-1')
const kCollectionIdAlpha = 'dddddddd-dddd-dddd-dddd-dddddddddd01';

/// Collection secondaire (remplace 'c-2', 'c-new')
const kCollectionIdBeta = 'dddddddd-dddd-dddd-dddd-dddddddddd02';

// ── Sous-tâches (habit_subtasks) ──────────────────────────────────────────────
/// Sous-tâche principale (remplace 's-1', 'subtask-uuid-001')
const kSubtaskIdAlpha = 'ffffffff-ffff-ffff-ffff-ffffffffffff';

// ── User habits ───────────────────────────────────────────────────────────────
/// Activation d'habitude principale (remplace 'uh-1', 'user-habit-1')
const kUserHabitIdAlpha = 'e0e0e0e0-e0e0-e0e0-e0e0-e0e0e0e0e001';

// ── Niyyah suggestions ────────────────────────────────────────────────────────
/// Suggestion d'intention principale (fallback système)
const kNiyyahSuggestionIdAlpha = '11111111-1111-1111-1111-111111111101';
