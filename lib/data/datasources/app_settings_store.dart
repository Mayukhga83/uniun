import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

@module
abstract class SharedPreferencesModule {
  @singleton
  @preResolve
  Future<SharedPreferences> sharedPreferences() =>
      SharedPreferences.getInstance();
}

@singleton
class AppSettingsStore {
  static const _kActiveModelId = 'app_settings.active_model_id';
  static const _kMeshEnabled = 'app_settings.mesh_enabled';

  final SharedPreferences _prefs;

  AppSettingsStore(this._prefs);

  AIModelId? get activeModelId {
    final raw = _prefs.getString(_kActiveModelId);
    if (raw == null) return null;
    for (final id in AIModelId.values) {
      if (id.name == raw) return id;
    }
    return null;
  }

  Future<void> setActiveModelId(AIModelId? id) async {
    if (id == null) {
      await _prefs.remove(_kActiveModelId);
    } else {
      await _prefs.setString(_kActiveModelId, id.name);
    }
  }

  /// Whether the offline Bluetooth/Wi-Fi mesh is enabled. Default off — opt-in for
  /// privacy and battery.
  bool get meshEnabled => _prefs.getBool(_kMeshEnabled) ?? false;

  Future<void> setMeshEnabled(bool enabled) =>
      _prefs.setBool(_kMeshEnabled, enabled);
}

/// Holds the logged-in user's public identity (pubkeyHex, npub, createdAt).
/// The private key (nsec) is NEVER stored here — it lives in
/// flutter_secure_storage (Android Keystore / iOS Keychain).
@singleton
class UserKeyStore {
  static const _kPubkeyHex = 'user_key.pubkey_hex';
  static const _kNpub = 'user_key.npub';
  static const _kCreatedAt = 'user_key.created_at_ms';

  final SharedPreferences _prefs;

  UserKeyStore(this._prefs);

  String? get pubkeyHex => _prefs.getString(_kPubkeyHex);
  String? get npub => _prefs.getString(_kNpub);
  DateTime? get createdAt {
    final ms = _prefs.getInt(_kCreatedAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get hasKey => _prefs.containsKey(_kPubkeyHex);

  Future<void> save({
    required String pubkeyHex,
    required String npub,
    required DateTime createdAt,
  }) async {
    await _prefs.setString(_kPubkeyHex, pubkeyHex);
    await _prefs.setString(_kNpub, npub);
    await _prefs.setInt(_kCreatedAt, createdAt.millisecondsSinceEpoch);
  }

  Future<void> clear() async {
    await _prefs.remove(_kPubkeyHex);
    await _prefs.remove(_kNpub);
    await _prefs.remove(_kCreatedAt);
  }
}
