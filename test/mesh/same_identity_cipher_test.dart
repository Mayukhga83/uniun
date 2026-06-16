import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/mesh/link/link_session.dart';
import 'package:uniun/features/mesh/payload/payload_envelope.dart';
import 'package:uniun/features/mesh/security/same_identity_cipher.dart';

import 'support/paired_mesh_link.dart';

/// The same-identity channel cipher: HKDF-from-nsec key derivation must be
/// deterministic (so a user's two devices interoperate), and ChaCha20-Poly1305 must
/// be confidential + tamper-evident.
void main() {
  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  test('seals then opens with the same key', () async {
    final cipher = await SameIdentityCipher.fromPrivkey('11' * 32);
    final plain = bytes('decrypted DM row');
    final sealed = await cipher.seal(plain);
    expect(sealed, isNot(equals(plain))); // actually encrypted
    expect(await cipher.open(sealed), equals(plain));
  });

  test('two devices with the same nsec derive the same key and interoperate',
      () async {
    final deviceA = await SameIdentityCipher.fromPrivkey('33' * 32);
    final deviceB = await SameIdentityCipher.fromPrivkey('33' * 32);
    final sealed = await deviceA.seal(bytes('hello from A'));
    expect(await deviceB.open(sealed), equals(bytes('hello from A')));
  });

  test('a different nsec cannot open', () async {
    final a = await SameIdentityCipher.fromPrivkey('11' * 32);
    final b = await SameIdentityCipher.fromPrivkey('22' * 32);
    expect(await b.open(await a.seal(bytes('secret'))), isNull);
  });

  test('a fresh nonce each time → identical plaintext seals differently', () async {
    final cipher = await SameIdentityCipher.fromPrivkey('44' * 32);
    final a = await cipher.seal(bytes('same'));
    final b = await cipher.seal(bytes('same'));
    expect(a, isNot(equals(b)));
  });

  test('tampered ciphertext fails to open', () async {
    final cipher = await SameIdentityCipher.fromPrivkey('55' * 32);
    final sealed = await cipher.seal(bytes('payload'));
    sealed[sealed.length - 1] ^= 0xFF; // flip a MAC byte
    expect(await cipher.open(sealed), isNull);
  });

  test('a SyncMessage seals over a link and opens on the same-key peer', () async {
    final links = createPairedLinks();
    final sA = LinkSession(links.a);
    final sB = LinkSession(links.b);
    final cipherA = await SameIdentityCipher.fromPrivkey('66' * 32);
    final cipherB = await SameIdentityCipher.fromPrivkey('66' * 32);

    final received = Completer<MeshMessage>();
    sB.onAppMessage((m) {
      if (m is EncryptedMessage) {
        cipherB.open(m.payload).then((inner) {
          if (inner == null) return;
          final dm = MeshMessage.decode(inner);
          if (dm != null) received.complete(dm);
        });
      }
    });

    // Mirrors the host's wrapped send.
    const original =
        SyncMessage(scope: 'note', op: SyncOp.have, ids: ['id1', 'id2']);
    sA.send(EncryptedMessage(await cipherA.seal(original.encode())));

    final got = await received.future.timeout(const Duration(seconds: 2));
    expect(got, isA<SyncMessage>());
    final sync = got as SyncMessage;
    expect(sync.scope, 'note');
    expect(sync.op, SyncOp.have);
    expect(sync.ids, ['id1', 'id2']);
  });
}
