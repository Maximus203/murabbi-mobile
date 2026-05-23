# ADR-018 — Alert System: Occurrence Model & Notification Strategy

**Date:** 2026-05-23
**Status:** Accepted
**Author:** Cherif DIOUF / AI Architect Agent
**Supersedes:** –
**Superseded by:** –
**Related ADRs:** ADR-006 (frequency model), ADR-007 (time range), ADR-008 (v1.5 extensions), ADR-013 (prayer calculation), ADR-014 (geolocation)

---

## 1. Context

Previous ADRs (ADR-006, ADR-007, ADR-008) established how habits are defined — their frequency, their time ranges, their v1.5 extensions (snooze, grace window). What remained unspecified was the **runtime model**: how a scheduled habit turns into a concrete, trackable event that a user can confirm, snooze, or miss.

The existing `habit_logs` table records user outcomes after the fact. It has no lifecycle — it cannot represent the intermediate states between "a notification was sent" and "the user responded". This gap creates several problems:

- There is no durable record of whether a notification was actually delivered.
- Snooze state cannot be persisted across app restarts.
- The `awaiting_validation` badge on the dashboard has no reliable backing data.
- Missed prayers cannot be distinguished from never-scheduled ones.
- Scoring is coupled to `users.total_points`, a mutable column that drifts from the real source of truth.

To close these gaps, the system needs a first-class **occurrence** entity: a row created at scheduling time, updated as the user interacts (or doesn't), and expired by a background job when the grace window closes. This ADR documents the full decision covering the occurrence data model, the habit type taxonomy, the grace/snooze rules, the notification strategy, the background job design, and the Flutter service/provider layer.

---

## 2. Decision

Introduce a `habit_occurrences` table as the central runtime entity for every scheduled habit execution, owned by a layered Flutter architecture (`NotificationService` → `NotificationScheduler` + `NotificationActionHandler` + `GraceWindowTracker`) backed by two Riverpod AsyncNotifiers, with local scheduling via `flutter_local_notifications` + `workmanager` and prayer-specific logic sourced from the on-device `adhan_dart` engine.

---

## 3. Detailed Design

### 3.1 Habit types taxonomy

Three `kind` values on the `habits` table drive behaviour throughout the system:

| kind | Description | `is_user_configurable` | Snooze allowed | Grace period |
|---|---|---|---|---|
| `prayer` | Fixed time from astronomical calculation (adhan) | `false` | No (obligatory prayers) | 30 min, not modifiable |
| `fixed` | User-defined time slot, recurring on selected days | Partial (grace period, active days) | Yes | 5–180 min (default 12) |
| `flexible` | Fully user-configurable | Yes, via `configurable_fields` JSONB flags | Yes | 5–180 min (default 12) |

`configurable_fields` for `flexible` habits is a JSONB object whose keys are column names and whose boolean values indicate whether the user may edit them in the UI. The backend validates mutations against this map before accepting an update.

### 3.2 Occurrence lifecycle (state machine)

```
              ┌──────────────┐
              │  scheduled   │  ← row inserted by ScheduleOccurrencesForToday
              └──────┬───────┘
                     │  notification delivered
                     ▼
              ┌──────────────┐
              │   notified   │
              └──────┬───────┘
                     │  grace window opens
                     ▼
         ┌───────────────────────┐
         │  awaiting_validation  │  ← visible in UI badge
         └───┬────────┬──────────┘
             │        │
  user taps  │        │  user taps "Snooze"
   Done /    │        │  (max 2 × per occurrence, forbidden on obligatory prayer)
   Dismiss   │        ▼
             │   ┌─────────┐
             │   │ snoozed │ ─────┐
             │   └─────────┘     │  snooze timer expires → back to awaiting_validation
             │                   ◄─┘
             ▼
     ┌────────────────────────────────────────────────────────────────┐
     │                       terminal states                         │
     │                                                                │
     │  validated   ← user confirmed within grace window            │
     │  late        ← user confirmed after grace but before midnight │
     │  missed      ← expired by job, no user interaction            │
     │  too_late    ← user confirmed after midnight local time       │
     └────────────────────────────────────────────────────────────────┘
```

Supabase columns for `habit_occurrences`:

```sql
CREATE TABLE habit_occurrences (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  habit_id           UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  scheduled_at       TIMESTAMPTZ NOT NULL,
  notified_at        TIMESTAMPTZ,
  grace_expires_at   TIMESTAMPTZ NOT NULL,    -- scheduled_at + grace_period_minutes
  status             TEXT NOT NULL DEFAULT 'scheduled'
                       CHECK (status IN (
                         'scheduled','notified','awaiting_validation',
                         'snoozed','validated','late','missed','too_late'
                       )),
  outcome            TEXT,                    -- 'done' | 'dismissed' | null
  snooze_count       SMALLINT NOT NULL DEFAULT 0 CHECK (snooze_count <= 2),
  next_snooze_at     TIMESTAMPTZ,
  validated_at       TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_habit_occurrences_user_status ON habit_occurrences(user_id, status);
CREATE INDEX idx_habit_occurrences_scheduled_at ON habit_occurrences(scheduled_at);
```

`habit_logs` is retained as a read-only compatibility view (SELECT over `habit_occurrences` WHERE status IN ('validated','late','too_late','missed')) so existing queries do not break during transition.

### 3.3 Grace window & snooze rules

**Grace window:**
- Default: 12 minutes for `flexible` and `fixed`.
- Default: 30 minutes for `prayer`, stored in `prayer_user_settings.grace_period_minutes`, not editable in-app.
- User-configurable range for non-prayer habits: 5–180 minutes via a slider in habit settings. Stored in `habits.grace_period_minutes`.
- Cut-off logic:
  - `validated_at <= grace_expires_at` → outcome `done`, status `validated`
  - `grace_expires_at < validated_at <= midnight(local)` → outcome `done`, status `late`
  - `validated_at > midnight(local)` → outcome `done`, status `too_late`
  - No interaction before `grace_expires_at` and job runs → status `missed`

**Snooze:**
- Allowed offsets: +5 min, +10 min, +20 min.
- Maximum 2 snoozes per occurrence (`snooze_count <= 2` enforced by CHECK constraint and Supabase RPC).
- Forbidden on `prayer` habits where `is_obligatory = true`. Supabase RPC raises `P0001` if attempted; Flutter catches it as `AppException.business`.
- Each snooze sets `next_snooze_at = now() + offset`, reschedules the local notification, and sets `status = 'snoozed'`.

### 3.4 Notification strategy (local + push)

**Hybrid model:**

| Channel | Package | Use case |
|---|---|---|
| On-device local | `flutter_local_notifications` | All scheduled habit/prayer alerts |
| FCM push | `firebase_messaging` + `firebase_core` | Admin broadcasts, remote config refresh |

**Local scheduling (`NotificationScheduler`):**
- Uses `zonedSchedule` with the user's IANA timezone (stored in `users.timezone`, resolved via `flutter_timezone`).
- Each occurrence row gets exactly one pending notification identified by `notificationId = occurrenceId.hashCode & 0x7FFFFFFF` (fits Android `int`).
- Notification payload includes `occurrenceId` and `habitId` as JSON string extras for action routing.
- Quick actions registered: **Done**, **Snooze**, **Dismiss** — handled by `NotificationActionHandler` without requiring the app to open.

**Prayer times (`adhan_dart`):**
- Calculated on-device from the user's last known coordinates (ADR-014).
- Results are stored in `prayer_occurrences` (subset of `habit_occurrences` where `habit.kind = 'prayer'`) at midnight refresh.
- User settings (calculation method, madhab, adjustments) are stored in `prayer_user_settings` and synced to Supabase so they survive device reinstalls.

**FCM:**
- Only used for admin-initiated pushes (e.g., Ramadan schedule override).
- Token stored in `user_devices.fcm_token`, refreshed on `FirebaseMessaging.onTokenRefresh`.

### 3.5 Background jobs

**Package:** `workmanager`

| Job | Trigger | Action |
|---|---|---|
| `scheduleOccurrencesForToday` | Boot completed + daily at midnight (local) | Insert `habit_occurrences` rows for the next 24 h; reschedule local notifications |
| `expireOverdueOccurrences` | Periodic, every 15 min | Set `status = 'missed'` on rows where `grace_expires_at < now()` AND `status = 'awaiting_validation'`; update `user_scores` via RPC `expire_occurrence(occurrence_id)` |
| `syncPrayerSettings` | On config change + daily | Push `prayer_user_settings` diff to Supabase |

WorkManager constraints: `NetworkType.connected` only for the sync job; no network required for local scheduling.

On iOS, background fetch is used in lieu of WorkManager periodic tasks (package handles this transparently). Minimum fetch interval set to 15 minutes.

### 3.6 Flutter architecture (services + providers + use cases)

**Services layer** (`lib/services/`):

```
NotificationService            ← public façade, injected via Riverpod
 ├── NotificationScheduler     ← occurrence → flutter_local_notifications mapping
 ├── NotificationActionHandler ← quick-action callbacks → RPC Supabase
 └── GraceWindowTracker        ← Supabase realtime subscription on habit_occurrences
                                  WHERE status = 'awaiting_validation' AND user_id = ?
```

`NotificationService` is the only entry point from `presentation/`. The sub-services are internal and never imported outside `services/`.

**Riverpod providers** (`lib/presentation/features/habits/providers/`):

```dart
// Source of truth for the current day
@riverpod
class TodayOccurrencesNotifier extends _$TodayOccurrencesNotifier {
  @override
  Future<List<HabitOccurrence>> build() async { ... }

  Future<void> validateOccurrence(String occurrenceId, String outcome) async { ... }
  Future<void> snoozeOccurrence(String occurrenceId, int offsetMinutes) async { ... }
}

// Derived — no server call
@riverpod
List<HabitOccurrence> awaitingValidation(AwaitingValidationRef ref) =>
    ref.watch(todayOccurrencesNotifierProvider).valueOrNull
        ?.where((o) => o.status == OccurrenceStatus.awaitingValidation)
        .toList() ?? [];
```

Invalidation chain: `validateOccurrence` → invalidates `todayOccurrencesNotifierProvider` → `awaitingValidationProvider` recomputes automatically → dashboard badge updates.

**Use cases** (`lib/domain/usecases/`):

| Class | Input | Output | Side effects |
|---|---|---|---|
| `ScheduleOccurrencesForToday` | `userId`, `date` | `List<HabitOccurrence>` | Inserts rows in Supabase; schedules local notifications |
| `ValidateOccurrence` | `occurrenceId`, `outcome` | `HabitOccurrence` | Calls RPC `validate_occurrence`; updates `user_scores` |
| `SnoozeOccurrence` | `occurrenceId`, `offsetMinutes` | `HabitOccurrence` | Calls RPC `snooze_occurrence`; reschedules local notification |
| `ExpireOverdueOccurrences` | `userId`, `beforeTimestamp` | `int` (count expired) | Batch update via RPC `expire_overdue_occurrences` |
| `SyncPrayerUserSettings` | `userId`, `PrayerSettings` | `void` | Upsert `prayer_user_settings` |

All RPCs enforce RLS — they only touch rows owned by the calling user's JWT subject.

**Scoring source of truth:**
`user_scores` table is the single source. `users.total_points` column must be dropped in the next migration (tracked as TODO in `data_model.md`). Mobile reads scores from `user_scores` via a dedicated provider; it never reads `users.total_points`.

---

## 4. Consequences

### 4.1 Positive

- **Full audit trail.** Every occurrence has a timestamped lifecycle; dashboards, streaks, and leaderboards are computed from immutable terminal states.
- **Reliable badge.** `awaitingValidationProvider` is derived directly from persisted rows — survives app restarts and background kills.
- **Decoupled scheduling.** `NotificationScheduler` is a pure mapping layer; swapping `flutter_local_notifications` for another package only touches this class.
- **Snooze correctness.** `snooze_count` is persisted server-side — the 2-snooze cap survives device reboots and multi-device scenarios.
- **Prayer integrity.** Snooze block on obligatory prayers is enforced at the database layer (RAISE EXCEPTION), not only in the UI.
- **Scoring integrity.** Single source of truth in `user_scores` eliminates drift between `users.total_points` and aggregated logs.

### 4.2 Negative / Trade-offs

- **Increased write volume.** Every habit execution generates at minimum 2–3 row mutations (scheduled → notified → terminal). For a user with 10 habits + 5 prayers, that is ~15 occurrences/day × 3 writes ≈ 45 mutations/day. Acceptable at current scale; revisit with server-side batching if DAU > 100k.
- **WorkManager reliability on Android.** Doze mode and OEM battery optimisations can delay the 15-minute expiry job. UI must tolerate `awaiting_validation` rows that linger slightly beyond `grace_expires_at` — the expiry timestamp is the authoritative cut-off, not the job execution time.
- **iOS background fetch is not guaranteed.** iOS schedules background fetch at its own discretion. The expiry job may run late; terminal state is still correct because `grace_expires_at` is server-persisted.
- **Migration cost.** Existing `habit_logs` data must be back-filled or left as-is behind the compatibility view. No destructive migration; the view covers read paths.
- **`users.total_points` removal is a breaking change** for any client reading that column (including potential admin tooling). Must be coordinated with `murabbi-admin` repo.

---

## 5. Rejected Alternatives

**A. Keep `habit_logs` as the only persistence layer, add a `status` column.**
Rejected: `habit_logs` is append-only by convention (ADR-006). Adding mutable lifecycle state to it blurs its semantics and makes snooze tracking (which requires updates, not inserts) awkward.

**B. Manage occurrence state fully in-memory (Riverpod only).**
Rejected: Does not survive app kills or device reboots. WorkManager background jobs have no access to Riverpod state. Server-side expiry becomes impossible.

**C. Use FCM for all habit notifications.**
Rejected: FCM delivery is non-deterministic (no SLA on delivery latency). Prayer times require second-precision accuracy. Local scheduling via `zonedSchedule` is the only reliable option for time-critical alerts.

**D. Use `timezone`-aware Dart `DateTime` instead of IANA timezone strings.**
Rejected: Dart `DateTime` does not carry IANA zone identity. Storing the IANA zone string in `users.timezone` and resolving it on-device via `flutter_timezone` is the only approach that survives DST transitions correctly.

**E. One global `occurrencesProvider` instead of a day-scoped one.**
Rejected: Loading all historical occurrences into memory on every build call is wasteful. Scoping to `today` keeps the provider payload small (< 20 rows typical) and aligns with the dashboard's temporal focus.

---

## 6. Implementation Notes

**Recommended implementation order:**

1. Supabase migration: create `habit_occurrences`, define RPCs (`validate_occurrence`, `snooze_occurrence`, `expire_overdue_occurrences`), add RLS policies, create `habit_logs` compatibility view, drop `users.total_points` after admin-side coordination.
2. Domain layer: `HabitOccurrence` freezed entity, `OccurrenceStatus` enum, repository interface `HabitOccurrenceRepository`.
3. Data layer: `SupabaseHabitOccurrenceDataSource` implementing the repository.
4. Use cases in dependency order: `ScheduleOccurrencesForToday` → `ValidateOccurrence` → `SnoozeOccurrence` → `ExpireOverdueOccurrences` → `SyncPrayerUserSettings`.
5. Services: `NotificationScheduler` (no Supabase dependency, unit-testable with mock `flutter_local_notifications`) → `NotificationActionHandler` → `GraceWindowTracker` → `NotificationService` façade.
6. WorkManager: register tasks in `main.dart` `callbackDispatcher`, wire to use cases.
7. Riverpod: `TodayOccurrencesNotifier` → `awaitingValidationProvider` → invalidation wiring.
8. Widget layer: badge on dashboard, bottom-sheet action handler (Done / Snooze / Dismiss).

**Pitfalls:**

- `zonedSchedule` requires `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` on Android 12+. Request `SCHEDULE_EXACT_ALARM` permission at runtime; fall back to `inexact` if denied (log a warning, do not crash).
- Notification `id` collision: `occurrenceId.hashCode & 0x7FFFFFFF` is not collision-free for large UUID sets. If two occurrences hash to the same int, the second notification silently replaces the first. Mitigate by storing the computed `notificationId` in the occurrence row and checking for conflicts at insert time.
- The Supabase RPC `snooze_occurrence` must validate `snooze_count < 2` and `habit.kind != 'prayer' OR NOT habit.is_obligatory` atomically. Do not rely on client-side guards alone.
- `GraceWindowTracker` uses a Supabase Realtime channel. Channels must be explicitly unsubscribed when the provider is disposed (use `ref.onDispose`). Leaking channels causes duplicate state updates.
- `users.total_points` removal: run a data consistency check before the migration — `SUM(user_scores.points) == users.total_points` for all users. Log discrepancies before dropping the column.
- TDD note: `NotificationScheduler` and all use cases must be tested with mocks before any device integration. Do not rely on manual device testing to validate the state machine — every transition must have a corresponding unit test.
