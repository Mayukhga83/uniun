import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/datasources/isar_schemas.dart';
import 'package:uniun/data/datasources/surrounding_read_state_store.dart';
import 'package:uniun/data/models/surrounding_note_model.dart';
import 'package:uniun/data/repositories/surrounding_note_repository_impl.dart';
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';

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

  List<String> idsOf(Either<Failure, List<SurroundingNoteEntity>> e) =>
      e.getOrElse(() => <SurroundingNoteEntity>[]).map((x) => x.note.id).toList();

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
    final got = idsOf(await repo.getAfter(
        after: DateTime.fromMillisecondsSinceEpoch(100), limit: 10));
    expect(got, ['b', 'c']);
  });

  test('getAfter inclusive includes the cursor note', () async {
    if (!isarReady) return;
    final isar = await openIsar('afterinc');
    addTearDown(() async => isar.close());
    await isar.writeTxn(() async {
      await isar.surroundingNoteModels.putAll([note('a', 100), note('b', 200)]);
    });
    final repo = await makeRepo(isar);
    final got = idsOf(await repo.getAfter(
        after: DateTime.fromMillisecondsSinceEpoch(100),
        inclusive: true,
        limit: 10));
    expect(got, ['a', 'b']);
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
    final got = idsOf(await repo.getBefore(
        before: DateTime.fromMillisecondsSinceEpoch(400), limit: 2));
    // newest two below 400 → b(200), c(300), returned ascending
    expect(got, ['b', 'c']);
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
    final got = idsOf(await repo.getBefore(before: null, limit: 2));
    // newest two → b(200), c(300), ascending
    expect(got, ['b', 'c']);
  });

  test('orders by receivedAt, not author created', () async {
    if (!isarReady) return;
    final isar = await openIsar('byreceived');
    addTearDown(() async => isar.close());
    // 'x' authored later (created 300) but received first (receivedAt 100);
    // 'y' authored earlier (created 100) but received later (receivedAt 200).
    final x = note('x', 100)..created = DateTime.fromMillisecondsSinceEpoch(300);
    final y = note('y', 200)..created = DateTime.fromMillisecondsSinceEpoch(100);
    await isar.writeTxn(() async {
      await isar.surroundingNoteModels.putAll([x, y]);
    });
    final repo = await makeRepo(isar);
    final got = idsOf(await repo.getAfter(
        after: DateTime.fromMillisecondsSinceEpoch(0), limit: 10));
    // Ascending by receivedAt → x(100) then y(200), regardless of created.
    expect(got, ['x', 'y']);
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
    final got =
        (await repo.oldestUnreadReceivedAt()).getOrElse(() => null);
    expect(got, DateTime.fromMillisecondsSinceEpoch(200));
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
    final got =
        (await repo.oldestUnreadReceivedAt()).getOrElse(() => null);
    expect(got, isNull);
  });
}
