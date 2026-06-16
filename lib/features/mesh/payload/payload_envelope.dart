import 'dart:convert';
import 'dart:typed_data';

import '../mesh_constants.dart';

/// Application-layer messages carried over any `MeshLink`, independent of
/// transport. Wire format: one UTF-8 JSON object `{"v":1,"t":<type>,...}` per
/// link message. Three kinds ride the same framing:
///
/// - [HelloMessage] — the signed-nonce identity proof (decides peer mode).
/// - [EventMessage] — a single Nostr event (broadcast / mesh relay / synced row).
/// - [SyncMessage]  — the same-identity reconciliation control protocol.
///
/// [decode] is tolerant: malformed, wrong-version, or unknown-type bytes return
/// null so callers drop them rather than throw.
sealed class MeshMessage {
  const MeshMessage();

  static const int version = 1;

  Map<String, dynamic> toJson();

  /// Encodes to the bytes sent over a `MeshLink`.
  Uint8List encode() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  /// Decodes one `MeshLink` message; null on malformed / unknown input.
  static MeshMessage? decode(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['v'] != version) return null;
      return switch (decoded['t']) {
        'hello' => HelloMessage.fromJson(decoded),
        'event' => EventMessage.fromJson(decoded),
        'sync' => SyncMessage.fromJson(decoded),
        'enc' => EncryptedMessage.fromJson(decoded),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}

/// One step of the mutual signed-nonce identity proof. Each side sends its claimed
/// [pubkey] plus a fresh [challenge] it wants the peer to sign, and (once it has
/// received the peer's challenge) a [proof]: a signed Nostr event whose content
/// carries that challenge. The receiver verifies the proof's signature, that the
/// event's pubkey equals the claimed [pubkey], and that the signed nonce matches
/// the challenge it issued — then compares the pubkey to its own to pick the mode.
final class HelloMessage extends MeshMessage {
  const HelloMessage({required this.pubkey, this.challenge, this.proof});

  /// Claimed Nostr pubkey (hex) of the sender.
  final String pubkey;

  /// Fresh random nonce the sender wants the peer to sign back. Null when only
  /// answering a peer's challenge.
  final String? challenge;

  /// JSON of a signed Nostr event proving the sender controls [pubkey] by signing
  /// the peer's previously-issued challenge. Null in the opening message.
  final Map<String, dynamic>? proof;

  @override
  Map<String, dynamic> toJson() => {
        'v': MeshMessage.version,
        't': 'hello',
        'pk': pubkey,
        if (challenge != null) 'ch': challenge,
        if (proof != null) 'pf': proof,
      };

  factory HelloMessage.fromJson(Map<String, dynamic> j) => HelloMessage(
        pubkey: j['pk'] as String,
        challenge: j['ch'] as String?,
        proof: (j['pf'] as Map?)?.cast<String, dynamic>(),
      );
}

/// A single Nostr event (raw `{id,pubkey,created_at,kind,tags,content,sig}`),
/// used for surrounding broadcast, mesh relay, and as the row payload in sync.
final class EventMessage extends MeshMessage {
  const EventMessage(this.event, {this.ttl = kMeshMaxTtl});

  final Map<String, dynamic> event;

  /// Remaining multi-hop forwards (see [kMeshMaxTtl]). The sync row payload ignores
  /// it; only the gossip relay ([MeshRouter]) reads it.
  final int ttl;

  @override
  Map<String, dynamic> toJson() => {
        'v': MeshMessage.version,
        't': 'event',
        'e': event,
        'ttl': ttl,
      };

  // An absent ttl (a peer that doesn't gossip, e.g. a sync row) is treated as
  // terminal — stored but never relayed.
  factory EventMessage.fromJson(Map<String, dynamic> j) => EventMessage(
        (j['e'] as Map).cast<String, dynamic>(),
        ttl: (j['ttl'] as int?) ?? 0,
      );
}

/// An AEAD-sealed inner [MeshMessage], used only on the **same-identity** channel so
/// the trusted reconciliation (which carries decrypted DM/profile rows) is never
/// cleartext on the wire. [payload] is `nonce || ciphertext || mac` from
/// `SameIdentityCipher.seal`; the receiver opens it and decodes the inner message.
final class EncryptedMessage extends MeshMessage {
  const EncryptedMessage(this.payload);

  final Uint8List payload;

  @override
  Map<String, dynamic> toJson() => {
        'v': MeshMessage.version,
        't': 'enc',
        'p': base64Encode(payload),
      };

  factory EncryptedMessage.fromJson(Map<String, dynamic> j) =>
      EncryptedMessage(base64Decode(j['p'] as String));
}

/// One operation of the per-scope same-identity reconciliation (v1 id-list diff,
/// later upgraded to NIP-77 Negentropy behind the same engine).
enum SyncOp {
  /// "Here are the keys I hold for [scope]."
  have,

  /// "Send me these keys I'm missing."
  need,

  /// "Here are the serialized rows you asked for."
  rows,

  /// "I have nothing more for [scope]."
  done,
}

/// A reconciliation control message for one collection [scope].
final class SyncMessage extends MeshMessage {
  const SyncMessage({
    required this.scope,
    required this.op,
    this.ids = const [],
    this.rows = const [],
  });

  /// Collection scope key (e.g. 'note', 'savedNote', 'profile', 'deletedNote').
  final String scope;
  final SyncOp op;

  /// Item keys, for [SyncOp.have] / [SyncOp.need].
  final List<String> ids;

  /// Serialized rows, for [SyncOp.rows].
  final List<Map<String, dynamic>> rows;

  @override
  Map<String, dynamic> toJson() => {
        'v': MeshMessage.version,
        't': 'sync',
        's': scope,
        'op': op.name,
        if (ids.isNotEmpty) 'ids': ids,
        if (rows.isNotEmpty) 'rows': rows,
      };

  factory SyncMessage.fromJson(Map<String, dynamic> j) => SyncMessage(
        scope: j['s'] as String,
        op: SyncOp.values.firstWhere(
          (o) => o.name == j['op'],
          orElse: () => SyncOp.done,
        ),
        ids: (j['ids'] as List?)?.cast<String>() ?? const [],
        rows: (j['rows'] as List?)
                ?.map((r) => (r as Map).cast<String, dynamic>())
                .toList() ??
            const [],
      );
}
