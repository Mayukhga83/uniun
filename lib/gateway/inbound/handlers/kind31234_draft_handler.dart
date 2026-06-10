import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:nip44/nip44.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/draft_model.dart';
import 'package:uniun/gateway/inbound/event_parser.dart';
import 'package:uniun/gateway/inbound/kind_handler.dart';

/// NIP-37 — encrypted draft wrap (Kind 31234).
///
/// Only events authored by the active user are applied. Last-write-wins by
/// `created_at` against [DraftModel.lastSyncedCreatedAt]: an older wrap is
/// ignored, a newer one replaces the local row. Empty `content` is the
/// NIP-37 deletion signal — local row is deleted.
class Kind31234DraftHandler implements KindHandler {
  Kind31234DraftHandler({
    required this.activePubkey,
    required this.activePrivkey,
  });

  /// Active user's hex pubkey. Null → no logged-in user, handler is a no-op.
  final String? activePubkey;

  /// Active user's hex privkey. Null → cannot decrypt, handler is a no-op.
  final String? activePrivkey;

  @override
  Set<int> get kinds => const {kDraftWrapKind};

  @override
  Future<void> handle(Map<String, dynamic> event, Isar isar) async {
    final eventId = event['id'] as String?;
    final pubkey = event['pubkey'] as String?;
    final createdAtSec = event['created_at'] as int?;
    final content = event['content'] as String?;
    final tags = (event['tags'] as List?) ?? const [];
    if (eventId == null ||
        pubkey == null ||
        createdAtSec == null ||
        content == null ||
        activePubkey == null ||
        activePrivkey == null) {
      return;
    }
    if (pubkey != activePubkey) return;

    final draftId = _firstTagValue(tags, 'd');
    if (draftId == null) return;

    final incomingCreatedAt = EventParser.dateTimeFromSec(createdAtSec);

    final existing =
        await isar.draftModels.filter().draftIdEqualTo(draftId).findFirst();
    final lastSeen = existing?.lastSyncedCreatedAt;
    if (lastSeen != null && !incomingCreatedAt.isAfter(lastSeen)) return;

    // Empty content → NIP-37 deletion signal.
    if (content.isEmpty) {
      if (existing == null) return;
      await isar.writeTxn(() async {
        await isar.draftModels.delete(existing.id);
      });
      return;
    }

    // Decrypt + parse inner draft event.
    Map<String, dynamic> inner;
    try {
      final plain = await Nip44.decryptMessage(
        content,
        activePrivkey!,
        activePubkey!,
      );
      inner = jsonDecode(plain) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final innerContent = (inner['content'] as String?) ?? '';
    final innerTags = (inner['tags'] as List?) ?? const [];
    final eTagRefs = <String>[];
    final pTagRefs = <String>[];
    final tTags = <String>[];
    String? rootEventId;
    String? replyToEventId;
    for (final raw in innerTags) {
      if (raw is! List || raw.isEmpty) continue;
      final name = raw[0];
      if (name == 'e' && raw.length >= 2) {
        final id = raw[1] as String;
        final marker = raw.length >= 4 ? raw[3] as String? : null;
        if (marker == 'root') rootEventId = id;
        if (marker == 'reply') replyToEventId = id;
        eTagRefs.add(id);
      } else if (name == 'p' && raw.length >= 2) {
        pTagRefs.add(raw[1] as String);
      } else if (name == 't' && raw.length >= 2) {
        tTags.add(raw[1] as String);
      }
    }

    try {
      await isar.writeTxn(() async {
        final row = existing ?? DraftModel();
        row.draftId = draftId;
        row.content = innerContent;
        row.rootEventId = rootEventId;
        row.replyToEventId = replyToEventId;
        row.eTagRefs = eTagRefs;
        row.pTagRefs = pTagRefs;
        row.tTags = tTags;
        // Preserve original local createdAt if we already have the row.
        row.createdAt = existing?.createdAt ?? incomingCreatedAt;
        row.updatedAt = incomingCreatedAt;
        row.lastSyncedCreatedAt = incomingCreatedAt;
        row.lastSyncedEventId = eventId;
        await isar.draftModels.put(row);
      });
    } catch (_) {
      return;
    }
  }

  String? _firstTagValue(List rawTags, String name) {
    for (final raw in rawTags) {
      if (raw is! List || raw.length < 2) continue;
      if (raw[0] == name) return raw[1] as String?;
    }
    return null;
  }
}
