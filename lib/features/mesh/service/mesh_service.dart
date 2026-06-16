import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/models/mesh/mesh_peer_state_model.dart';
import 'package:uniun/domain/repositories/user_repository.dart';

import '../engine/mesh_engine_host.dart';

/// Main-isolate controller for the offline mesh. Hosting differs by platform:
///
///  * **Android** — the engine runs in a headless `FlutterEngine` hosted by a
///    foreground service (so the mesh survives backgrounding). This controller asks
///    native to start/stop it over [_control].
///  * **iOS / macOS** — the engine runs **inline on this (main) isolate**. Apple
///    platforms are foreground-only (no background service needed), and
///    `package:objective_c` — pulled in by `path_provider` — crashes when a second
///    `FlutterEngine` exists in the process. So we host [MeshEngineHost] directly.
///
/// Either way the connected-peer count is mirrored for the Settings UI by watching
/// the [MeshPeerStateModel] rows the host maintains. Gated by the opt-in flag and a
/// logged-in user — default off for privacy/battery.
@lazySingleton
class MeshService with WidgetsBindingObserver {
  MeshService(this._isar, this._users, this._settings);

  final Isar _isar;
  final UserRepository _users;
  final AppSettingsStore _settings;

  static const MethodChannel _control =
      MethodChannel('in.uniun.app/mesh_control');

  final ValueNotifier<int> connectedPeers = ValueNotifier<int>(0);

  // Inline host (iOS/macOS only).
  MeshEngineHost? _host;
  StreamSubscription<void>? _peerStateWatch;
  bool _running = false;
  bool _observing = false;
  // Set when start() ran while the app was not foreground (cold launch); the real
  // start is deferred to the next resume.
  bool _pendingStart = false;
  int _generation = 0;

  /// Apple platforms run the mesh inline; Android uses the headless engine.
  bool get _inline => Platform.isIOS || Platform.isMacOS;

  bool get isRunning => _running;

  void start() {
    if (_running) return;
    _running = true;
    // Start only when the app is foreground. Android 12+ forbids starting the
    // foreground service from the background, and app launch calls start() before
    // the activity is resumed — so defer to the next resume if needed.
    _ensureObserver();
    if (_isForeground()) {
      unawaited(_init());
    } else {
      _pendingStart = true;
    }
  }

  Future<void> _init() async {
    final gen = ++_generation;
    if (!_settings.meshEnabled) {
      _running = false;
      return;
    }
    final keys = await _users.getActiveKeysHex();
    if (keys == null || gen != _generation) {
      if (gen == _generation) _running = false;
      return; // not logged in / superseded
    }

    // Reset the UI peer-count mirror — the engine may have been killed last run
    // without clearing its rows — then keep it in sync with the host's writes.
    connectedPeers.value = 0;
    await _isar.writeTxn(() => _isar.meshPeerStateModels.clear());
    if (gen != _generation) return;
    _peerStateWatch = _isar.meshPeerStateModels.watchLazy().listen((_) async {
      connectedPeers.value = await _isar.meshPeerStateModels.count();
    });

    if (_inline) {
      // Apple: run the host on this (main) isolate, sharing the app's Isar
      // (ownsIsar: false so teardown never closes it).
      _host = MeshEngineHost(
        _isar,
        pubkeyHex: keys.pubkeyHex,
        privkeyHex: keys.privkeyHex,
        ownsIsar: false,
      );
      await _host!.start();
    } else {
      // Android: the native foreground service hosts the headless engine.
      await _invoke('start');
    }
  }

  Future<void> stop() async {
    _generation++;
    _running = false;
    _pendingStart = false;
    connectedPeers.value = 0;

    await _peerStateWatch?.cancel();
    _peerStateWatch = null;

    if (_inline) {
      await _host?.shutdown();
      _host = null;
    } else {
      await _invoke('stop');
    }

    try {
      await _isar.writeTxn(() => _isar.meshPeerStateModels.clear());
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingStart && _running) {
      _pendingStart = false;
      unawaited(_init());
    }
  }

  void _ensureObserver() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  bool _isForeground() =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  Future<void> _invoke(String method) async {
    try {
      await _control.invokeMethod<void>(method);
    } on MissingPluginException {
      // Platform without the native mesh host — no-op.
    } on PlatformException catch (e) {
      debugPrint('MESH: native $method failed: $e');
    }
  }
}
