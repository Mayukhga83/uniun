import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/mesh/handshake/identity_proof.dart';
import 'package:uniun/features/mesh/link/mesh_peer.dart';
import 'package:uniun/features/mesh/transport/lan/lan_link.dart';
import 'package:uniun/features/mesh/transport/lan/lan_server.dart';

import 'support/fake_signer.dart';

/// Exercises [LanLink] (framing + lifecycle) over a REAL loopback TCP connection,
/// running the full identity handshake end-to-end. This validates the LAN socket
/// path on the host VM; mDNS discovery itself needs physical devices.
void main() {
  test('LanServer accepts a connection and reports its port', () async {
    final server = LanServer();
    await server.start();
    expect(server.isRunning, isTrue);
    expect(server.port, greaterThan(0));

    final accepted = Completer<Socket>();
    final sub = server.connections.listen(accepted.complete);
    final client = await Socket.connect(
      InternetAddress.loopbackIPv4,
      server.port,
    );
    final serverSide = await accepted.future;

    await sub.cancel();
    client.destroy();
    serverSide.destroy();
    await server.stop();
  });

  test('mutual handshake over real loopback TCP via LanLink', () async {
    final server = LanServer();
    await server.start();
    final accepted = Completer<Socket>();
    final sub = server.connections.listen(accepted.complete);

    final clientSocket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      server.port,
    );
    final serverSocket = await accepted.future;

    final clientLink = LanLink.fromSocket(clientSocket);
    final serverLink = LanLink.fromSocket(serverSocket);

    final results = await Future.wait([
      IdentityProof(FakeSigner('a' * 64, nonceSeed: 'A')).run(clientLink),
      IdentityProof(FakeSigner('b' * 64, nonceSeed: 'B')).run(serverLink),
    ]);

    expect(results[0]!.peerPubkey, 'b' * 64);
    expect(results[0]!.mode, PeerMode.stranger);
    expect(results[1]!.peerPubkey, 'a' * 64);

    await sub.cancel();
    await clientLink.close();
    await serverLink.close();
    await server.stop();
  });
}
