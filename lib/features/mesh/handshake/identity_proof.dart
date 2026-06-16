import 'dart:async';

import '../link/mesh_link.dart';
import '../link/mesh_peer.dart';
import '../mesh_constants.dart';
import '../payload/payload_envelope.dart';

/// Signs and verifies the identity-proof challenge. The production implementation
/// wraps nostr_core_dart (`Event.from` to sign, `Event.isValid` to verify a
/// Schnorr signature); tests inject a fake. Kept abstract so the handshake logic
/// is unit-testable without real crypto.
abstract class MeshSigner {
  /// Our own Nostr pubkey (hex).
  String get pubkey;

  /// Produces a signed Nostr event proving control of [pubkey], binding the
  /// peer-issued [challenge] nonce (e.g. in the event content) so the proof can't
  /// be replayed against a different handshake.
  Map<String, dynamic> sign(String challenge);

  /// True iff [proof] is a valid signature by [claimedPubkey] over [challenge].
  bool verify({
    required Map<String, dynamic> proof,
    required String claimedPubkey,
    required String challenge,
  });

  /// A fresh, unpredictable nonce for our outgoing challenge.
  String newNonce();
}

class IdentityProofResult {
  IdentityProofResult({required this.peerPubkey, required this.mode});

  /// The peer's cryptographically-proven Nostr pubkey (hex).
  final String peerPubkey;

  /// [PeerMode.sameIdentity] if the proven pubkey equals ours, else
  /// [PeerMode.stranger].
  final PeerMode mode;
}

/// Runs the mutual signed-nonce handshake over a freshly-connected [MeshLink] and
/// resolves the peer's [PeerMode].
///
/// Both ends symmetrically: (1) open with `Hello{pubkey, challenge}`; (2) on
/// receiving the peer's challenge, reply `Hello{pubkey, proof=sign(theirNonce)}`;
/// (3) on receiving the peer's proof, verify it binds OUR nonce to THEIR claimed
/// pubkey. When both directions are proven, the mode is decided by comparing the
/// proven pubkey to ours. A bad signature or a timeout resolves to null so the
/// caller drops the peer.
///
/// The nonce needs freshness, not secrecy: the signature proves key control
/// regardless of who can read the nonce, and a fresh nonce per handshake defeats
/// replay. (Cross-transport MITM relay is mitigated at the link layer — Noise on
/// BLE; channel binding over LAN is future hardening, noted in the plan.)
class IdentityProof {
  IdentityProof(this._signer, {Duration timeout = kMeshHandshakeTimeout})
      : _timeout = timeout;

  final MeshSigner _signer;
  final Duration _timeout;

  /// Transport-neutral core: drives the handshake over a stream of inbound
  /// [HelloMessage]s and a [send] sink. Used in production over a `LinkSession`'s
  /// `hellos` so the link's single message stream can be shared with the sync
  /// engine afterwards.
  Future<IdentityProofResult?> negotiate({
    required Stream<HelloMessage> hellos,
    required void Function(HelloMessage) send,
  }) async {
    final completer = Completer<IdentityProofResult?>();
    final myNonce = _signer.newNonce();
    String? peerPubkey;
    var peerProven = false;
    var iProved = false;

    void finishIfDone() {
      if (peerProven && iProved && !completer.isCompleted) {
        final mode = peerPubkey == _signer.pubkey
            ? PeerMode.sameIdentity
            : PeerMode.stranger;
        completer.complete(
          IdentityProofResult(peerPubkey: peerPubkey!, mode: mode),
        );
      }
    }

    void fail() {
      if (!completer.isCompleted) completer.complete(null);
    }

    final sub = hellos.listen((msg) {
      // Lock the peer's claimed pubkey for the whole handshake.
      peerPubkey ??= msg.pubkey;
      if (msg.pubkey != peerPubkey) {
        fail();
        return;
      }

      // Answer their challenge with our signed proof (once).
      if (msg.challenge != null && !iProved) {
        send(HelloMessage(
          pubkey: _signer.pubkey,
          proof: _signer.sign(msg.challenge!),
        ));
        iProved = true;
      }

      // Verify their proof binds OUR nonce to THEIR claimed pubkey.
      if (msg.proof != null && !peerProven) {
        final ok = _signer.verify(
          proof: msg.proof!,
          claimedPubkey: msg.pubkey,
          challenge: myNonce,
        );
        if (!ok) {
          fail();
          return;
        }
        peerProven = true;
      }

      finishIfDone();
    });

    // Open with our claimed pubkey + fresh challenge.
    send(HelloMessage(pubkey: _signer.pubkey, challenge: myNonce));

    try {
      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } finally {
      await sub.cancel();
    }
  }

  /// Convenience for standalone use (and tests): decodes a raw [MeshLink]'s
  /// messages into the [negotiate] core. Subscribes to `link.messages` directly,
  /// so use this only when nothing else needs that stream.
  Future<IdentityProofResult?> run(MeshLink link) {
    final hellos = StreamController<HelloMessage>();
    final sub = link.messages.listen((bytes) {
      final msg = MeshMessage.decode(bytes);
      if (msg is HelloMessage) hellos.add(msg);
    });
    return negotiate(
      hellos: hellos.stream,
      send: (h) => link.send(h.encode()),
    ).whenComplete(() async {
      await sub.cancel();
      await hellos.close();
    });
  }
}
