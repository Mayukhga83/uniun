import 'package:uniun/features/mesh/handshake/identity_proof.dart';

/// Deterministic stand-in for the real Schnorr signer. A valid proof is the
/// string `sig(<pubkey>:<challenge>)`; verification recomputes and compares, so
/// only a holder of the claimed key (here, knowledge of its pubkey) can produce a
/// proof that binds the expected nonce. Nonces are seeded per instance so two
/// signers in one test don't collide.
class FakeSigner implements MeshSigner {
  FakeSigner(this.pubkey, {String nonceSeed = 'n'}) : _seed = nonceSeed;

  @override
  final String pubkey;
  final String _seed;
  int _c = 0;

  @override
  String newNonce() => '$_seed-${_c++}';

  @override
  Map<String, dynamic> sign(String challenge) => {
        'pk': pubkey,
        'ch': challenge,
        'sig': 'sig($pubkey:$challenge)',
      };

  @override
  bool verify({
    required Map<String, dynamic> proof,
    required String claimedPubkey,
    required String challenge,
  }) {
    return proof['pk'] == claimedPubkey &&
        proof['sig'] == 'sig($claimedPubkey:$challenge)';
  }
}
