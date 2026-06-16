import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

/// mDNS/DNS-SD service type for UNIUN device sync. Our own type so we only find
/// other UNIUN instances, never unrelated Bonjour services.
const String kLanServiceType = '_uniun-sync._tcp';

/// A resolved nearby UNIUN peer reachable over the LAN.
class LanPeerEndpoint {
  LanPeerEndpoint({required this.host, required this.port, required this.name});
  final String host;
  final int port;

  /// The peer's mDNS instance name (a random per-launch token — NOT the Nostr
  /// identity, which is proven only after the TCP handshake).
  final String name;
}

/// Advertises this device's sync service over mDNS and browses for peers,
/// resolving each to a [LanPeerEndpoint]. Deliberately carries **no Nostr pubkey**
/// in the advertisement/TXT — identity is established by the signed-nonce
/// handshake once a TCP link is open.
class LanDiscovery {
  LanDiscovery({required this.instanceName});

  /// Unique per-device instance name; used to advertise and to skip self-discovery.
  final String instanceName;

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discSub;
  final _peers = StreamController<LanPeerEndpoint>.broadcast();

  Stream<LanPeerEndpoint> get peers => _peers.stream;

  Future<void> start({required int port}) async {
    final broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: instanceName,
        type: kLanServiceType,
        port: port,
      ),
    );
    await broadcast.ready;
    await broadcast.start();
    _broadcast = broadcast;

    final discovery = BonsoirDiscovery(type: kLanServiceType);
    await discovery.ready;
    _discSub = discovery.eventStream?.listen(_onEvent);
    await discovery.start();
    _discovery = discovery;
  }

  void _onEvent(BonsoirDiscoveryEvent event) {
    final service = event.service;
    switch (event.type) {
      case BonsoirDiscoveryEventType.discoveryServiceFound:
        if (service != null) {
          unawaited(
            _discovery?.serviceResolver.resolveService(service) ??
                Future.value(),
          );
        }
      case BonsoirDiscoveryEventType.discoveryServiceResolved:
        if (service is ResolvedBonsoirService &&
            service.host != null &&
            service.name != instanceName) {
          _peers.add(
            LanPeerEndpoint(
              host: service.host!,
              port: service.port,
              name: service.name,
            ),
          );
        }
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _discSub?.cancel();
    _discSub = null;
    await _discovery?.stop();
    _discovery = null;
    await _broadcast?.stop();
    _broadcast = null;
    if (!_peers.isClosed) await _peers.close();
  }
}
