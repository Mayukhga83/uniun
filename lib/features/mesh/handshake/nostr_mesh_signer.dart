import 'dart:math';

import 'package:nostr_core_dart/nostr.dart';

import 'identity_proof.dart';

/// Production [MeshSigner] backed by nostr_core_dart (secp256k1 / Schnorr).
///
/// A proof is an ephemeral Nostr event (kind [handshakeKind]) whose `content` is
/// the peer-issued challenge nonce, signed by our key. Verification recomputes the
/// id and checks the Schnorr signature via [Event.isValid] (we pass `verify:false`
/// to the constructor because nostr_core_dart's built-in verify is an `assert`,
/// which is stripped in release builds — we check the boolean ourselves), then
/// confirms the event author equals the claimed pubkey and the signed content
/// equals the expected nonce.
class NostrMeshSigner implements MeshSigner {
  NostrMeshSigner({required String pubkeyHex, required String privkeyHex})
      : pubkey = pubkeyHex.toLowerCase(),
        _privkeyHex = privkeyHex;

  /// Ephemeral kind (20000–29999 per NIP-01) so a leaked proof is never stored.
  static const int handshakeKind = 27492;

  @override
  final String pubkey;
  final String _privkeyHex;
  final Random _rng = Random.secure();

  @override
  String newNonce() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Map<String, dynamic> sign(String challenge) {
    final event = Event.from(
      kind: handshakeKind,
      tags: const [],
      content: challenge,
      privkey: _privkeyHex,
    );
    return event.toJson();
  }

  @override
  bool verify({
    required Map<String, dynamic> proof,
    required String claimedPubkey,
    required String challenge,
  }) {
    try {
      final event = Event.fromJson(proof, verify: false);
      return event.isValid() &&
          event.kind == handshakeKind &&
          event.pubkey.toLowerCase() == claimedPubkey.toLowerCase() &&
          event.content == challenge;
    } catch (_) {
      return false;
    }
  }
}
