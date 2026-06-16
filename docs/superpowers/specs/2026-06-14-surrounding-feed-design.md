# Surrounding Feed — Paginated, Read-Tracked Chat Feed

**Date:** 2026-06-14
**Status:** Approved (design)

## Problem

The "Surrounding" feed shows Kind-1 notes broadcast by nearby devices over the
mesh ([SurroundingNoteModel](../../../lib/data/models/surrounding_note_model.dart),
ingested by [surrounding_inbound.dart](../../../lib/features/mesh/surrounding/surrounding_inbound.dart),
evicted daily). The current UI ([surrounding_feed_page.dart](../../../lib/features/surrounding/pages/surrounding_feed_page.dart))
loads **all** notes at once via `getAll()`, sorted by author timestamp
(`created`) newest-first, with no pagination and no read tracking — it reloads
the whole list on every mesh arrival, resetting scroll position.

We want it to behave like the **channel feed**
([channel_feed_page.dart](../../../lib/features/channels/feed/pages/channel_feed_page.dart) /
[channel_feed_bloc.dart](../../../lib/features/channels/feed/bloc/channel_feed_bloc.dart)):
a bidirectional paginated chat that opens at the user's unread boundary, loads
older notes on scroll-up and newer notes on scroll-down, and tracks what has been
read so the next visit resumes from the first unread note.

## Key differences from the channel feed

1. **Ordering key is arrival time, not author time.** Notes are ordered by
   `receivedAt` (when this device received the note over the mesh), not `created`.
   Mesh notes arrive out-of-order relative to their author timestamps; arrival
   order is the meaningful chronology.
2. **Read-only.** No composer — these are strangers' notes; the user cannot reply
   into this surface. (Channel feed has a composer; we drop it.)
3. **Ephemeral.** Surrounding notes are evicted daily. The read pointer must
   survive eviction.
4. **Single global feed.** Not per-channel — one read pointer for the whole
   surrounding feed.

## Product decisions (confirmed with user)

- **Open position:** when unread notes exist, the **first unread note is pinned
  to the top** of the viewport. Already-read notes are reachable by scrolling up;
  newer notes by scrolling down. (Not the channel's mid-screen anchor.)
- **Mark-as-read:** automatic — a note becomes read once it has been visible then
  scrolled out of view (channel-style `VisibilityDetector`). Reaching the newest
  note marks everything loaded read.
- **Live arrivals:** new notes arriving over the mesh while the feed is open are
  appended silently at the bottom; the user's scroll position is never disturbed.

## Design

### 1. Read pointer — a single timestamp watermark

New `SurroundingReadStateStore` (`@singleton`, SharedPreferences), mirroring
[FeedReadStateStore](../../../lib/data/datasources/feed_read_state_store.dart):

```dart
@singleton
class SurroundingReadStateStore {
  // key: 'surrounding_read_state.last_read_received_at_ms'
  DateTime get lastReadReceivedAt;        // epoch 0 if unset → everything unread
  Future<void> setLastReadReceivedAt(DateTime ts);
}
```

A raw **timestamp** watermark is used (not a `lastReadEventId`) because
surrounding notes are evicted daily — an eventId pointer could reference an
evicted note, whereas a timestamp survives eviction. "Mark read" advances the
watermark to `max(current, note.receivedAt)`. A note is unread iff
`receivedAt > watermark`.

### 2. Domain — `SurroundingNoteEntity` wrapper

The UI needs each note's `receivedAt` (to advance the watermark on scroll-past
and as the pagination cursor), but `NoteEntity` carries only `created`. Rather
than add a mesh-transport field to the shared `NoteEntity`, add a small wrapper:

```dart
// lib/domain/entities/surrounding/surrounding_note_entity.dart
@freezed
abstract class SurroundingNoteEntity with _$SurroundingNoteEntity {
  const factory SurroundingNoteEntity({
    required NoteEntity note,
    required DateTime receivedAt,
  }) = _SurroundingNoteEntity;
}
```

The page renders `item.note` in `NoteCard`; visibility + cursors use
`item.receivedAt`.

### 3. Repository — replace `getAll()`

[SurroundingNoteRepository](../../../lib/domain/repositories/surrounding_note_repository.dart)
new contract (keep `watch()` and `promoteToSaved()` as-is):

```dart
abstract class SurroundingNoteRepository {
  /// Older page: notes with receivedAt < [before] (newest overall if null),
  /// newest-first, capped at [limit].
  Future<List<SurroundingNoteEntity>> getBefore({DateTime? before, required int limit});

  /// Newer page: notes with receivedAt > [after] (>= if [inclusive]),
  /// oldest-first, capped at [limit].
  Future<List<SurroundingNoteEntity>> getAfter({
    required DateTime after,
    bool inclusive = false,
    required int limit,
  });

  /// Boundary: receivedAt of the oldest still-unread note
  /// (receivedAt > watermark). Null if all read / empty.
  Future<DateTime?> oldestUnreadReceivedAt();

  /// Advance the read watermark to max(current, [receivedAt]).
  Future<void> markReadUpTo(DateTime receivedAt);

  Stream<void> watch();
  Future<void> promoteToSaved(String eventId);
}
```

`receivedAt` is already `@Index()`-ed on `SurroundingNoteModel`, so these are
indexed queries. **No Isar schema change, no migration.** The impl gains a
`SurroundingReadStateStore` constructor dependency for the watermark methods.

### 4. Cubit + state (expand existing `SurroundingCubit`)

Keep it a `Cubit` calling the repository interface directly via `getIt` (the
established pattern in this feature — no use-case layer introduced).

State fields:

```dart
status            // initial | loading | loaded
notes             // List<SurroundingNoteEntity>, oldest→newest
boundaryIndex     // notes[0..boundaryIndex-1] read on open; [boundaryIndex..] unread on open
openedWithUnread  // anchor 0.0 if true, else 1.0
hasMoreOlder
hasMoreNewer
isLoadingOlder
isLoadingNewer
```

Page size constant (mirror channel's `_kChannelPageSize = 10`).

- **`load()`**: `boundary = oldestUnreadReceivedAt()`.
  - Top section = newest page `getBefore(before: boundary)`, reversed to ascending.
  - Bottom section = `getAfter(after: boundary, inclusive: true)` (oldest unread page).
  - `openedWithUnread = bottom.isNotEmpty`.
  - **All read** (`boundary == null`): top = newest page `getBefore(before: null)`,
    bottom = empty, `openedWithUnread = false` → opens at the newest note.
  - `notes = [...top, ...bottom]`, `boundaryIndex = top.length`,
    `hasMoreOlder = top hit limit`, `hasMoreNewer = bottom hit limit`.
- **`loadOlder()`**: guard on `isLoadingOlder`/`hasMoreOlder`. `getBefore(before:
  notes.first.receivedAt)`, reverse to ascending, dedupe by eventId, prepend.
  Bump `boundaryIndex` by the count prepended. `hasMoreOlder = page hit limit`.
- **`loadNewer({bool isRefresh = false})`**: guard on `isLoadingNewer`; bypass
  `hasMoreNewer` when `isRefresh`. `getAfter(after: notes.last.receivedAt,
  inclusive: true)`, dedupe, append. `hasMoreNewer = page hit limit`.
- **`markRead(DateTime receivedAt)`**: `repo.markReadUpTo(receivedAt)`. Guarded
  with an in-cubit `Set<DateTime>` / max-watermark so it isn't written on every
  scroll frame.
- **`watch()` subscription** fires on mesh arrival/eviction → silent `loadNewer()`
  (append-only; never resets scroll). Replaces the current full `load()` reload.

### 5. Page — center-sliver `CustomScrollView`

Rewrite [surrounding_feed_page.dart](../../../lib/features/surrounding/pages/surrounding_feed_page.dart)
to mirror the channel feed page's scroll mechanics:

- Two slivers split at `boundaryIndex`: a pre-center sliver (read section,
  rendered reversed so it grows **upward**) + a center sliver keyed
  `_centerKey` (unread section, grows **downward**).
- **`anchor: state.openedWithUnread ? 0.0 : 1.0`** — `0.0` pins the first unread
  note to the **top** (per product decision); `1.0` anchors the newest note at
  the bottom when all-read.
- `_onScroll`: near `minScrollExtent` → `loadOlder()`; near `maxScrollExtent` →
  `loadNewer()`.
- `OverscrollNotification` past the bottom → `loadNewer(isRefresh: true)`.
- `VisibilityDetector` per note: once `visibleFraction >= 0.5` then back to `0`,
  call `markRead(item.receivedAt)`.
- Edge spinners while loading older/newer (reuse channel's `_EdgeSpinner` shape).
- **No composer.** Keep the existing AppBar, `_EmptyState`, and l10n keys
  (`surroundingTitle`, `surroundingEmpty`, `surroundingEmptySub`). Render
  `NoteCard(note: item.note, onTap: () {})` — `NoteCard` owns its own bookmark.

### Not changing

Mesh ingest/eviction, `SurroundingNoteModel`, `NoteCard`, routing
([app_router.dart:136](../../../lib/core/router/app_router.dart#L136)). No new
l10n strings.

## Eviction interplay

Daily eviction removes notes with `receivedAt < cutoff`. The watermark may point
into evicted territory — harmless, it's just a high-water mark; those notes are
gone. New arrivals always have `receivedAt = DateTime.now() > watermark`, so they
surface as unread. The timestamp watermark needs no fix-up after eviction.

## Acceptance criteria

1. Opening the feed with unread notes pins the **oldest unread** note to the top;
   scrolling up reveals already-read notes, scrolling down reveals newer ones.
2. Opening with everything read shows the newest notes at the bottom (chat-style).
3. Notes are ordered by `receivedAt` (arrival), ascending top→bottom.
4. Scrolling a note out of view marks it read; closing and reopening resumes from
   the first still-unread note.
5. New mesh arrivals append at the bottom without moving the current scroll
   position.
6. Pagination loads in pages (no full-list load); dedupe prevents duplicates at
   page seams.
7. Empty feed shows the existing empty state.
8. `flutter analyze` clean; `build_runner` regenerates the freezed entity +
   injectable config.

## Build / verify

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```
