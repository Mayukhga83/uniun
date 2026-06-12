import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

part 'event_queue_model.g.dart';

/// Durable outbound event queue. Each row represents one signed Nostr event
/// that needs to be published to one or more relays.
///
/// [id] is the Isar autoincrement integer — used as the ordered cursor by
/// every [WebSocketService] so each connection tracks its own send position
/// independently via [WebSocketService._lastSentQueueId].
///
/// An entry is eligible for dequeue when:
///   sentCount >= number of currently connected write relays
///   AND enqueuedAt < now - 30 minutes
/// Kinds used by the Marmot private channel protocol.
const _privateChannelKinds = {9002, 9021, 9022, 9023, 9024, 9025};

/// Superset of [_privateChannelKinds] plus other kinds whose full signed event
/// JSON is stored in [EventQueueModel.content] and sent to the relay as-is via
/// [toRawRelayMessage] — needed for tag shapes the shaped serializer cannot
/// produce. NIP-37 draft wraps (`d` / `k` / `expiration` tags) join this set.
const _rawPassthroughKinds = {..._privateChannelKinds, 31234};

@Collection(ignore: {'copyWith'})
@Name('EventQueue')
class EventQueueModel {
  Id id = Isar.autoIncrement;

  /// Nostr event ID (SHA256 hex) — unique per event.
  @Index(unique: true)
  late String eventId;

  /// Signed event payload stored in structured form.
  /// WebSocketService serializes this to the relay wire format at send time.
  late String authorPubkey;
  late String sig;
  late String content;
  late int kind;
  late List<String> eTagRefs;
  String? rootEventId;
  String? replyToEventId;
  late List<String> pTagRefs;
  late List<String> tTags;
  late DateTime created;

  /// NIP-18 quote info — re-emitted on the wire so the broadcast event
  /// hashes back to [eventId] (sig validation depends on it).
  String? quoteEventId;
  String? quoteAuthorPubkey;
  int? quoteKind;

  /// Number of write-relay connections that have received ["OK", id, true].
  /// Incremented atomically by each WebSocketService on successful ACK.
  late int sentCount = 0;

  /// When this event was enqueued. Used for the 30-minute dequeue gate.
  late DateTime enqueuedAt;
}

/// Tag reconstruction order (must match the order callers use when signing,
/// otherwise the re-serialized event hash will not match [eventId]):
///   1. root e-tag (NIP-10)
///   2. reply e-tag (NIP-10)
///   3. mention e-tags (remaining eTagRefs)
///   4. p-tags
///   5. t-tags
///   6. q-tag (NIP-18 share/quote, optional)
///   7. k-tag (kind of the quoted event, optional)
extension EventQueueModelExtension on EventQueueModel {
  /// Populates this queue row from a data-layer [NoteModel].
  EventQueueModel populateFromNoteModel(NoteModel note) {
    eventId = note.eventId;
    authorPubkey = note.authorPubkey;
    sig = note.sig;
    content = note.content;
    kind = 1;
    eTagRefs = List<String>.from(note.eTagRefs);
    rootEventId = note.rootEventId;
    replyToEventId = note.replyToEventId;
    pTagRefs = List<String>.from(note.pTagRefs);
    tTags = List<String>.from(note.tTags);
    created = note.created;
    sentCount = 0;
    enqueuedAt = DateTime.now();
    return this;
  }

  /// Populates this queue row from a domain-layer [NoteEntity].
  ///
  /// NoteEntity does not carry root/reply threading markers, so those remain
  /// null and all eTagRefs are emitted as mention tags.
  EventQueueModel populateFromNoteEntity(NoteEntity note) {
    eventId = note.id;
    authorPubkey = note.authorPubkey;
    sig = note.sig;
    content = note.content;
    kind = 1;
    eTagRefs = List<String>.from(note.eTagRefs);
    rootEventId = null;
    replyToEventId = null;
    pTagRefs = List<String>.from(note.pTagRefs);
    tTags = List<String>.from(note.tTags);
    created = note.created;
    sentCount = 0;
    enqueuedAt = DateTime.now();
    return this;
  }

  /// Relay wire message: ["EVENT", {signed-event-json}]
  String toSerializedRelayMessage() {
    final tags = <List<String>>[
      if (rootEventId != null) ['e', rootEventId!, '', 'root'],
      if (replyToEventId != null) ['e', replyToEventId!, '', 'reply'],
      for (final ref in eTagRefs)
        if (ref != rootEventId && ref != replyToEventId)
          ['e', ref, '', 'mention'],
      for (final p in pTagRefs) ['p', p],
      for (final t in tTags) ['t', t],
      if (quoteEventId != null)
        ['q', quoteEventId!, '', quoteAuthorPubkey ?? ''],
      if (quoteKind != null) ['k', quoteKind!.toString()],
    ];

    return jsonEncode([
      'EVENT',
      <String, dynamic>{
        'id': eventId,
        'pubkey': authorPubkey,
        'created_at': created.millisecondsSinceEpoch ~/ 1000,
        'kind': kind,
        'tags': tags,
        'content': content,
        'sig': sig,
      },
    ]);
  }
}

extension EventQueueRawPassthroughExt on EventQueueModel {
  /// True only for Marmot private-channel events. Used by the routing strategy
  /// that extracts the `h` tag — drafts must NOT match here.
  bool get isPrivateChannelEvent => _privateChannelKinds.contains(kind);

  /// True for any kind that stores its full signed event JSON in [content] and
  /// must be sent to the relay as-is via [toRawRelayMessage].
  bool get isRawPassthroughEvent => _rawPassthroughKinds.contains(kind);

  /// Converts this entry to the relay wire format `["EVENT", {signed-event}]`.
  ///
  /// Requires that [content] holds the full signed event JSON, as produced by
  /// `jsonEncode(event.toJson())` from nostr_core_dart.
  String toRawRelayMessage() {
    return jsonEncode(['EVENT', jsonDecode(content)]);
  }
}
