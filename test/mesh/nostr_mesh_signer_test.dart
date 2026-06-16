import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/features/mesh/handshake/nostr_mesh_signer.dart';

/// Exercises the PRODUCTION signer with real secp256k1/Schnorr keys (not the fake
/// used for handshake-logic tests), so the actual proof/verify path is covered.
void main() {
  late Keychain keyA;
  late Keychain keyB;
  late NostrMeshSigner signerA;
  late NostrMeshSigner verifier;

  setUp(() {
    keyA = Keychain.generate();
    keyB = Keychain.generate();
    signerA =
        NostrMeshSigner(pubkeyHex: keyA.public, privkeyHex: keyA.private);
    // verify() ignores the verifier's own key; any instance can check a proof.
    verifier =
        NostrMeshSigner(pubkeyHex: keyB.public, privkeyHex: keyB.private);
  });

  test('genuine proof verifies against the right pubkey + challenge', () {
    final proof = signerA.sign('challenge-xyz');
    expect(
      verifier.verify(
        proof: proof,
        claimedPubkey: keyA.public,
        challenge: 'challenge-xyz',
      ),
      isTrue,
    );
  });

  test('wrong challenge → rejected (replay/binding protection)', () {
    final proof = signerA.sign('challenge-xyz');
    expect(
      verifier.verify(
        proof: proof,
        claimedPubkey: keyA.public,
        challenge: 'different-challenge',
      ),
      isFalse,
    );
  });

  test('wrong claimed pubkey → rejected', () {
    final proof = signerA.sign('challenge-xyz');
    expect(
      verifier.verify(
        proof: proof,
        claimedPubkey: keyB.public, // not the signer
        challenge: 'challenge-xyz',
      ),
      isFalse,
    );
  });

  test('tampered signature → rejected', () {
    final proof = signerA.sign('challenge-xyz');
    final tampered = Map<String, dynamic>.from(proof)..['sig'] = '0' * 128;
    expect(
      verifier.verify(
        proof: tampered,
        claimedPubkey: keyA.public,
        challenge: 'challenge-xyz',
      ),
      isFalse,
    );
  });

  test('tampered content (id no longer matches) → rejected', () {
    final proof = signerA.sign('challenge-xyz');
    final tampered = Map<String, dynamic>.from(proof)
      ..['content'] = 'challenge-xyz-EVIL';
    expect(
      verifier.verify(
        proof: tampered,
        claimedPubkey: keyA.public,
        challenge: 'challenge-xyz-EVIL',
      ),
      isFalse,
    );
  });

  test('malformed proof map → rejected (no throw)', () {
    expect(
      verifier.verify(
        proof: const {'not': 'an event'},
        claimedPubkey: keyA.public,
        challenge: 'x',
      ),
      isFalse,
    );
  });

  test('newNonce is 32 hex chars and unique', () {
    final a = signerA.newNonce();
    final b = signerA.newNonce();
    expect(a.length, 32);
    expect(RegExp(r'^[0-9a-f]+$').hasMatch(a), isTrue);
    expect(a, isNot(b));
  });
}
