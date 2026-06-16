import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nostr_core_dart/nostr.dart';

/// flutter_secure_storage key holding the user's nsec. Mirrors
/// `UserRepositoryImpl._nsecStorageKey`.
const String _kNsecSecureKey = 'uniun_nsec';

/// Loads the active identity **inside the Android mesh engine**, from the nsec alone.
///
/// Reads only the private key (nsec) from secure storage and derives the public key
/// from it, so identity comes from a single source. The private key never leaves
/// Dart + secure storage. Returns null when logged out.
Future<({String pubkeyHex, String privkeyHex})?> readMeshIdentity() async {
  try {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final nsec = await storage.read(key: _kNsecSecureKey);
    if (nsec == null) return null;

    final String privkeyHex;
    if (nsec.startsWith('nsec1')) {
      privkeyHex = Nip19.decodePrivkey(nsec);
      if (privkeyHex.isEmpty) return null;
    } else if (nsec.length == 64) {
      privkeyHex = nsec; // raw 32-byte hex
    } else {
      return null;
    }
    final pubkeyHex = Keychain(privkeyHex).public;
    return (pubkeyHex: pubkeyHex, privkeyHex: privkeyHex);
  } catch (_) {
    return null;
  }
}
