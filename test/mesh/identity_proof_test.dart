import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/mesh/handshake/identity_proof.dart';
import 'package:uniun/features/mesh/link/mesh_peer.dart';
import 'package:uniun/features/mesh/payload/payload_envelope.dart';

import 'support/fake_signer.dart';
import 'support/paired_mesh_link.dart';

void main() {
  test('same identity → both resolve sameIdentity', () async {
    final links = createPairedLinks();
    final pub = 'a' * 64;
    final ra = IdentityProof(FakeSigner(pub, nonceSeed: 'A')).run(links.a);
    final rb = IdentityProof(FakeSigner(pub, nonceSeed: 'B')).run(links.b);
    final results = await Future.wait([ra, rb]);

    expect(results[0]!.mode, PeerMode.sameIdentity);
    expect(results[1]!.mode, PeerMode.sameIdentity);
    expect(results[0]!.peerPubkey, pub);
    expect(results[1]!.peerPubkey, pub);
  });

  test('different identities → both resolve stranger with peer pubkey', () async {
    final links = createPairedLinks();
    final pubA = 'a' * 64;
    final pubB = 'b' * 64;
    final ra = IdentityProof(FakeSigner(pubA, nonceSeed: 'A')).run(links.a);
    final rb = IdentityProof(FakeSigner(pubB, nonceSeed: 'B')).run(links.b);
    final results = await Future.wait([ra, rb]);

    expect(results[0]!.mode, PeerMode.stranger);
    expect(results[0]!.peerPubkey, pubB);
    expect(results[1]!.mode, PeerMode.stranger);
    expect(results[1]!.peerPubkey, pubA);
  });

  test('forged proof → honest side rejects (null)', () async {
    final links = createPairedLinks();
    final honest =
        IdentityProof(FakeSigner('a' * 64, nonceSeed: 'A')).run(links.a);

    // Adversary on end B claims a victim pubkey but signs garbage.
    final victim = 'v' * 64;
    links.b.messages.listen((bytes) {
      final msg = MeshMessage.decode(bytes);
      if (msg is HelloMessage && msg.challenge != null) {
        links.b.send(
          HelloMessage(
            pubkey: victim,
            challenge: 'adv-nonce',
            proof: const {'pk': 'forged-pk', 'sig': 'forged'},
          ).encode(),
        );
      }
    });

    expect(await honest, isNull);
  });

  test('silent peer → timeout resolves null', () async {
    final links = createPairedLinks();
    // End B never responds.
    final result = await IdentityProof(
      FakeSigner('a' * 64),
      timeout: const Duration(milliseconds: 150),
    ).run(links.a);
    expect(result, isNull);
  });
}
