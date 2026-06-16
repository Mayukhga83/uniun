import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';

/// Symmetric AEAD cipher for the **same-identity** mesh channel.
///
/// Both of a user's devices hold the same nsec, so each derives the SAME key from it
/// (HKDF-SHA256, no key exchange) and then ChaCha20-Poly1305 seals/opens every sync
/// message. This keeps the trusted reconciliation — which transfers DECRYPTED DM and
/// profile rows — confidential over BLE/LAN, where it would otherwise be cleartext.
///
/// Only the same-identity path is encrypted. The handshake (`Hello`) and the public
/// Surrounding/mesh gossip stay plaintext: the former carries only pubkeys + signed
/// nonces, the latter are signed public events any relay must read to forward.
class SameIdentityCipher {
  SameIdentityCipher._(this._key);

  final SecretKey _key;

  static final Cipher _cipher = Chacha20.poly1305Aead();

  /// Versioned context binding the derived key to this protocol revision — bump the
  /// suffix on any breaking change so old/new builds never share a key.
  static const String _info = 'uniun-mesh-same-identity-v1';

  /// Fixed, non-secret HKDF salt (same on both devices, so they derive the same
  /// key). A constant salt is fine here — the IKM is a high-entropy private key —
  /// and it must be non-empty (the HKDF extract step uses it as the HMAC key).
  static const String _salt = 'uniun-mesh-hkdf-salt-v1';

  /// Derives the channel key from the shared private key (raw hex).
  static Future<SameIdentityCipher> fromPrivkey(String privkeyHex) async {
    final key = await Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: SecretKey(_hexToBytes(privkeyHex)),
      nonce: utf8.encode(_salt),
      info: utf8.encode(_info),
    );
    return SameIdentityCipher._(key);
  }

  /// Encrypts [plaintext] → `nonce || ciphertext || mac` (a fresh random nonce each
  /// call, so identical plaintexts never produce identical ciphertexts).
  Future<Uint8List> seal(Uint8List plaintext) async {
    final box = await _cipher.encrypt(plaintext, secretKey: _key);
    return box.concatenation();
  }

  /// Decrypts a sealed blob; null on auth failure or malformed input.
  Future<Uint8List?> open(Uint8List sealed) async {
    try {
      final box = SecretBox.fromConcatenation(
        sealed,
        nonceLength: _cipher.nonceLength,
        macLength: _cipher.macAlgorithm.macLength,
      );
      return Uint8List.fromList(await _cipher.decrypt(box, secretKey: _key));
    } catch (_) {
      return null;
    }
  }

  static List<int> _hexToBytes(String hex) {
    final out = <int>[];
    for (var i = 0; i + 1 < hex.length; i += 2) {
      out.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return out;
  }
}
