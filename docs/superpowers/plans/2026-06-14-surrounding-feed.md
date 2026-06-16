# Surrounding Feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Surrounding feed (Kind-1 notes received from nearby strangers over the mesh) into a bidirectional paginated chat feed that orders by arrival time (`receivedAt`), opens at the first unread note, loads older notes on scroll-up and newer notes on scroll-down, and tracks a read pointer so the next visit resumes from the first unread note.

**Architecture:** A single timestamp watermark (`SurroundingReadStateStore`, SharedPreferences) records the `receivedAt` of the newest read note; a note is unread iff `receivedAt > watermark`. The repository gains cursor-paginated `getBefore`/`getAfter` queries over the already-indexed `receivedAt` field plus boundary/mark-read helpers. A new `SurroundingNoteEntity` wrapper carries each note's `receivedAt` to the UI without polluting the shared `NoteEntity`. The `SurroundingCubit` drives bidirectional pagination; the page mirrors the channel feed's center-sliver `CustomScrollView`, anchored at `0.0` (first unread at top) when unread notes exist.

**Tech Stack:** Flutter, flutter_bloc (Cubit), Isar (isar_community 3.3.2), SharedPreferences, freezed 3.x, injectable + get_it, visibility_detector. Tests via flutter_test with real Isar (download core) and mocked SharedPreferences.

**Reference files (read before starting):**
- Spec: `docs/superpowers/specs/2026-06-14-surrounding-feed-design.md`
- Pattern to mirror: `lib/features/channels/feed/bloc/channel_feed_bloc.dart`, `lib/features/channels/feed/pages/channel_feed_page.dart`
- Read-pointer precedent: `lib/data/datasources/feed_read_state_store.dart`, `lib/data/datasources/app_settings_store.dart` (SharedPreferences DI module)
- Test precedent (real Isar): `test/mesh/surrounding_integration_test.dart`
- Model (unchanged): `lib/data/models/surrounding_note_model.dart` — `receivedAt` is already `@Index()`-ed.

---

## Task 1: SurroundingReadStateStore (read watermark)

**Files:**
- Create: `lib/data/datasources/surrounding_read_state_store.dart`
- Test: `test/surrounding/surrounding_read_state_store_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/surrounding/surrounding_read_state_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/data/datasources/surrounding_read_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SurroundingReadStateStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // guarantee isolation across tests
    return SurroundingReadStateStore(prefs);
  }

  test('defaults to epoch 0 when unset', () async {
    final store = await freshStore();
    expect(store.lastReadReceivedAt, DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('advanceTo moves the watermark forward', () async {
    final store = await freshStore();
    final t = DateTime.fromMillisecondsSinceEpoch(1000);
    await store.advanceTo(t);
    expect(store.lastReadReceivedAt, t);
  });

  test('advanceTo never moves the watermark backward', () async {
    final store = await freshStore();
    await store.advanceTo(DateTime.fromMillisecondsSinceEpoch(2000));
    await store.advanceTo(DateTime.fromMillisecondsSinceEpoch(1000));
    expect(store.lastReadReceivedAt, DateTime.fromMillisecondsSinceEpoch(2000));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/surrounding/surrounding_read_state_store_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../surrounding_read_state_store.dart'`.

- [ ] **Step 3: Write minimal implementation**

Create `lib/data/datasources/surrounding_read_state_store.dart`:

```dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Surrounding feed's read watermark — the `receivedAt` of the
/// newest surrounding note the user has read. A single scalar in
/// SharedPreferences (epoch millis). A surrounding note is unread iff its
/// `receivedAt` is strictly greater than this watermark.
///
/// A timestamp (not a `lastReadEventId`) is used because surrounding notes are
/// evicted daily — an eventId pointer could reference an evicted note, whereas a
/// timestamp watermark survives eviction. Mirrors [FeedReadStateStore].
@singleton
class SurroundingReadStateStore {
  static const _kLastReadMs = 'surrounding_read_state.last_read_received_at_ms';

  final SharedPreferences _prefs;

  SurroundingReadStateStore(this._prefs);

  /// Epoch (millis 0) when unset → every note is unread on first open.
  DateTime get lastReadReceivedAt {
    final ms = _prefs.getInt(_kLastReadMs) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Advances the watermark to max(current, [ts]). Never moves it backwards.
  Future<void> advanceTo(DateTime ts) async {
    final current = _prefs.getInt(_kLastReadMs) ?? 0;
    if (ts.millisecondsSinceEpoch <= current) return;
    await _prefs.setInt(_kLastReadMs, ts.millisecondsSinceEpoch);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/surrounding/surrounding_read_state_store_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/datasources/surrounding_read_state_store.dart test/surrounding/surrounding_read_state_store_test.dart
git commit -m "feat(surrounding): add read watermark store"
```

---

## Task 2: SurroundingNoteEntity (domain wrapper)

**Files:**
- Create: `lib/domain/entities/surrounding/surrounding_note_entity.dart`
- Generated (by build_runner): `lib/domain/entities/surrounding/surrounding_note_entity.freezed.dart`

- [ ] **Step 1: Write the entity**

Create `lib/domain/entities/surrounding/surrounding_note_entity.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

part 'surrounding_note_entity.freezed.dart';

/// A surrounding-feed item: the rendered [note] plus the local [receivedAt]
/// timestamp (when this device received it over the mesh). `receivedAt` drives
/// feed ordering, pagination cursors, and the read watermark — it is mesh
/// transport metadata that does not belong on the shared [NoteEntity].
@freezed
abstract class SurroundingNoteEntity with _$SurroundingNoteEntity {
  const factory SurroundingNoteEntity({
    required NoteEntity note,
    required DateTime receivedAt,
  }) = _SurroundingNoteEntity;
}
```

- [ ] **Step 2: Run build_runner to generate the freezed part**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: SUCCESS; `lib/domain/entities/surrounding/surrounding_note_entity.freezed.dart` is created.

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/domain/entities/surrounding/surrounding_note_entity.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/domain/entities/surrounding/surrounding_note_entity.dart lib/domain/entities/surrounding/surrounding_note_entity.freezed.dart
git commit -m "feat(surrounding): add SurroundingNoteEntity wrapper"
```

---

## Task 3: Repository — paginated queries + watermark

**Files:**
- Modify: `lib/domain/repositories/surrounding_note_repository.dart` (replace interface)
- Modify: `lib/data/repositories/surrounding_note_repository_impl.dart` (replace impl body)
- Test: `test/surrounding/surrounding_note_repository_test.dart`
- Regenerated (by build_runner): `lib/common/locator.config.dart` (new store + changed constructor)

- [ ] **Step 1: Write the failing integration test**

Create `test/surrounding/surrounding_note_repository_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/data/datasources/isar_schemas.dart';
import 'package:uniun/data/datasources/surrounding_read_state_store.dart';
import 'package:uniun/data/models/surrounding_note_model.dart';
import 'package:uniun/data/repositories/surrounding_note_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var isarReady = false;
  final temps = <Directory>[];

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
      isarReady = true;
    } catch (e) {
      // ignore: avoid_print
      print('Isar core unavailable, skipping: $e');
    }
  });

  tearDownAll(() async {
    for (final d in temps) {
      if (await d.exists()) await d.delete(recursive: true);
    }
  });

  Future<Isar> openIsar(String name) async {
    final dir = await Directory.systemTemp.createTemp('uniun_surrrepo_$name');
    temps.add(dir);
    return Isar.open(isarSchemas,
        directory: dir.path, name: '$name${temps.length}');
  }

  SurroundingNoteModel note(String id, int ms) => SurroundingNoteModel()
    ..eventId = id
    ..sig = 'sig_$id'
    ..authorPubkey = 'pk_$id'
    ..content = 'c_$id'
    ..type = NoteType.text
    ..eTagRefs = const []
    ..pTagRefs = const []
    ..tTags = const []
    ..kind = 1
    ..created = DateTime.fromMillisecondsSinceEpoch(ms)
    ..receivedAt = DateTime.fromMillisecondsSinceEpoch(ms);

  Future<SurroundingNoteRepositoryImpl> makeRepo(Isar isar) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // no cross-test watermark leakage
    return SurroundingNoteRepositoryImpl(
      isar: isar,
      readStore: SurroundingReadStateStore(prefs),
    );
  }

  test('getAfter returns notes strictly newer than the cursor, ascending',
      () async {
    if (!isarReady) return;
    final isar = await openIsar('after');
    addTearDown(() async => isar.close());
    await isar.writeTxn(() async {
      await isar.surroundingNoteModels
          .putAll([note('a', 100), note('b', 200), note('c', 300)]);
    });
    final repo = await makeRepo(isar);
    final page = await repo.getAfter(
        after: DateTime.fromMillisecondsSinceEpoch(100), limit: 10);
    expect(page.map((e) => e.note.id).toList(), ['b', 'c']);
  });

  test('getAfter inclusive includes the cursor note', () async {
    if (!isarReady) return;
    final isar = await openIsar('afterinc');
    addTearDown(() async => isar.close());
    await isar.writeTxn(() async {
      await isar.surroundingNoteModels.putAll([note('a', 100), note('b', 200)]);
    });
    final repo = await makeRepo(isar);
    final page = await repo.getAfter(
        after: DateTime.fromMillisecondsSinceEpoch(100),
        inclusive: true,
        limit: 10);
    expect(page.map((e) => e.note.id).toList(), ['a', 'b']);
  });

  test('getBefore returns notes older than the cursor, oldest-to-newest, capped',
      () async {
    if (!isarReady) return;
    final isar = await openIsar('before');
    addTearDown(() async => isar.close());
    await isar.writeTxn(() async {
      await isar.surroundingNoteModels.putAll(
          [note('a', 100), note('b', 200), note('c', 300), note('d', 400)]);
    });
    final repo = await makeRepo(isar);
    final page = await repo.getBefore(
        before: DateTime.fromMillisecondsSinceEpoch(400), limit: 2);
    // newest two below 400 → b(200), c(300), returned ascending
    expect(page.map((e) => e.note.id).toList(), ['b', 'c']);
  });

  test('getBefore with null cursor returns the newest page, ascending',
      () async {
    if (!isarReady) return;
    final isar = await openIsar('beforenull');
    addTearDown(() async => isar.close());
    await isar.writeTxn(() async {
      await isar.surroundingNoteModels
          .putAll([note('a', 100), note('b', 200), note('c', 300)]);
    });
    final repo = await makeRepo(isar);
    final page = await repo.getBefore(before: null, limit: 2);
    // newest two → b(200), c(300), ascending
    expect(page.map((e) => e.note.id).toList(), ['b', 'c']);
  });

  test('oldestUnreadReceivedAt is the first note past the watermark', () async {
    if (!isarReady) return;
    final isar = await openIsar('unread');
    addTearDown(() async => isar.close());
    await isar.writeTxn(() async {
      await isar.surroundingNoteModels
          .putAll([note('a', 100), note('b', 200), note('c', 300)]);
    });
    final repo = await makeRepo(isar);
    await repo.markReadUpTo(DateTime.fromMillisecondsSinceEpoch(150));
    expect(await repo.oldestUnreadReceivedAt(),
        DateTime.fromMillisecondsSinceEpoch(200));
  });

  test('oldestUnreadReceivedAt is null when everything is read', () async {
    if (!isarReady) return;
    final isar = await openIsar('allread');
    addTearDown(() async => isar.close());
    await isar.writeTxn(() async {
      await isar.surroundingNoteModels.putAll([note('a', 100), note('b', 200)]);
    });
    final repo = await makeRepo(isar);
    await repo.markReadUpTo(DateTime.fromMillisecondsSinceEpoch(999));
    expect(await repo.oldestUnreadReceivedAt(), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/surrounding/surrounding_note_repository_test.dart`
Expected: FAIL — compile error (the impl has no `readStore` param / no `getAfter`/`getBefore`/`oldestUnreadReceivedAt`/`markReadUpTo`).

- [ ] **Step 3: Replace the repository interface**

Replace the entire contents of `lib/domain/repositories/surrounding_note_repository.dart` with:

```dart
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';

/// Read side of the ephemeral "Surrounding" feed (notes received from nearby
/// strangers over the mesh). Ordered by `receivedAt` (arrival time on this
/// device), not author time. Writes/eviction happen in the mesh layer.
abstract class SurroundingNoteRepository {
  /// Older page: notes with receivedAt < [before] (newest overall if null),
  /// returned oldest→newest, capped at [limit].
  Future<List<SurroundingNoteEntity>> getBefore({
    DateTime? before,
    required int limit,
  });

  /// Newer page: notes with receivedAt > [after] (>= if [inclusive]),
  /// returned oldest→newest, capped at [limit].
  Future<List<SurroundingNoteEntity>> getAfter({
    required DateTime after,
    bool inclusive = false,
    required int limit,
  });

  /// receivedAt of the oldest still-unread note (receivedAt > read watermark);
  /// null when everything is read or the cache is empty.
  Future<DateTime?> oldestUnreadReceivedAt();

  /// Advances the read watermark to max(current, [receivedAt]).
  Future<void> markReadUpTo(DateTime receivedAt);

  /// Fires whenever the surrounding cache changes (new arrivals / eviction).
  Stream<void> watch();

  /// Promotes a surrounding note into the forever-retained saved notes, so it
  /// survives the daily eviction. No-op if already saved or unknown.
  Future<void> promoteToSaved(String eventId);
}
```

- [ ] **Step 4: Replace the repository implementation**

Replace the entire contents of `lib/data/repositories/surrounding_note_repository_impl.dart` with:

```dart
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/datasources/surrounding_read_state_store.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/models/surrounding_note_model.dart';
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';
import 'package:uniun/domain/repositories/surrounding_note_repository.dart';

@Injectable(as: SurroundingNoteRepository)
class SurroundingNoteRepositoryImpl extends SurroundingNoteRepository {
  final Isar isar;
  final SurroundingReadStateStore readStore;
  SurroundingNoteRepositoryImpl({required this.isar, required this.readStore});

  SurroundingNoteEntity _wrap(SurroundingNoteModel r) =>
      SurroundingNoteEntity(note: r.toDomain(), receivedAt: r.receivedAt);

  @override
  Future<List<SurroundingNoteEntity>> getBefore({
    DateTime? before,
    required int limit,
  }) async {
    final List<SurroundingNoteModel> rows;
    if (before == null) {
      rows = await isar.surroundingNoteModels
          .where()
          .sortByReceivedAtDesc()
          .limit(limit)
          .findAll();
    } else {
      rows = await isar.surroundingNoteModels
          .filter()
          .receivedAtLessThan(before)
          .sortByReceivedAtDesc()
          .limit(limit)
          .findAll();
    }
    // Query is newest-first; the feed renders oldest→newest.
    return rows.reversed.map(_wrap).toList();
  }

  @override
  Future<List<SurroundingNoteEntity>> getAfter({
    required DateTime after,
    bool inclusive = false,
    required int limit,
  }) async {
    final rows = await isar.surroundingNoteModels
        .filter()
        .receivedAtGreaterThan(after, include: inclusive)
        .sortByReceivedAt()
        .limit(limit)
        .findAll(); // oldest→newest
    return rows.map(_wrap).toList();
  }

  @override
  Future<DateTime?> oldestUnreadReceivedAt() async {
    final watermark = readStore.lastReadReceivedAt;
    final row = await isar.surroundingNoteModels
        .filter()
        .receivedAtGreaterThan(watermark)
        .sortByReceivedAt()
        .findFirst();
    return row?.receivedAt;
  }

  @override
  Future<void> markReadUpTo(DateTime receivedAt) =>
      readStore.advanceTo(receivedAt);

  @override
  Stream<void> watch() => isar.surroundingNoteModels.watchLazy();

  @override
  Future<void> promoteToSaved(String eventId) async {
    final row = await isar.surroundingNoteModels
        .where()
        .eventIdEqualTo(eventId)
        .findFirst();
    if (row == null) return;
    final existing =
        await isar.savedNoteModels.where().eventIdEqualTo(eventId).findFirst();
    if (existing != null) return;

    await isar.writeTxn(() async {
      await isar.savedNoteModels.put(SavedNoteModel()
        ..eventId = row.eventId
        ..sig = row.sig
        ..authorPubkey = row.authorPubkey
        ..content = row.content
        ..type = row.type
        ..eTagRefs = row.eTagRefs
        ..rootEventId = row.rootEventId
        ..replyToEventId = row.replyToEventId
        ..pTagRefs = row.pTagRefs
        ..tTags = row.tTags
        ..created = row.created
        ..savedAt = DateTime.now()
        ..quoteEventId = row.quoteEventId);
    });
  }
}
```

- [ ] **Step 5: Regenerate injectable config (new @singleton store + changed constructor)**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: SUCCESS; `lib/common/locator.config.dart` now registers `SurroundingReadStateStore` and passes `readStore:` into `SurroundingNoteRepositoryImpl`.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/surrounding/surrounding_note_repository_test.dart`
Expected: PASS (6 tests). If the machine has no network for the Isar core, every test early-returns and the suite passes trivially — note that in the commit but do not treat a green run as proof unless the core downloaded (look for the "Isar core unavailable" print).

- [ ] **Step 7: Commit**

```bash
git add lib/domain/repositories/surrounding_note_repository.dart lib/data/repositories/surrounding_note_repository_impl.dart lib/common/locator.config.dart test/surrounding/surrounding_note_repository_test.dart
git commit -m "feat(surrounding): paginated receivedAt queries + read watermark"
```

---

## Task 4: SurroundingCubit + state (bidirectional pagination)

**Files:**
- Modify: `lib/features/surrounding/cubit/surrounding_state.dart` (replace)
- Modify: `lib/features/surrounding/cubit/surrounding_cubit.dart` (replace)
- Test: `test/surrounding/surrounding_cubit_test.dart`

- [ ] **Step 1: Write the failing cubit test**

Create `test/surrounding/surrounding_cubit_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';
import 'package:uniun/domain/repositories/surrounding_note_repository.dart';
import 'package:uniun/features/surrounding/cubit/surrounding_cubit.dart';

SurroundingNoteEntity item(String id, int ms) => SurroundingNoteEntity(
      note: NoteEntity(
        id: id,
        sig: 's',
        authorPubkey: 'pk',
        content: id,
        type: NoteType.text,
        eTagRefs: const [],
        pTagRefs: const [],
        tTags: const [],
        created: DateTime.fromMillisecondsSinceEpoch(ms),
      ),
      receivedAt: DateTime.fromMillisecondsSinceEpoch(ms),
    );

/// In-memory fake; `all` is kept ascending by receivedAt.
class FakeSurroundingRepo implements SurroundingNoteRepository {
  FakeSurroundingRepo(this.all, {DateTime? watermark})
      : _watermark = watermark ?? DateTime.fromMillisecondsSinceEpoch(0);
  final List<SurroundingNoteEntity> all;
  DateTime _watermark;
  DateTime? markedReadTo;

  @override
  Future<List<SurroundingNoteEntity>> getBefore(
      {DateTime? before, required int limit}) async {
    final list = all
        .where((e) => before == null || e.receivedAt.isBefore(before))
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)); // newest-first
    return list.take(limit).toList().reversed.toList(); // ascending
  }

  @override
  Future<List<SurroundingNoteEntity>> getAfter(
      {required DateTime after, bool inclusive = false, required int limit}) async {
    final list = all
        .where((e) => inclusive
            ? !e.receivedAt.isBefore(after)
            : e.receivedAt.isAfter(after))
        .toList()
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt)); // ascending
    return list.take(limit).toList();
  }

  @override
  Future<DateTime?> oldestUnreadReceivedAt() async {
    final unread = all.where((e) => e.receivedAt.isAfter(_watermark)).toList()
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    return unread.isEmpty ? null : unread.first.receivedAt;
  }

  @override
  Future<void> markReadUpTo(DateTime receivedAt) async {
    markedReadTo = receivedAt;
    if (receivedAt.isAfter(_watermark)) _watermark = receivedAt;
  }

  @override
  Stream<void> watch() => const Stream<void>.empty();

  @override
  Future<void> promoteToSaved(String eventId) async {}
}

void main() {
  test('all-read feed opens at the bottom (openedWithUnread false)', () async {
    final repo = FakeSurroundingRepo(
      [item('a', 100), item('b', 200)],
      watermark: DateTime.fromMillisecondsSinceEpoch(999),
    );
    final cubit = SurroundingCubit(repo: repo);
    await cubit.load();
    expect(cubit.state.openedWithUnread, false);
    expect(cubit.state.notes.map((e) => e.note.id).toList(), ['a', 'b']);
    expect(cubit.state.boundaryIndex, 2);
    await cubit.close();
  });

  test('unread feed anchors first unread; boundary splits read/unread', () async {
    final repo = FakeSurroundingRepo(
      [item('a', 100), item('b', 200), item('c', 300)],
      watermark: DateTime.fromMillisecondsSinceEpoch(150),
    );
    final cubit = SurroundingCubit(repo: repo);
    await cubit.load();
    expect(cubit.state.openedWithUnread, true);
    expect(cubit.state.notes.map((e) => e.note.id).toList(), ['a', 'b', 'c']);
    expect(cubit.state.boundaryIndex, 1); // 'a' read; 'b','c' unread
    await cubit.close();
  });

  test('loadOlder prepends older notes and shifts the boundary', () async {
    final notes = [for (var i = 1; i <= 12; i++) item('n$i', i * 100)];
    final repo = FakeSurroundingRepo(notes,
        watermark: DateTime.fromMillisecondsSinceEpoch(99999)); // all read
    final cubit = SurroundingCubit(repo: repo);
    await cubit.load();
    expect(cubit.state.notes.length, 10); // newest page
    expect(cubit.state.notes.first.note.id, 'n3');
    expect(cubit.state.hasMoreOlder, true);
    await cubit.loadOlder();
    expect(cubit.state.notes.first.note.id, 'n1');
    expect(cubit.state.notes.length, 12);
    await cubit.close();
  });

  test('loadNewer appends newer notes', () async {
    // Open with watermark 150 so 'a' is read, 'b' unread; page size hides nothing.
    final repo = FakeSurroundingRepo(
      [item('a', 100), item('b', 200)],
      watermark: DateTime.fromMillisecondsSinceEpoch(150),
    );
    final cubit = SurroundingCubit(repo: repo);
    await cubit.load();
    // A new note arrives in the underlying store.
    repo.all.add(item('c', 300));
    await cubit.loadNewer(isRefresh: true);
    expect(cubit.state.notes.map((e) => e.note.id).toList(), ['a', 'b', 'c']);
    await cubit.close();
  });

  test('markRead advances the watermark monotonically', () async {
    final repo = FakeSurroundingRepo([item('a', 100)]);
    final cubit = SurroundingCubit(repo: repo);
    cubit.markRead(DateTime.fromMillisecondsSinceEpoch(200));
    cubit.markRead(DateTime.fromMillisecondsSinceEpoch(100)); // ignored
    expect(repo.markedReadTo, DateTime.fromMillisecondsSinceEpoch(200));
    await cubit.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/surrounding/surrounding_cubit_test.dart`
Expected: FAIL — compile error (`SurroundingCubit` has no `repo` named param, no `loadOlder`/`loadNewer`/`markRead`; state has no `boundaryIndex`/`openedWithUnread`/`hasMoreOlder`/`hasMoreNewer`).

- [ ] **Step 3: Replace the state**

Replace the entire contents of `lib/features/surrounding/cubit/surrounding_state.dart` with:

```dart
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';

enum SurroundingStatus { initial, loading, loaded }

class SurroundingState {
  const SurroundingState({
    this.status = SurroundingStatus.initial,
    this.notes = const [],
    this.boundaryIndex = 0,
    this.openedWithUnread = false,
    this.hasMoreOlder = false,
    this.hasMoreNewer = false,
    this.isLoadingOlder = false,
    this.isLoadingNewer = false,
  });

  final SurroundingStatus status;

  /// All loaded items, oldest→newest by receivedAt.
  ///
  /// `notes[0 .. boundaryIndex - 1]` were already read when the feed opened
  /// (top section, grows upward); `notes[boundaryIndex ..]` were unread on open
  /// (center/bottom section, grows downward).
  final List<SurroundingNoteEntity> notes;

  /// Index where the unread section begins (count of leading read notes).
  final int boundaryIndex;

  /// True when the feed had unread notes on open → the first unread note is
  /// anchored at the top (anchor 0.0). False → anchored at the bottom (1.0).
  final bool openedWithUnread;

  final bool hasMoreOlder;
  final bool hasMoreNewer;
  final bool isLoadingOlder;
  final bool isLoadingNewer;

  SurroundingState copyWith({
    SurroundingStatus? status,
    List<SurroundingNoteEntity>? notes,
    int? boundaryIndex,
    bool? openedWithUnread,
    bool? hasMoreOlder,
    bool? hasMoreNewer,
    bool? isLoadingOlder,
    bool? isLoadingNewer,
  }) {
    return SurroundingState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      boundaryIndex: boundaryIndex ?? this.boundaryIndex,
      openedWithUnread: openedWithUnread ?? this.openedWithUnread,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      hasMoreNewer: hasMoreNewer ?? this.hasMoreNewer,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isLoadingNewer: isLoadingNewer ?? this.isLoadingNewer,
    );
  }
}
```

- [ ] **Step 4: Replace the cubit**

Replace the entire contents of `lib/features/surrounding/cubit/surrounding_cubit.dart` with:

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';
import 'package:uniun/domain/repositories/surrounding_note_repository.dart';

import 'surrounding_state.dart';

/// Items loaded per upward / downward pagination step.
const int _kSurroundingPageSize = 10;

class SurroundingCubit extends Cubit<SurroundingState> {
  SurroundingCubit({SurroundingNoteRepository? repo})
      : _repo = repo ?? getIt<SurroundingNoteRepository>(),
        super(const SurroundingState()) {
    // Live updates: surrounding notes arrive over the mesh + evict daily.
    _sub = _repo.watch().listen((_) => _onCacheChanged());
  }

  final SurroundingNoteRepository _repo;
  StreamSubscription<void>? _sub;

  /// Highest receivedAt already pushed to the read watermark — avoids a
  /// SharedPreferences write on every scroll frame.
  DateTime _persistedReadMark = DateTime.fromMillisecondsSinceEpoch(0);

  /// Initial bidirectional load. Anchors at the read→unread boundary: a page of
  /// already-read notes above, the oldest page of unread notes below. When
  /// everything is read it opens at the newest notes (bottom).
  Future<void> load() async {
    if (state.status == SurroundingStatus.initial) {
      emit(state.copyWith(status: SurroundingStatus.loading));
    }

    final boundary = await _repo.oldestUnreadReceivedAt();

    final top = await _repo.getBefore(
      before: boundary,
      limit: _kSurroundingPageSize,
    ); // oldest→newest

    var bottom = <SurroundingNoteEntity>[];
    if (boundary != null) {
      bottom = await _repo.getAfter(
        after: boundary,
        inclusive: true,
        limit: _kSurroundingPageSize,
      ); // oldest→newest
    }

    if (isClosed) return;
    emit(state.copyWith(
      status: SurroundingStatus.loaded,
      notes: [...top, ...bottom],
      boundaryIndex: top.length,
      openedWithUnread: bottom.isNotEmpty,
      hasMoreOlder: top.length == _kSurroundingPageSize,
      hasMoreNewer: bottom.length == _kSurroundingPageSize,
      isLoadingOlder: false,
      isLoadingNewer: false,
    ));
  }

  /// Scrolling up: prepend the next older page of read notes.
  Future<void> loadOlder() async {
    if (state.isLoadingOlder || !state.hasMoreOlder || state.notes.isEmpty) {
      return;
    }
    emit(state.copyWith(isLoadingOlder: true));

    final older = await _repo.getBefore(
      before: state.notes.first.receivedAt,
      limit: _kSurroundingPageSize,
    );
    final existing = state.notes.map((e) => e.note.id).toSet();
    final fresh = older.where((e) => !existing.contains(e.note.id)).toList();
    if (fresh.isEmpty) {
      emit(state.copyWith(isLoadingOlder: false, hasMoreOlder: false));
      return;
    }
    emit(state.copyWith(
      notes: [...fresh, ...state.notes],
      boundaryIndex: state.boundaryIndex + fresh.length,
      hasMoreOlder: older.length == _kSurroundingPageSize,
      isLoadingOlder: false,
    ));
  }

  /// Scrolling down (or a mesh arrival, via [isRefresh]): append the next newer
  /// page. Inclusive + dedupe so notes sharing the last loaded receivedAt are
  /// not skipped.
  Future<void> loadNewer({bool isRefresh = false}) async {
    if (state.isLoadingNewer || state.notes.isEmpty) return;
    if (!isRefresh && !state.hasMoreNewer) return;
    emit(state.copyWith(isLoadingNewer: true));

    final newer = await _repo.getAfter(
      after: state.notes.last.receivedAt,
      inclusive: true,
      limit: _kSurroundingPageSize,
    );
    final existing = state.notes.map((e) => e.note.id).toSet();
    final fresh = newer.where((e) => !existing.contains(e.note.id)).toList();
    if (fresh.isEmpty) {
      emit(state.copyWith(isLoadingNewer: false, hasMoreNewer: false));
      return;
    }
    emit(state.copyWith(
      notes: [...state.notes, ...fresh],
      hasMoreNewer: newer.length == _kSurroundingPageSize,
      isLoadingNewer: false,
    ));
  }

  /// A note left the viewport after being seen → advance the read watermark.
  /// Skipped when it would not move the watermark forward.
  void markRead(DateTime receivedAt) {
    if (!receivedAt.isAfter(_persistedReadMark)) return;
    _persistedReadMark = receivedAt;
    _repo.markReadUpTo(receivedAt);
  }

  /// Mesh arrival or eviction. Empty/not-yet-loaded → full load; otherwise
  /// silently append newer notes without disturbing the scroll position.
  Future<void> _onCacheChanged() async {
    if (state.status != SurroundingStatus.loaded || state.notes.isEmpty) {
      await load();
    } else {
      await loadNewer(isRefresh: true);
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/surrounding/surrounding_cubit_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/surrounding/cubit/surrounding_state.dart lib/features/surrounding/cubit/surrounding_cubit.dart test/surrounding/surrounding_cubit_test.dart
git commit -m "feat(surrounding): bidirectional paginated cubit + read tracking"
```

---

## Task 5: Page — center-sliver bidirectional scroll

**Files:**
- Modify: `lib/features/surrounding/pages/surrounding_feed_page.dart` (replace)

No unit test (CustomScrollView + VisibilityDetector + getIt-backed NoteCard make a meaningful widget test disproportionately heavy and unlike the rest of this codebase). Verify via `flutter analyze` + the manual checklist in Task 6.

- [ ] **Step 1: Replace the page**

Replace the entire contents of `lib/features/surrounding/pages/surrounding_feed_page.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../cubit/surrounding_cubit.dart';
import '../cubit/surrounding_state.dart';

/// The "Surrounding" feed — Kind-1 notes broadcast by nearby devices over the
/// mesh, ordered by arrival time (`receivedAt`). Opens at the first unread note;
/// scroll up for older notes, scroll down for newer. Ephemeral (evicted daily);
/// the NoteCard bookmark keeps one forever.
class SurroundingFeedPage extends StatelessWidget {
  const SurroundingFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SurroundingCubit()..load(),
      child: const _SurroundingView(),
    );
  }
}

class _SurroundingView extends StatefulWidget {
  const _SurroundingView();

  @override
  State<_SurroundingView> createState() => _SurroundingViewState();
}

class _SurroundingViewState extends State<_SurroundingView> {
  final _scrollController = ScrollController();

  /// Anchor key for the center sliver (the unread/bottom section). Slivers
  /// before it lay out upward, so prepending older notes never shifts the
  /// visible content.
  final _centerKey = const ValueKey('surrounding-feed-center');

  /// Distance from an edge at which the next page is requested.
  static const double _loadTrigger = 240;

  final Set<String> _everVisible = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Nearing the top loads older notes; nearing the bottom loads newer notes.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final cubit = context.read<SurroundingCubit>();
    final state = cubit.state;

    if (pos.pixels <= pos.minScrollExtent + _loadTrigger) {
      if (state.hasMoreOlder && !state.isLoadingOlder) cubit.loadOlder();
    }
    if (pos.pixels >= pos.maxScrollExtent - _loadTrigger) {
      if (state.hasMoreNewer && !state.isLoadingNewer) cubit.loadNewer();
    }
  }

  /// Over-pulling past the bottom edge re-checks for notes that arrived after
  /// the feed opened.
  bool _onScrollNotification(ScrollNotification n) {
    if (n is OverscrollNotification && n.overscroll > 0) {
      final cubit = context.read<SurroundingCubit>();
      if (!cubit.state.isLoadingNewer) cubit.loadNewer(isRefresh: true);
    }
    return false;
  }

  /// Marks a note read once it has been majority-visible then leaves view.
  void _onVisibility(SurroundingNoteEntity item, VisibilityInfo info) {
    if (info.visibleFraction >= 0.5) {
      _everVisible.add(item.note.id);
    } else if (info.visibleFraction == 0 &&
        _everVisible.contains(item.note.id)) {
      context.read<SurroundingCubit>().markRead(item.receivedAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          l10n.surroundingTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: BlocBuilder<SurroundingCubit, SurroundingState>(
        builder: (context, state) {
          if (state.status == SurroundingStatus.initial ||
              state.status == SurroundingStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }
          if (state.notes.isEmpty) return const _EmptyState();
          return _buildList(context, state);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, SurroundingState state) {
    // Split at the read→unread boundary. The top section renders in the
    // pre-center sliver (reversed → grows upward); the bottom section is the
    // center sliver (grows downward).
    final top = state.notes.sublist(0, state.boundaryIndex);
    final bottom = state.notes.sublist(state.boundaryIndex);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: CustomScrollView(
            controller: _scrollController,
            center: _centerKey,
            // First unread note pinned to the top when unread notes exist;
            // otherwise anchored at the bottom like a standard chat.
            anchor: state.openedWithUnread ? 0.0 : 1.0,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _tile(top[top.length - 1 - i]),
                  childCount: top.length,
                ),
              ),
              SliverList(
                key: _centerKey,
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _tile(bottom[i]),
                  childCount: bottom.length,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 8,
                ),
              ),
            ],
          ),
        ),
        if (state.isLoadingOlder)
          const Positioned(top: 0, left: 0, right: 0, child: _EdgeSpinner()),
        if (state.isLoadingNewer)
          const Positioned(bottom: 0, left: 0, right: 0, child: _EdgeSpinner()),
      ],
    );
  }

  Widget _tile(SurroundingNoteEntity item) {
    return VisibilityDetector(
      key: ValueKey('surr-${item.note.id}'),
      onVisibilityChanged: (info) => _onVisibility(item, info),
      child: NoteCard(
        key: ValueKey(item.note.id),
        note: item.note,
        onTap: () {},
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_tethering_rounded,
              size: 56,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.surroundingEmpty,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.surroundingEmptySub,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small progress strip shown while an older/newer page is loading.
class _EdgeSpinner extends StatelessWidget {
  const _EdgeSpinner();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze the page**

Run: `flutter analyze lib/features/surrounding/`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/surrounding/pages/surrounding_feed_page.dart
git commit -m "feat(surrounding): center-sliver feed anchored at first unread"
```

---

## Task 6: Full build + analyze + regression

**Files:** none (verification only)

- [ ] **Step 1: Full codegen**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: SUCCESS, no conflicts.

- [ ] **Step 2: Analyze the whole project**

Run: `flutter analyze`
Expected: No new issues introduced by this work (pre-existing warnings elsewhere are out of scope). In particular, confirm `lib/common/locator.config.dart` compiles (the `readStore` dependency resolves).

- [ ] **Step 3: Run the full surrounding + mesh regression suite**

Run: `flutter test test/surrounding/ test/mesh/surrounding_integration_test.dart`
Expected: PASS. (Repository/integration tests early-return if the Isar core can't download — confirm the core actually loaded by the absence of the "Isar core unavailable" print before trusting a green result.)

- [ ] **Step 4: Manual verification checklist (run the app, open the Surrounding feed)**

Verify each acceptance criterion:
1. With unread notes present, the feed opens with the **oldest unread** note at the **top**; scrolling up reveals already-read notes, scrolling down reveals newer ones.
2. With everything read, the feed opens showing the newest notes at the bottom (chat-style).
3. Notes are ordered by arrival (`receivedAt`), oldest at top → newest at bottom.
4. Scroll a note out of view, leave and reopen the feed → it resumes from the first still-unread note.
5. A new mesh arrival appends at the bottom without moving the current scroll position.
6. Scrolling up near the top loads an older page (edge spinner shows); no duplicates at the seam.
7. With no surrounding notes, the empty state renders.

- [ ] **Step 5: Final commit (if any uncommitted generated files remain)**

```bash
git add -A
git commit -m "chore(surrounding): regenerate build artifacts"
```

---

## Self-Review Notes

- **Spec coverage:** read pointer (Task 1), wrapper entity (Task 2), repository pagination + boundary + mark-read (Task 3), cubit bidirectional load/older/newer + silent append on arrival (Task 4), center-sliver page with `anchor: 0.0` first-unread-at-top + VisibilityDetector mark-read + no composer (Task 5), build/analyze/regression + manual acceptance (Task 6). All spec sections map to a task.
- **Type consistency:** `SurroundingNoteEntity{note, receivedAt}`, repo methods `getBefore`/`getAfter`/`oldestUnreadReceivedAt`/`markReadUpTo`, store `lastReadReceivedAt`/`advanceTo`, cubit `load`/`loadOlder`/`loadNewer`/`markRead`, state `notes`/`boundaryIndex`/`openedWithUnread`/`hasMoreOlder`/`hasMoreNewer`/`isLoadingOlder`/`isLoadingNewer` — names are identical across all tasks.
- **No placeholders:** every code step contains complete, compilable code.
- **`getAll()` removal:** the only caller was `SurroundingCubit` (rewritten in Task 4); no other references exist.
```
