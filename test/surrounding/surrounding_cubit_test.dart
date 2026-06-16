import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/error/failures.dart';
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

/// In-memory fake; `all` is kept ascending by receivedAt. `watch()` is driven
/// by a StreamController so tests can simulate a mesh arrival.
class FakeSurroundingRepo implements SurroundingNoteRepository {
  FakeSurroundingRepo(this.all, {DateTime? watermark})
      : _watermark = watermark ?? DateTime.fromMillisecondsSinceEpoch(0);
  final List<SurroundingNoteEntity> all;
  DateTime _watermark;
  DateTime? markedReadTo;
  final _cacheChanges = StreamController<void>.broadcast();

  void emitCacheChange() => _cacheChanges.add(null);
  Future<void> dispose() => _cacheChanges.close();

  @override
  Future<Either<Failure, List<SurroundingNoteEntity>>> getBefore(
      {DateTime? before, required int limit}) async {
    final list = all
        .where((e) => before == null || e.receivedAt.isBefore(before))
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)); // newest-first
    return Right(list.take(limit).toList().reversed.toList()); // ascending
  }

  @override
  Future<Either<Failure, List<SurroundingNoteEntity>>> getAfter(
      {required DateTime after,
      bool inclusive = false,
      required int limit}) async {
    final list = all
        .where((e) => inclusive
            ? !e.receivedAt.isBefore(after)
            : e.receivedAt.isAfter(after))
        .toList()
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt)); // ascending
    return Right(list.take(limit).toList());
  }

  @override
  Future<Either<Failure, DateTime?>> oldestUnreadReceivedAt() async {
    final unread = all.where((e) => e.receivedAt.isAfter(_watermark)).toList()
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    return Right(unread.isEmpty ? null : unread.first.receivedAt);
  }

  @override
  Future<Either<Failure, Unit>> markReadUpTo(DateTime receivedAt) async {
    markedReadTo = receivedAt;
    if (receivedAt.isAfter(_watermark)) _watermark = receivedAt;
    return const Right(unit);
  }

  @override
  Stream<void> watch() => _cacheChanges.stream;

  @override
  Future<Either<Failure, Unit>> promoteToSaved(String eventId) async =>
      const Right(unit);
}

void main() {
  test('load() opens on the newest page (oldest→newest within it)', () async {
    final notes = [for (var i = 1; i <= 12; i++) item('n$i', i * 100)];
    final repo = FakeSurroundingRepo(notes);
    final cubit = SurroundingCubit(repo: repo);
    await cubit.load();
    // newest 10 of n1..n12 → n3..n12, returned oldest→newest (so newest is last)
    expect(
      cubit.state.notes.map((e) => e.note.id).toList(),
      ['n3', 'n4', 'n5', 'n6', 'n7', 'n8', 'n9', 'n10', 'n11', 'n12'],
    );
    expect(cubit.state.hasMoreOlder, true);
    await cubit.close();
    await repo.dispose();
  });

  test('load() with a short page reports no more older', () async {
    final repo = FakeSurroundingRepo([item('a', 100), item('b', 200)]);
    final cubit = SurroundingCubit(repo: repo);
    await cubit.load();
    expect(cubit.state.notes.map((e) => e.note.id).toList(), ['a', 'b']);
    expect(cubit.state.hasMoreOlder, false);
    await cubit.close();
    await repo.dispose();
  });

  test('loadOlder prepends the next older page', () async {
    final notes = [for (var i = 1; i <= 12; i++) item('n$i', i * 100)];
    final repo = FakeSurroundingRepo(notes);
    final cubit = SurroundingCubit(repo: repo);
    await cubit.load();
    expect(cubit.state.notes.length, 10); // newest page n3..n12
    expect(cubit.state.notes.first.note.id, 'n3');
    expect(cubit.state.hasMoreOlder, true);
    await cubit.loadOlder();
    expect(cubit.state.notes.first.note.id, 'n1'); // n1, n2 prepended
    expect(cubit.state.notes.length, 12);
    expect(cubit.state.hasMoreOlder, false);
    await cubit.close();
    await repo.dispose();
  });

  test('loadNewer appends a newer note at the bottom', () async {
    final repo = FakeSurroundingRepo([item('a', 100), item('b', 200)]);
    final cubit = SurroundingCubit(repo: repo);
    await cubit.load();
    repo.all.add(item('c', 300));
    await cubit.loadNewer();
    expect(cubit.state.notes.map((e) => e.note.id).toList(), ['a', 'b', 'c']);
    await cubit.close();
    await repo.dispose();
  });

  test('a mesh arrival (watch event) appends at the bottom', () async {
    final repo = FakeSurroundingRepo([item('a', 100), item('b', 200)]);
    final cubit = SurroundingCubit(repo: repo);
    await cubit.load();
    expect(cubit.state.notes.map((e) => e.note.id).toList(), ['a', 'b']);

    // A new note arrives over the mesh and the cache fires its watch event.
    repo.all.add(item('c', 300));
    repo.emitCacheChange();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cubit.state.notes.map((e) => e.note.id).toList(), ['a', 'b', 'c']);
    await cubit.close();
    await repo.dispose();
  });

  test('markRead advances the watermark monotonically', () async {
    final repo = FakeSurroundingRepo([item('a', 100)]);
    final cubit = SurroundingCubit(repo: repo);
    cubit.markRead(DateTime.fromMillisecondsSinceEpoch(200));
    cubit.markRead(DateTime.fromMillisecondsSinceEpoch(100)); // ignored
    expect(repo.markedReadTo, DateTime.fromMillisecondsSinceEpoch(200));
    await cubit.close();
    await repo.dispose();
  });
}
