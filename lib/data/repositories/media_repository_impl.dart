import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/datasources/blossom_client.dart';
import 'package:uniun/data/datasources/media_cache_data_source.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/notes/media_attachment.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/core/constants/app_constants.dart';
import 'package:uniun/domain/entities/media/media_blob_entity.dart';
import 'package:uniun/domain/entities/media/media_dim.dart';
import 'package:uniun/domain/entities/media/media_filter.dart';
import 'package:uniun/domain/repositories/media_repository.dart';
import 'package:uniun/domain/repositories/user_server_list_repository.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

@Injectable(as: MediaRepository)
class MediaRepositoryImpl extends MediaRepository {
  MediaRepositoryImpl({
    required this.isar,
    required BlossomClient blossom,
    required MediaCacheDataSource cache,
    required UserServerListRepository serverList,
    required GetActiveUserKeysUseCase getActiveUserKeys,
  })  : _blossom = blossom,
        _cache = cache,
        _serverList = serverList,
        _getActiveUserKeys = getActiveUserKeys;

  final Isar isar;
  final BlossomClient _blossom;
  final MediaCacheDataSource _cache;
  final UserServerListRepository _serverList;
  final GetActiveUserKeysUseCase _getActiveUserKeys;

  @override
  Future<Either<Failure, MediaBlobEntity>> uploadBytes({
    required Uint8List bytes,
    required String mime,
    String? filename,
    String? blurhash,
    int? width,
    int? height,
  }) async {
    try {
      final keysResult = await _getActiveUserKeys.call();
      final keys = keysResult.fold((_) => null, (k) => k);
      if (keys == null) {
        return const Left(Failure.failure('No active user'));
      }

      final sha256 = crypto.sha256.convert(bytes).toString();
      final ext = _extFromMime(mime, filename);

      final serversResult = await _serverList.getServers();
      final servers = serversResult.fold((_) => <String>[], (s) => s);
      if (servers.isEmpty) {
        return const Left(Failure.failure('No Blossom server configured'));
      }
      final primary = servers.first;

      var serverHas = false;
      try {
        serverHas = await _blossom.head(primary, sha256, ext: ext);
      } catch (_) {
        serverHas = false;
      }

      // Build the public URL from our HTTP base. Khatru's `descriptor.url`
      // uses the relay's `wss://` URL — unusable for HTTP fetch.
      final String publicUrl =
          '$primary/$sha256${ext != null ? '.$ext' : ''}';
      if (!serverHas) {
        await _blossom.upload(
          serverUrl: primary,
          bytes: bytes,
          mime: mime,
          sha256: sha256,
          keys: keys,
        );
      }

      await _cache.write(sha256, ext, bytes);
      final localFile = await _cache.fileFor(sha256, ext);

      // Persist Kind 10063 default once. `getServers` returns the
      // hardcoded default when nothing is stored — only publish when the
      // user has no explicit configuration yet.
      final stored = await _serverList.getServers();
      final shouldPublish = stored.fold(
        (_) => true,
        (urls) => urls.isEmpty ||
            (urls.length == 1 && urls.first == AppConstants.kUniunBlossom),
      );
      if (shouldPublish) {
        await _serverList.setServers([primary]);
      }

      final downloadedAt = DateTime.now();
      await _upsertCache(
        sha256: sha256,
        localPath: localFile.path,
        downloadedAt: downloadedAt,
        mime: mime,
        sizeBytes: bytes.length,
      );

      return Right(MediaBlobEntity(
        sha256: sha256,
        mime: mime,
        sizeBytes: bytes.length,
        dim: (width != null && height != null)
            ? MediaDim(width: width, height: height)
            : null,
        blurhash: blurhash,
        filename: filename,
        serverUrls: [publicUrl],
        localPath: localFile.path,
        downloadedAt: downloadedAt,
      ));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MediaBlobEntity>> downloadBySha({
    required String sha256,
    required String url,
    required String mime,
  }) async {
    try {
      final ext = _extFromMime(mime, null);

      // Cached already → just upsert the cache row (e.g. after manual removal
      // followed by re-tap on a still-present file).
      if (await _cache.exists(sha256, ext)) {
        final f = await _cache.read(sha256, ext);
        if (f != null) {
          final downloadedAt = DateTime.now();
          final size = await f.length();
          await _upsertCache(
            sha256: sha256,
            localPath: f.path,
            downloadedAt: downloadedAt,
            mime: mime,
            sizeBytes: size,
          );
          return Right(MediaBlobEntity(
            sha256: sha256,
            mime: mime,
            sizeBytes: size,
            serverUrls: [url],
            localPath: f.path,
            downloadedAt: downloadedAt,
          ));
        }
      }

      final bytes = await _blossom.downloadFromUrl(url);
      await _cache.write(sha256, ext, bytes);
      final localFile = await _cache.fileFor(sha256, ext);
      final downloadedAt = DateTime.now();
      await _upsertCache(
        sha256: sha256,
        localPath: localFile.path,
        downloadedAt: downloadedAt,
        mime: mime,
        sizeBytes: bytes.length,
      );

      return Right(MediaBlobEntity(
        sha256: sha256,
        mime: mime,
        sizeBytes: bytes.length,
        serverUrls: [url],
        localPath: localFile.path,
        downloadedAt: downloadedAt,
      ));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MediaBlobEntity>> saveLocalBytes({
    required Uint8List bytes,
    required String mime,
    String? filename,
    String? blurhash,
    int? width,
    int? height,
  }) async {
    try {
      final sha256 = crypto.sha256.convert(bytes).toString();
      final ext = _extFromMime(mime, filename);

      await _cache.write(sha256, ext, bytes);
      final localFile = await _cache.fileFor(sha256, ext);

      final downloadedAt = DateTime.now();
      await _upsertCache(
        sha256: sha256,
        localPath: localFile.path,
        downloadedAt: downloadedAt,
        mime: mime,
        sizeBytes: bytes.length,
      );

      return Right(MediaBlobEntity(
        sha256: sha256,
        mime: mime,
        sizeBytes: bytes.length,
        dim: (width != null && height != null)
            ? MediaDim(width: width, height: height)
            : null,
        blurhash: blurhash,
        filename: filename,
        serverUrls: const [], // local-only until published
        localPath: localFile.path,
        downloadedAt: downloadedAt,
      ));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List?>> readLocalBytes(String sha256) async {
    try {
      final f = await _cache.read(sha256, null);
      if (f == null) return const Right(null);
      return Right(await f.readAsBytes());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MediaBlobEntity?>> getCachedBySha(String sha256) async {
    try {
      final row = await isar.mediaCacheModels
          .filter()
          .sha256EqualTo(sha256)
          .findFirst();
      if (row == null) return const Right(null);

      // Look up the first NoteModel carrying this sha to recover dim /
      // blurhash / filename / url for the detail page. The mime + size
      // come straight from the cache row so they're correct even before
      // any note exists (e.g. mid-compose after upload).
      MediaAttachment? attachment;
      final notes =
          await isar.noteModels.filter().hasMediaEqualTo(true).findAll();
      for (final n in notes) {
        for (final a in n.attachments) {
          if (a.sha256 == sha256) {
            attachment = a;
            break;
          }
        }
        if (attachment != null) break;
      }

      return Right(MediaBlobEntity(
        sha256: row.sha256,
        mime: row.mime,
        sizeBytes: row.sizeBytes,
        dim: (attachment?.width != null && attachment?.height != null)
            ? MediaDim(
                width: attachment!.width!,
                height: attachment.height!,
              )
            : null,
        blurhash: attachment?.blurhash,
        filename: attachment?.filename,
        serverUrls:
            attachment?.url != null ? [attachment!.url!] : const [],
        localPath: row.localPath,
        downloadedAt: row.downloadedAt,
      ));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Stream<List<MediaBlobEntity>> watchAll({MediaFilter? filter}) {
    final f = filter ?? const MediaFilter();
    // The cache row carries every field the gallery tile actually renders
    // (mime, sizeBytes, localPath, downloadedAt). The rich attachment
    // fields (dim / blurhash / filename / serverUrls) aren't read by the
    // gallery — they only matter on the detail page, which fetches them
    // via `getCachedBySha`. So this stream skips the NoteModel scan.
    return isar.mediaCacheModels
        .where()
        .sortByDownloadedAtDesc()
        .watch(fireImmediately: true)
        .map((rows) {
      final out = <MediaBlobEntity>[];
      for (final r in rows) {
        final entity = MediaBlobEntity(
          sha256: r.sha256,
          mime: r.mime,
          sizeBytes: r.sizeBytes,
          serverUrls: const [],
          localPath: r.localPath,
          downloadedAt: r.downloadedAt,
        );
        if (!_matches(entity, f)) continue;
        out.add(entity);
      }
      return out;
    });
  }

  @override
  Future<Either<Failure, Unit>> removeLocal(String sha256) async {
    try {
      final row = await isar.mediaCacheModels
          .filter()
          .sha256EqualTo(sha256)
          .findFirst();
      if (row == null) return const Right(unit);
      final ext = p.extension(row.localPath).replaceFirst('.', '');
      await _cache.delete(sha256, ext.isEmpty ? null : ext);
      await isar.writeTxn(() async {
        await isar.mediaCacheModels.delete(row.id);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────

  Future<void> _upsertCache({
    required String sha256,
    required String localPath,
    required DateTime downloadedAt,
    required String mime,
    required int sizeBytes,
  }) async {
    await isar.writeTxn(() async {
      final existing = await isar.mediaCacheModels
          .filter()
          .sha256EqualTo(sha256)
          .findFirst();
      final row = existing ?? MediaCacheModel();
      row.sha256 = sha256;
      row.localPath = localPath;
      row.downloadedAt = downloadedAt;
      row.mime = mime;
      row.sizeBytes = sizeBytes;
      await isar.mediaCacheModels.put(row);
    });
  }

  bool _matches(MediaBlobEntity e, MediaFilter f) {
    switch (f.kind) {
      case MediaKindFilter.all:
        return true;
      case MediaKindFilter.image:
        return e.mime.startsWith('image/');
      case MediaKindFilter.video:
        return e.mime.startsWith('video/');
      case MediaKindFilter.audio:
        return e.mime.startsWith('audio/');
      case MediaKindFilter.file:
        return !e.mime.startsWith('image/') &&
            !e.mime.startsWith('video/') &&
            !e.mime.startsWith('audio/');
    }
  }

  String? _extFromMime(String mime, String? filename) {
    final fromMime = _mimeToExt[mime.toLowerCase()];
    if (fromMime != null) return fromMime;
    if (filename != null) {
      final ext = p.extension(filename);
      if (ext.isNotEmpty) return ext.replaceFirst('.', '');
    }
    return null;
  }

  static const Map<String, String> _mimeToExt = {
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png',
    'image/gif': 'gif',
    'image/webp': 'webp',
    'image/heic': 'heic',
    'image/avif': 'avif',
    'video/mp4': 'mp4',
    'video/webm': 'webm',
    'video/quicktime': 'mov',
    'audio/mpeg': 'mp3',
    'audio/mp4': 'm4a',
    'audio/ogg': 'ogg',
    'audio/wav': 'wav',
    'application/pdf': 'pdf',
    // Shiv can cite a received .docx; without an extension the OS has no way
    // to tell which app should open the cached file.
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        'docx',
    'text/plain': 'txt',
    'application/json': 'json',
  };
}

