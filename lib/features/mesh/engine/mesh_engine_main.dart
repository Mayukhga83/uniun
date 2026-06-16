import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uniun/data/datasources/isar_schemas.dart';

import 'mesh_engine_host.dart';
import 'mesh_identity.dart';

/// Dart entry point for the **Android headless mesh `FlutterEngine`**, hosted by
/// `MeshForegroundService` so the mesh keeps running in the background. The engine
/// has its own platform-channel access (BLE + mDNS push directly to it), opens its
/// own Isar at the shared path (Isar is the cross-engine bus for the UI peer-count
/// mirror), reads its identity from secure storage, and runs the whole mesh engine
/// ([MeshEngineHost]).
///
/// Apple platforms do NOT use this — they run [MeshEngineHost] inline on the main
/// isolate (see `MeshService`), since they're foreground-only and don't need a
/// background-capable second engine.
///
/// The native `DartExecutor` resolves entry points only in the **root library** (the
/// file with `main()`), so the `@pragma('vm:entry-point')` entry point `meshEngineMain`
/// lives in `lib/main.dart` and delegates here.
Future<void> runMeshEngine() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Register federated plugins (secure_storage, path_provider, bonsoir) on this
  // non-main engine — without it their platform channels aren't wired up here.
  DartPluginRegistrant.ensureInitialized();

  final identity = await readMeshIdentity();
  if (identity == null) return; // logged out — nothing to run

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    isarSchemas,
    directory: dir.path,
    name: Isar.defaultName,
  );

  final host = MeshEngineHost(
    isar,
    pubkeyHex: identity.pubkeyHex,
    privkeyHex: identity.privkeyHex,
  );
  await host.start();
  // The host now lives on its server + watchers + the `mesh_engine` shutdown
  // channel; it tears itself down (and closes Isar) when native invokes `shutdown`.
}
