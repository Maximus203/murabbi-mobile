# ERD — Murabbi Mobile (tables Supabase attendues)

**Version** : Phase 0
**Date** : 2026-04-27

```mermaid
erDiagram
    users {
        uuid id PK
        text display_name
        text email
        text level
        timestamp created_at
        timestamp updated_at
    }

    prayer_days {
        uuid id PK
        uuid user_id FK
        date date
        text fajr
        text dhuhr
        text asr
        text maghrib
        text isha
        timestamp created_at
        timestamp updated_at
    }

    categories {
        uuid id PK
        uuid user_id FK
        text name
        text color
        text icon
        int points
        boolean is_system
        timestamp created_at
    }

    habits {
        uuid id PK
        uuid user_id FK
        uuid category_id FK
        text name
        int frequency
        text time_range
        int[] active_days
        int points
        boolean is_system
        timestamp created_at
        timestamp updated_at
    }

    habit_logs {
        uuid id PK
        uuid habit_id FK
        uuid user_id FK
        date date
        text status
        timestamp created_at
    }

    collections {
        uuid id PK
        uuid user_id FK
        text name
        text description
        boolean is_system
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    collection_habits {
        uuid collection_id FK
        uuid habit_id FK
    }

    user_scores {
        uuid id PK
        uuid user_id FK
        int total_points
        int weekly_points
        text current_level
        int weekly_rank
        timestamp updated_at
    }

    users ||--o{ prayer_days : "has"
    users ||--o{ categories : "owns"
    users ||--o{ habits : "owns"
    users ||--o{ habit_logs : "has"
    users ||--o{ collections : "owns"
    users ||--|| user_scores : "has"
    categories ||--o{ habits : "classifies"
    habits ||--o{ habit_logs : "has"
    collections ||--o{ collection_habits : "contains"
    habits ||--o{ collection_habits : "belongs to"
```

## Notes

- Toutes les tables ont RLS activé (règle S-2)
- `categories` et `collections` : les lignes `is_system = true` sont créées par
  les admins (via `murabbi-admin`) — les utilisateurs ne peuvent pas les modifier
- `prayer_days` : contrainte unique sur `(user_id, date)`
- `habit_logs` : contrainte unique sur `(habit_id, user_id, date)`
- `user_scores` : calculé via trigger ou Edge Function, jamais écrit directement par le client
- Les colonnes `updated_at` sont gérées par trigger automatique
