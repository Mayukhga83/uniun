import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:nip44/nip44.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/draft_model.dart';
import 'package:uniun/domain/entities/draft/draft_entity.dart';
import 'package:uniun/domain/repositories/draft_repository.dart';
import 'package:uniun/domain/repositories/event_queue_repository.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

/// NIP-37 expiration window. Relays drop wraps after this; users who don't
/// open the app for 90 days lose any unsynced drafts (acceptable — local Isar
/// copy survives if they're still on the original device).
const Duration _draftExpiry = Duration(days: 90);

@Injectable(as: DraftRepository)
class DraftRepositoryImpl extends DraftRepository {
  final Isar isar;
  final EventQueueRepository _eventQueue;
  final GetActiveUserKeysUseCase _getActiveUserKeys;

  DraftRepositoryImpl({
    required this.isar,
    required EventQueueRepository eventQueue,
    required GetActiveUserKeysUseCase getActiveUserKeys,
  })  : _eventQueue = eventQueue,
        _getActiveUserKeys = getActiveUserKeys;

  @override
  Future<Either<Failure, DraftEntity>> saveDraft(DraftEntity draft) async {
    try {
      final existing = await isar.draftModels
          .filter()
          .draftIdEqualTo(draft.draftId)
          .findFirst();

      final model = DraftModel()
        ..draftId = draft.draftId
        ..content = draft.content
        ..rootEventId = draft.rootEventId
        ..replyToEventId = draft.replyToEventId
        ..eTagRefs = draft.eTagRefs
        ..pTagRefs = draft.pTagRefs
        ..tTags = draft.tTags
        ..createdAt = draft.createdAt
        ..updatedAt = draft.updatedAt
        ..lastSyncedCreatedAt = existing?.lastSyncedCreatedAt;

      await isar.writeTxn(() async {
        if (existing != null) model.id = existing.id;
        await isar.draftModels.put(model);
      });

      // Await the publish so it's durably enqueued before we return — but
      // never let a publish failure surface as a save failure. Local Isar is
      // the source of truth; the relay is best-effort sync.
      await _publishDraftWrap(model);

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DraftEntity>>> getDrafts() async {
    try {
      final drafts =
          await isar.draftModels.where().sortByUpdatedAtDesc().findAll();
      return Right(drafts.map((d) => d.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DraftEntity>> getDraftById(String draftId) async {
    try {
      final draft =
          await isar.draftModels.filter().draftIdEqualTo(draftId).findFirst();
      if (draft == null) {
        return const Left(Failure.notFoundFailure('Draft not found'));
      }
      return Right(draft.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDraft(String draftId) async {
    try {
      await isar.writeTxn(() async {
        await isar.draftModels.filter().draftIdEqualTo(draftId).deleteAll();
      });
      // NIP-37 deletion signal: publish a Kind 31234 with empty content under
      // the same `d` tag. Receivers drop their local row. Same suppression
      // policy as saveDraft — publish failures don't roll back the local
      // delete.
      await _publishDraftDeletion(draftId);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  // ── Outbound NIP-37 wraps ─────────────────────────────────────────────────

  /// Builds, signs, and enqueues a Kind 31234 wrap carrying the encrypted
  /// inner draft event. Idempotent — re-saving the same draft replaces the
  /// previous relay-side copy because Kind 31234 is parameterized replaceable
  /// keyed on `["d", draftId]`. Swallows all errors; the local Isar write is
  /// authoritative and the relay is best-effort sync.
  Future<void> _publishDraftWrap(DraftModel m) async {
    try {
    final keysResult = await _getActiveUserKeys.call();
    final keys = keysResult.fold((_) => null, (k) => k);
    if (keys == null) return;

    final innerEvent = <String, dynamic>{
      'kind': kNoteKind,
      'pubkey': keys.pubkeyHex,
      'created_at': m.updatedAt.millisecondsSinceEpoch ~/ 1000,
      'tags': [
        if (m.rootEventId != null) ['e', m.rootEventId!, '', 'root'],
        if (m.replyToEventId != null) ['e', m.replyToEventId!, '', 'reply'],
        for (final e in m.eTagRefs)
          if (e != m.rootEventId && e != m.replyToEventId)
            ['e', e, '', 'mention'],
        for (final p in m.pTagRefs) ['p', p],
        for (final t in m.tTags) ['t', t],
      ],
      'content': m.content,
    };

    final encrypted = await Nip44.encryptMessage(
      jsonEncode(innerEvent),
      keys.privkeyHex,
      keys.pubkeyHex,
    );

    await _enqueueWrap(
      keys: keys,
      draftId: m.draftId,
      encryptedContent: encrypted,
    );
    } catch (_) {
      // Suppress — local Isar write already succeeded.
    }
  }

  /// NIP-37 deletion: same `d` tag, empty content. Relay replaces the previous
  /// row; receivers see empty content and drop the local draft. Errors
  /// swallowed for the same reason as [_publishDraftWrap].
  Future<void> _publishDraftDeletion(String draftId) async {
    try {
      final keysResult = await _getActiveUserKeys.call();
      final keys = keysResult.fold((_) => null, (k) => k);
      if (keys == null) return;
      await _enqueueWrap(
        keys: keys,
        draftId: draftId,
        encryptedContent: '',
      );
    } catch (_) {
      // Suppress — local Isar delete already succeeded.
    }
  }

  Future<void> _enqueueWrap({
    required UserSigningKeys keys,
    required String draftId,
    required String encryptedContent,
  }) async {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expireSec =
        DateTime.now().add(_draftExpiry).millisecondsSinceEpoch ~/ 1000;
    final tags = <List<String>>[
      ['d', draftId],
      ['k', kNoteKind.toString()],
      ['expiration', expireSec.toString()],
    ];

    final event = Event.from(
      privkey: keys.privkeyHex,
      kind: kDraftWrapKind,
      content: encryptedContent,
      tags: tags,
      createdAt: nowSec,
    );

    // Full signed JSON goes into EventQueueModel.content because the shaped
    // serializer in event_queue_model.dart can't emit d/k/expiration tags.
    // Kind 31234 is in _rawPassthroughKinds so the outbound pump uses
    // toRawRelayMessage() instead of toSerializedRelayMessage().
    final fullJson = jsonEncode({
      'id': event.id,
      'pubkey': event.pubkey,
      'created_at': event.createdAt,
      'kind': event.kind,
      'tags': tags,
      'content': event.content,
      'sig': event.sig,
    });

    await _eventQueue.enqueueSignedEvent(
      eventId: event.id,
      authorPubkey: event.pubkey,
      sig: event.sig,
      kind: kDraftWrapKind,
      eTagRefs: const [],
      pTagRefs: const [],
      tTags: const [],
      content: fullJson,
      created: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }
}

