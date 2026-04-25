import 'dart:convert';

/// Encode/decode for QR-based UNIUN cards.
///
/// Wire format: plain JSON string embedded directly in the QR code.
/// No base64 — QR handles binary natively so encoding adds no value.
///
/// Channel: {"k":40,"id":"<hex>","pk":"<hex>","ca":<ts>,"n":"<name>","a":"<about>"}
/// User:    {"n":"<name>","pk":"<pubkeyHex>"}
class UniunQrPayload {
  UniunQrPayload._();

  static String encodeChannel({
    required String channelId,
    required String creatorPubKey,
    required String name,
    required String about,
    String picture = '',
    int createdAt = 0,
  }) {
    return jsonEncode({
      'k': 40,
      'id': channelId,
      'pk': creatorPubKey,
      'ca': createdAt,
      'n': name,
      'a': about,
      if (picture.isNotEmpty) 'p': picture,
    });
  }

  static String encodeUser({
    required String name,
    required String pubkeyHex,
  }) {
    return jsonEncode({'n': name, 'pk': pubkeyHex});
  }

  /// Decode a raw QR string. Returns null if not a valid UNIUN payload.
  static UniunQrDecoded? decode(String raw) {
    try {
      final obj = jsonDecode(raw.trim());
      if (obj is! Map<String, dynamic>) return null;

      String s(Object? v) => v?.toString() ?? '';

      // Channel: has 'id' key (64-char hex)
      if (obj.containsKey('id') && s(obj['id']).length >= 60) {
        return UniunQrDecoded(
          kind: UniunQrKind.channel,
          fields: {
            'Kind': s(obj['k'] ?? 40),
            'Channel': s(obj['n']),
            if (s(obj['a']).isNotEmpty) 'About': s(obj['a']),
            'ID': s(obj['id']),
            if (s(obj['pk']).isNotEmpty) 'Creator': s(obj['pk']),
          },
          raw: obj,
        );
      }

      // User: has 'pk' key (pubkey hex)
      if (obj.containsKey('pk') && obj.containsKey('n')) {
        return UniunQrDecoded(
          kind: UniunQrKind.user,
          fields: {
            'Name': s(obj['n']),
            'pubkey': s(obj['pk']),
          },
          raw: obj,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}

enum UniunQrKind { user, channel }

class UniunQrDecoded {
  const UniunQrDecoded({
    required this.kind,
    required this.fields,
    required this.raw,
  });

  final UniunQrKind kind;
  final Map<String, String> fields;

  /// Raw decoded JSON object — use to navigate to channel or add user.
  final Map<String, dynamic> raw;

  String? get channelId => kind == UniunQrKind.channel ? raw['id'] as String? : null;
  String? get pubkeyHex => raw['pk'] as String?;
  String? get name => raw['n'] as String?;
}
