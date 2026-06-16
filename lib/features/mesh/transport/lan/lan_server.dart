import 'dart:async';
import 'dart:io';

/// Accepts inbound TCP connections from LAN peers. Binds to an OS-assigned port
/// ([port]) which is then advertised over mDNS by [LanDiscovery]. Each accepted
/// socket is wrapped as a `LanLink` by the isolate-side `LanConnector`.
class LanServer {
  ServerSocket? _server;
  final _connections = StreamController<Socket>.broadcast();

  Stream<Socket> get connections => _connections.stream;
  int get port => _server?.port ?? 0;
  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0, shared: true);
    _server!.listen(
      (socket) {
        if (!_connections.isClosed) _connections.add(socket);
      },
      onError: (_) {/* transient accept error — keep listening */},
    );
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    if (!_connections.isClosed) await _connections.close();
  }
}
