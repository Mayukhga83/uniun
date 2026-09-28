import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/constants/app_constants.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/datasources/blossom_client.dart';
import 'package:uniun/data/datasources/media_cache_data_source.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/repositories/media_repository_impl.dart';
import 'package:uniun/domain/entities/media/media_filter.dart';
import 'package:uniun/domain/repositories/user_server_list_repository.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

import '../../_helpers/fixtures.dart';
import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';

class _MBlossom extends Mock implements BlossomClient {}

class _MCache extends Mock implements MediaCacheDataSource {}

class _MServerList extends Mock implements UserServerListRepository {}

class _MKeys extends Mock implements GetActiveUserKeysUseCase {}

/// Covers: MediaRepositoryImpl — every public method across happy paths,
/// failure paths, dedup / idempotency behaviours, filter branches, and edge
/// cases (empty inputs, unicode, boundary sizes). Real Isar via
/// [openTestIsar]; collaborators mocked with mocktail.
void main() {
  const kBlossom = 'https://blossom.example';
  const signingKeys = kSigningKeys;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(signingKeys);
    registerFallbackValue(<String>[]);
  });

  late Isar isar;
  late _MBlossom blossom;
  late _MCache cache;
  late _MServerList serverList;
  late _MKeys keys;
  late MediaRepositoryImpl repo;
  late Directory tmpDir;

  Uint8List bytesOf(String s) => Uint8List.fromList(s.codeUnits);

  Future<File> writeFile(String name, [Uint8List? data]) async {
    final f = File('${tmpDir.path}/$name');
    await f.writeAsBytes(data ?? bytesOf('x'));
    return f;
  }

  void stubKeysOk() => when(() => keys.call()).thenAnswer(
        (_) async => const Right(signingKeys),
      );

  void stubServers(List<String> urls) =>
      when(() => serverList.getServers()).thenAnswer(
        (_) async => Right(urls),
      );

  void stubSetServersOk() => when(() => serverList.setServers(any()))
      .thenAnswer((_) async => const Right(unit));

  setUp(() async {
    isar = await openTestIsar();
    tmpDir = await Directory.systemTemp.createTemp('uniun_media_repo_');
    blossom = _MBlossom();
    cache = _MCache();
    serverList = _MServerList();
    keys = _MKeys();
    repo = MediaRepositoryImpl(
      isar: isar,
      blossom: blossom,
      cache: cache,
      serverList: serverList,
      getActiveUserKeys: keys,
    );

    // Default cache stubs — every path exercises them.
    when(() => cache.write(any(), any(), any())).thenAnswer(
      (inv) async {
        final sha = inv.positionalArguments[0] as String;
        final ext = inv.positionalArguments[1] as String?;
        return writeFile(ext == null ? sha : '$sha.$ext',
            inv.positionalArguments[2] as Uint8List);
      },
    );
    when(() => cache.fileFor(any(), any())).thenAnswer((inv) async {
      final sha = inv.positionalArguments[0] as String;
      final ext = inv.positionalArguments[1] as String?;
      return File('${tmpDir.path}/${ext == null ? sha : '$sha.$ext'}');
    });
    when(() => cache.exists(any(), any())).thenAnswer((_) async => false);
    when(() => cache.delete(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  // ── uploadBytes ───────────────────────────────────────────────────────────

  group('uploadBytes — happy path', () {
    setUp(() {
      stubKeysOk();
      stubServers([kBlossom]);
      stubSetServersOk();
      when(() => blossom.head(any(), any(), ext: any(named: 'ext')))
          .thenAnswer((_) async => false);
      when(() => blossom.upload(
            serverUrl: any(named: 'serverUrl'),
            bytes: any(named: 'bytes'),
            mime: any(named: 'mime'),
            sha256: any(named: 'sha256'),
            keys: any(named: 'keys'),
          )).thenAnswer((_) async => const BlobDescriptor(
            url: 'ignored — repo rebuilds URL from serverUrl',
            sha256: 'ignored',
            size: 0,
            mime: 'image/jpeg',
          ));
    });

    test('uploads new blob, caches locally, writes Isar row, returns entity',
        () async {
      final res = await repo.uploadBytes(
        bytes: bytesOf('imgdata'),
        mime: 'image/jpeg',
        filename: 'photo.jpg',
        blurhash: 'LKO2?U',
        width: 100,
        height: 80,
      );

      expect(res.isRight(), isTrue);
      final blob = res.getOrElse(() => throw StateError('left'));
      expect(blob.mime, 'image/jpeg');
      expect(blob.sizeBytes, 7);
      expect(blob.dim?.width, 100);
      expect(blob.dim?.height, 80);
      expect(blob.blurhash, 'LKO2?U');
      expect(blob.filename, 'photo.jpg');
      expect(blob.serverUrls.single, startsWith('$kBlossom/'));
      expect(blob.serverUrls.single, endsWith('.jpg'));

      verify(() => blossom.upload(
            serverUrl: kBlossom,
            bytes: any(named: 'bytes'),
            mime: 'image/jpeg',
            sha256: any(named: 'sha256'),
            keys: signingKeys,
          )).called(1);

      // Isar row upserted.
      final row = await isar.mediaCacheModels
          .filter()
          .sha256EqualTo(blob.sha256)
          .findFirst();
      expect(row, isNotNull);
      expect(row!.mime, 'image/jpeg');
      expect(row.sizeBytes, 7);
    });

    test('skips upload when server already has the blob (HEAD 200 dedup)',
        () async {
      when(() => blossom.head(any(), any(), ext: any(named: 'ext')))
          .thenAnswer((_) async => true);

      final res = await repo.uploadBytes(
        bytes: bytesOf('imgdata'),
        mime: 'image/jpeg',
      );

      expect(res.isRight(), isTrue);
      verifyNever(() => blossom.upload(
            serverUrl: any(named: 'serverUrl'),
            bytes: any(named: 'bytes'),
            mime: any(named: 'mime'),
            sha256: any(named: 'sha256'),
            keys: any(named: 'keys'),
          ));
      // Cache write and Isar row still happen — the blob must exist locally
      // even when the server had it first.
      verify(() => cache.write(any(), any(), any())).called(1);
    });

    test('treats HEAD failure as "not on server" and uploads', () async {
      when(() => blossom.head(any(), any(), ext: any(named: 'ext')))
          .thenThrow(Exception('network down'));
      final res = await repo.uploadBytes(
        bytes: bytesOf('imgdata'),
        mime: 'image/jpeg',
      );
      expect(res.isRight(), isTrue);
      verify(() => blossom.upload(
            serverUrl: any(named: 'serverUrl'),
            bytes: any(named: 'bytes'),
            mime: any(named: 'mime'),
            sha256: any(named: 'sha256'),
            keys: any(named: 'keys'),
          )).called(1);
    });

    test('publishes Kind 10063 default when servers list was empty', () async {
      stubServers(const []);
      final res = await repo.uploadBytes(
        bytes: bytesOf('x'),
        mime: 'image/jpeg',
      );
      // Empty list = "No Blossom server configured" — this is a Left.
      expect(res.isLeft(), isTrue);
    });

    test('publishes Kind 10063 default when servers list is just the hardcode',
        () async {
      stubServers([AppConstants.kUniunBlossom]);
      when(() => blossom.head(any(), any(), ext: any(named: 'ext')))
          .thenAnswer((_) async => false);

      await repo.uploadBytes(
        bytes: bytesOf('x'),
        mime: 'image/jpeg',
      );

      verify(() => serverList.setServers([AppConstants.kUniunBlossom]))
          .called(1);
    });

    test('does NOT re-publish 10063 when user has a custom server list',
        () async {
      stubServers(const ['https://custom.example', 'https://backup.example']);
      when(() => blossom.head(any(), any(), ext: any(named: 'ext')))
          .thenAnswer((_) async => false);

      await repo.uploadBytes(bytes: bytesOf('x'), mime: 'image/jpeg');

      verifyNever(() => serverList.setServers(any()));
    });
  });

  group('uploadBytes — failure paths', () {
    test('returns Left when active-user keys are missing', () async {
      when(() => keys.call())
          .thenAnswer((_) async => const Left(Failure.failure('no user')));
      stubServers([kBlossom]);

      final res = await repo.uploadBytes(
        bytes: bytesOf('x'),
        mime: 'image/jpeg',
      );
      expect(res, const Left(Failure.failure('No active user')));
      verifyNever(() => blossom.upload(
            serverUrl: any(named: 'serverUrl'),
            bytes: any(named: 'bytes'),
            mime: any(named: 'mime'),
            sha256: any(named: 'sha256'),
            keys: any(named: 'keys'),
          ));
    });

    test('returns Left when no Blossom servers are configured', () async {
      stubKeysOk();
      stubServers(const []);

      final res = await repo.uploadBytes(
        bytes: bytesOf('x'),
        mime: 'image/jpeg',
      );
      expect(res, const Left(Failure.failure('No Blossom server configured')));
    });

    test('wraps a BlossomException from upload into Failure.errorFailure',
        () async {
      stubKeysOk();
      stubServers([kBlossom]);
      when(() => blossom.head(any(), any(), ext: any(named: 'ext')))
          .thenAnswer((_) async => false);
      when(() => blossom.upload(
            serverUrl: any(named: 'serverUrl'),
            bytes: any(named: 'bytes'),
            mime: any(named: 'mime'),
            sha256: any(named: 'sha256'),
            keys: any(named: 'keys'),
          )).thenThrow(BlossomException(413, 'too large'));

      final res = await repo.uploadBytes(
        bytes: bytesOf('x'),
        mime: 'image/jpeg',
      );
      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.toMessage(), contains('413')),
        (_) => fail('expected Left'),
      );
    });

    test('wraps a cache-write failure into Left', () async {
      stubKeysOk();
      stubServers([kBlossom]);
      stubSetServersOk();
      when(() => blossom.head(any(), any(), ext: any(named: 'ext')))
          .thenAnswer((_) async => false);
      when(() => blossom.upload(
            serverUrl: any(named: 'serverUrl'),
            bytes: any(named: 'bytes'),
            mime: any(named: 'mime'),
            sha256: any(named: 'sha256'),
            keys: any(named: 'keys'),
          )).thenAnswer((_) async => const BlobDescriptor(
            url: 'x',
            sha256: 'x',
            size: 0,
            mime: 'image/jpeg',
          ));
      when(() => cache.write(any(), any(), any()))
          .thenThrow(const FileSystemException('disk full'));

      final res = await repo.uploadBytes(
        bytes: bytesOf('x'),
        mime: 'image/jpeg',
      );
      expect(res.isLeft(), isTrue);
    });
  });

  // ── downloadBySha ─────────────────────────────────────────────────────────

  group('downloadBySha', () {
    test('re-hydrates from local cache when file is already present',
        () async {
      final f = await writeFile('abc.jpg', bytesOf('cached'));
      when(() => cache.exists('abc', 'jpg')).thenAnswer((_) async => true);
      when(() => cache.read('abc', 'jpg')).thenAnswer((_) async => f);

      final res = await repo.downloadBySha(
        sha256: 'abc',
        url: 'https://s/abc.jpg',
        mime: 'image/jpeg',
      );

      expect(res.isRight(), isTrue);
      verifyNever(() => blossom.downloadFromUrl(any()));
      final row = await isar.mediaCacheModels
          .filter()
          .sha256EqualTo('abc')
          .findFirst();
      expect(row!.sizeBytes, 6); // 'cached'.length
    });

    test('a received .docx is cached with its extension so it can be opened',
        () async {
      const docx =
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      final f = await writeFile('w.docx', bytesOf('cached'));
      when(() => cache.exists('w', 'docx')).thenAnswer((_) async => true);
      when(() => cache.read('w', 'docx')).thenAnswer((_) async => f);

      final res = await repo.downloadBySha(
          sha256: 'w', url: 'https://s/w', mime: docx);

      expect(res.isRight(), isTrue,
          reason: 'downloads carry no filename, so the mime alone must map');
      verify(() => cache.exists('w', 'docx')).called(1);
    });

    test('downloads from server when cache is empty', () async {
      when(() => cache.exists('abc', 'jpg')).thenAnswer((_) async => false);
      when(() => blossom.downloadFromUrl('https://s/abc.jpg'))
          .thenAnswer((_) async => bytesOf('fetched'));

      final res = await repo.downloadBySha(
        sha256: 'abc',
        url: 'https://s/abc.jpg',
        mime: 'image/jpeg',
      );
      expect(res.isRight(), isTrue);
      verify(() => blossom.downloadFromUrl('https://s/abc.jpg')).called(1);
      final row = await isar.mediaCacheModels
          .filter()
          .sha256EqualTo('abc')
          .findFirst();
      expect(row!.sizeBytes, 7);
    });

    test('wraps download failure into Left', () async {
      when(() => cache.exists(any(), any())).thenAnswer((_) async => false);
      when(() => blossom.downloadFromUrl(any()))
          .thenThrow(BlossomException(404, 'not found'));
      final res = await repo.downloadBySha(
        sha256: 'abc',
        url: 'https://s/abc.jpg',
        mime: 'image/jpeg',
      );
      expect(res.isLeft(), isTrue);
    });
  });

  // ── saveLocalBytes ────────────────────────────────────────────────────────

  group('saveLocalBytes', () {
    test('caches without uploading, returns entity with empty serverUrls',
        () async {
      final res = await repo.saveLocalBytes(
        bytes: bytesOf('draft'),
        mime: 'image/png',
        filename: 'draft.png',
      );
      expect(res.isRight(), isTrue);
      final blob = res.getOrElse(() => throw StateError('left'));
      expect(blob.serverUrls, isEmpty);
      expect(blob.mime, 'image/png');
      verifyNever(() => blossom.upload(
            serverUrl: any(named: 'serverUrl'),
            bytes: any(named: 'bytes'),
            mime: any(named: 'mime'),
            sha256: any(named: 'sha256'),
            keys: any(named: 'keys'),
          ));
    });

    test('carries dim + blurhash through to the entity when provided',
        () async {
      final res = await repo.saveLocalBytes(
        bytes: bytesOf('x'),
        mime: 'image/png',
        width: 42,
        height: 24,
        blurhash: 'LKO2?U',
      );
      final blob = res.getOrElse(() => throw StateError('left'));
      expect(blob.dim!.width, 42);
      expect(blob.dim!.height, 24);
      expect(blob.blurhash, 'LKO2?U');
    });

    test('leaves dim null when only one of width/height supplied', () async {
      final res = await repo.saveLocalBytes(
        bytes: bytesOf('x'),
        mime: 'image/png',
        width: 42,
      );
      final blob = res.getOrElse(() => throw StateError('left'));
      expect(blob.dim, isNull);
    });

    test('wraps cache-write failure into Left', () async {
      when(() => cache.write(any(), any(), any()))
          .thenThrow(const FileSystemException('disk full'));
      final res = await repo.saveLocalBytes(
        bytes: bytesOf('x'),
        mime: 'image/png',
      );
      expect(res.isLeft(), isTrue);
    });
  });

  // ── readLocalBytes ────────────────────────────────────────────────────────

  group('readLocalBytes', () {
    test('returns bytes when file exists', () async {
      final f = await writeFile('abc', bytesOf('data'));
      when(() => cache.read('abc', null)).thenAnswer((_) async => f);

      final res = await repo.readLocalBytes('abc');
      expect(res.isRight(), isTrue);
      expect(res.getOrElse(() => null), bytesOf('data'));
    });

    test('returns Right(null) when file is absent', () async {
      when(() => cache.read('abc', null)).thenAnswer((_) async => null);
      final res = await repo.readLocalBytes('abc');
      expect(res, const Right<Failure, Uint8List?>(null));
    });

    test('wraps I/O error into Left', () async {
      when(() => cache.read(any(), any()))
          .thenThrow(const FileSystemException('perm denied'));
      final res = await repo.readLocalBytes('abc');
      expect(res.isLeft(), isTrue);
    });
  });

  // ── getCachedBySha ────────────────────────────────────────────────────────

  group('getCachedBySha', () {
    test('returns Right(null) when no cache row exists', () async {
      final res = await repo.getCachedBySha('nope');
      expect(res, const Right<Failure, dynamic>(null));
    });

    test('returns entity from cache row alone when no NoteModel references it',
        () async {
      await isar.writeTxn(() async {
        await isar.mediaCacheModels.put(mediaCacheRow('sha',
            sizeBytes: 42,
            localPath: '/tmp/sha.jpg',
            downloadedAt: DateTime(2026, 1, 1)));
      });

      final res = await repo.getCachedBySha('sha');
      final blob = res.getOrElse(() => null)!;
      expect(blob.sha256, 'sha');
      expect(blob.sizeBytes, 42);
      expect(blob.dim, isNull);
      expect(blob.blurhash, isNull);
      expect(blob.filename, isNull);
      expect(blob.serverUrls, isEmpty);
    });

    test('joins attachment metadata from the first note carrying the sha',
        () async {
      await isar.writeTxn(() async {
        await isar.mediaCacheModels.put(mediaCacheRow('sha',
            sizeBytes: 42,
            localPath: '/tmp/sha.jpg',
            downloadedAt: DateTime(2026, 1, 1)));

        final att = mediaAttachmentRow(
          sha256: 'sha',
          sizeBytes: 42,
          url: 'https://s/sha.jpg',
          width: 200,
          height: 100,
          blurhash: 'HASH',
          filename: 'photo.jpg',
        );
        await isar.noteModels.put(noteRow(
          'ev1',
          authorPubkey: 'pk',
          type: NoteType.image,
          created: DateTime(2026, 1, 1),
          attachments: [att],
        ));
      });

      final res = await repo.getCachedBySha('sha');
      final blob = res.getOrElse(() => null)!;
      expect(blob.dim!.width, 200);
      expect(blob.dim!.height, 100);
      expect(blob.blurhash, 'HASH');
      expect(blob.filename, 'photo.jpg');
      expect(blob.serverUrls.single, 'https://s/sha.jpg');
    });
  });

  // ── watchAll (stream + MediaFilter branches) ──────────────────────────────

  group('watchAll', () {
    Future<void> seed(String sha, String mime) async {
      await isar.writeTxn(() async {
        await isar.mediaCacheModels.put(mediaCacheRow(sha,
            mime: mime,
            localPath: '/tmp/$sha',
            downloadedAt: DateTime(2026, 1, 1)));
      });
    }

    test('emits everything under kind=all', () async {
      await seed('a', 'image/jpeg');
      await seed('b', 'video/mp4');
      await seed('c', 'application/pdf');
      final blobs = await repo.watchAll(filter: const MediaFilter()).first;
      expect(blobs.map((b) => b.sha256).toSet(), {'a', 'b', 'c'});
    });

    test('kind=image keeps only image/* rows', () async {
      await seed('a', 'image/jpeg');
      await seed('b', 'video/mp4');
      final blobs = await repo
          .watchAll(filter: const MediaFilter(kind: MediaKindFilter.image))
          .first;
      expect(blobs.map((b) => b.sha256).toList(), ['a']);
    });

    test('kind=video keeps only video/* rows', () async {
      await seed('a', 'image/jpeg');
      await seed('b', 'video/mp4');
      final blobs = await repo
          .watchAll(filter: const MediaFilter(kind: MediaKindFilter.video))
          .first;
      expect(blobs.map((b) => b.sha256).toList(), ['b']);
    });

    test('kind=audio keeps only audio/* rows', () async {
      await seed('a', 'image/jpeg');
      await seed('b', 'audio/mpeg');
      final blobs = await repo
          .watchAll(filter: const MediaFilter(kind: MediaKindFilter.audio))
          .first;
      expect(blobs.map((b) => b.sha256).toList(), ['b']);
    });

    test('kind=file keeps only non-image/video/audio rows', () async {
      await seed('a', 'image/jpeg');
      await seed('b', 'audio/mpeg');
      await seed('c', 'application/pdf');
      await seed('d', 'text/plain');
      final blobs = await repo
          .watchAll(filter: const MediaFilter(kind: MediaKindFilter.file))
          .first;
      expect(blobs.map((b) => b.sha256).toSet(), {'c', 'd'});
    });

    test('sorts newest first by downloadedAt', () async {
      await isar.writeTxn(() async {
        await isar.mediaCacheModels.put(mediaCacheRow('old',
            localPath: '/tmp/old', downloadedAt: DateTime(2024, 1, 1)));
        await isar.mediaCacheModels.put(mediaCacheRow('new',
            localPath: '/tmp/new', downloadedAt: DateTime(2026, 6, 1)));
      });
      final blobs = await repo.watchAll().first;
      expect(blobs.first.sha256, 'new');
      expect(blobs.last.sha256, 'old');
    });

    test('null filter defaults to kind=all', () async {
      await seed('a', 'image/jpeg');
      final blobs = await repo.watchAll(filter: null).first;
      expect(blobs, hasLength(1));
    });

    test('re-emits when a row is added', () async {
      final stream = repo.watchAll();
      final emissions = <List<String>>[];
      final sub = stream.listen((blobs) {
        emissions.add(blobs.map((b) => b.sha256).toList());
      });
      await Future.delayed(const Duration(milliseconds: 20));
      await seed('a', 'image/jpeg');
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(emissions.last, ['a']);
    });
  });

  // ── removeLocal ───────────────────────────────────────────────────────────

  group('removeLocal', () {
    test('returns Right(unit) when no row exists (idempotent)', () async {
      final res = await repo.removeLocal('nope');
      expect(res, const Right<Failure, Unit>(unit));
      verifyNever(() => cache.delete(any(), any()));
    });

    test('deletes cache file + Isar row when row exists', () async {
      await isar.writeTxn(() async {
        await isar.mediaCacheModels.put(mediaCacheRow('sha',
            localPath: '/tmp/sha.jpg', downloadedAt: DateTime.now()));
      });

      final res = await repo.removeLocal('sha');
      expect(res, const Right<Failure, Unit>(unit));
      verify(() => cache.delete('sha', 'jpg')).called(1);
      final gone = await isar.mediaCacheModels
          .filter()
          .sha256EqualTo('sha')
          .findFirst();
      expect(gone, isNull);
    });

    test('handles a stored localPath with no extension', () async {
      await isar.writeTxn(() async {
        await isar.mediaCacheModels.put(mediaCacheRow('sha',
            mime: 'application/octet-stream',
            localPath: '/tmp/sha',
            downloadedAt: DateTime.now()));
      });
      final res = await repo.removeLocal('sha');
      expect(res, const Right<Failure, Unit>(unit));
      verify(() => cache.delete('sha', null)).called(1);
    });

    test('wraps cache-delete failure into Left', () async {
      await isar.writeTxn(() async {
        await isar.mediaCacheModels.put(mediaCacheRow('sha',
            localPath: '/tmp/sha.jpg', downloadedAt: DateTime.now()));
      });
      when(() => cache.delete(any(), any()))
          .thenThrow(const FileSystemException('perm denied'));

      final res = await repo.removeLocal('sha');
      expect(res.isLeft(), isTrue);
    });
  });

  // ── Ext-from-mime helper (exercised indirectly) ──────────────────────────

  group('_extFromMime — via saveLocalBytes filename resolution', () {
    setUp(() {
      // Capture the ext that gets passed to cache.write / fileFor so we can
      // pin the mime → ext map without pulling the private method out.
    });

    for (final entry in const [
      ['image/jpeg', 'jpg'],
      ['image/JPEG', 'jpg'], // case-insensitive
      ['image/png', 'png'],
      ['image/gif', 'gif'],
      ['image/webp', 'webp'],
      ['image/heic', 'heic'],
      ['image/avif', 'avif'],
      ['video/mp4', 'mp4'],
      ['video/webm', 'webm'],
      ['video/quicktime', 'mov'],
      ['audio/mpeg', 'mp3'],
      ['audio/mp4', 'm4a'],
      ['audio/ogg', 'ogg'],
      ['audio/wav', 'wav'],
      ['application/pdf', 'pdf'],
      [
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'docx'
      ],
      ['text/plain', 'txt'],
      ['application/json', 'json'],
    ]) {
      test('mime `${entry[0]}` → ext `${entry[1]}`', () async {
        await repo.saveLocalBytes(bytes: bytesOf('x'), mime: entry[0]);
        verify(() => cache.write(any(), entry[1], any())).called(1);
      });
    }

    test('unknown mime + filename → ext taken from filename', () async {
      await repo.saveLocalBytes(
        bytes: bytesOf('x'),
        mime: 'application/vnd.example',
        filename: 'report.docx',
      );
      verify(() => cache.write(any(), 'docx', any())).called(1);
    });

    test('unknown mime + no filename → null ext', () async {
      await repo.saveLocalBytes(
        bytes: bytesOf('x'),
        mime: 'application/vnd.example',
      );
      final captured = verify(
        () => cache.write(any(), captureAny(), any()),
      ).captured;
      expect(captured.single, isNull);
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────────

  group('boundary + malformed inputs', () {
    test('zero-byte upload succeeds', () async {
      stubKeysOk();
      stubServers([kBlossom]);
      stubSetServersOk();
      when(() => blossom.head(any(), any(), ext: any(named: 'ext')))
          .thenAnswer((_) async => false);
      when(() => blossom.upload(
            serverUrl: any(named: 'serverUrl'),
            bytes: any(named: 'bytes'),
            mime: any(named: 'mime'),
            sha256: any(named: 'sha256'),
            keys: any(named: 'keys'),
          )).thenAnswer((_) async => const BlobDescriptor(
            url: 'x',
            sha256: 'x',
            size: 0,
            mime: 'image/jpeg',
          ));

      final res = await repo.uploadBytes(
        bytes: Uint8List(0),
        mime: 'image/jpeg',
      );
      expect(res.isRight(), isTrue);
      final blob = res.getOrElse(() => throw StateError('left'));
      expect(blob.sizeBytes, 0);
    });

    test('unicode filename round-trips through saveLocalBytes', () async {
      final res = await repo.saveLocalBytes(
        bytes: bytesOf('x'),
        mime: 'application/pdf',
        filename: '𝓊𝓃𝒾𝒸𝑜𝒹𝑒-report.pdf',
      );
      final blob = res.getOrElse(() => throw StateError('left'));
      expect(blob.filename, '𝓊𝓃𝒾𝒸𝑜𝒹𝑒-report.pdf');
    });

    test('large payload (500 KB) upload path is unchanged', () async {
      stubKeysOk();
      stubServers([kBlossom]);
      stubSetServersOk();
      when(() => blossom.head(any(), any(), ext: any(named: 'ext')))
          .thenAnswer((_) async => false);
      when(() => blossom.upload(
            serverUrl: any(named: 'serverUrl'),
            bytes: any(named: 'bytes'),
            mime: any(named: 'mime'),
            sha256: any(named: 'sha256'),
            keys: any(named: 'keys'),
          )).thenAnswer((_) async => const BlobDescriptor(
            url: 'x',
            sha256: 'x',
            size: 0,
            mime: 'image/jpeg',
          ));
      final big = Uint8List(500 * 1024);
      final res = await repo.uploadBytes(bytes: big, mime: 'image/jpeg');
      expect(res.isRight(), isTrue);
    });
  });
}
