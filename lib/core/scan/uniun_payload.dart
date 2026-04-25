import 'dart:convert';

class UniunPayload {
  UniunPayload._();

  static const String channelMagic = 'UNIUN-C';
  static const String userMagic = 'UNIUN-U';

  static const int gridCols = 24;

  // ── Encode ────────────────────────────────────────────────────────────────

  static UniunEncoded encodeChannel({
    required String channelId,
    required String creatorPubKey,
    required String name,
    required String about,
    String picture = '',
    int createdAt = 0,
    List<String> tags = const [],
  }) {
    final obj = {
      'k': 40,
      'id': channelId,
      'pk': creatorPubKey,
      'ca': createdAt,
      'n': name,
      'a': about,
      if (picture.isNotEmpty) 'p': picture,
      if (tags.isNotEmpty) 't': tags,
    };
    return UniunEncoded(magic: channelMagic, grid: _toGrid(obj));
  }

  static UniunEncoded encodeUser({
    required String name,
    required String pubkeyHex,
  }) {
    final obj = {'n': name, 'pk': pubkeyHex};
    return UniunEncoded(magic: userMagic, grid: _toGrid(obj));
  }

  static String _toGrid(Map<String, dynamic> obj) {
    final raw = base64Url.encode(utf8.encode(jsonEncode(obj)));
    final b = StringBuffer();
    for (var i = 0; i < raw.length; i += gridCols) {
      if (i > 0) b.write('\n');
      b.write(raw.substring(i, (i + gridCols).clamp(0, raw.length)));
    }
    return b.toString();
  }

  // ── Decode ────────────────────────────────────────────────────────────────

  static UniunDecoded? decode(String rawText) {
    final upper = rawText.toUpperCase();

    UniunCardKind? kind;
    int magicEnd = -1;

    final ci = upper.indexOf(channelMagic);
    final ui = upper.indexOf(userMagic);

    // Pick whichever magic appears first (and actually exists).
    if (ci >= 0 && (ui < 0 || ci <= ui)) {
      kind = UniunCardKind.channel;
      magicEnd = ci + channelMagic.length;
    } else if (ui >= 0) {
      kind = UniunCardKind.user;
      magicEnd = ui + userMagic.length;
    }

    if (kind == null) return null;

    final after = rawText.substring(magicEnd);
    final cleaned = after.replaceAll(RegExp(r'[^A-Za-z0-9_\-=]'), '');
    if (cleaned.isEmpty) return null;

    try {
      final mod = cleaned.length % 4;
      final padded = mod == 0 ? cleaned : cleaned + ('=' * (4 - mod));
      final obj = jsonDecode(utf8.decode(base64Url.decode(padded)));
      if (obj is! Map<String, dynamic>) return null;

      // Kind is confirmed by JSON content, not the magic alone.
      final resolvedKind = obj.containsKey('id')
          ? UniunCardKind.channel
          : UniunCardKind.user;

      return UniunDecoded(kind: resolvedKind, fields: _fieldsFor(resolvedKind, obj));
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _fieldsFor(
      UniunCardKind kind, Map<String, dynamic> obj) {
    String s(Object? v) => v?.toString() ?? '';
    if (kind == UniunCardKind.user) {
      return {'Name': s(obj['n']), 'pubkey': s(obj['pk'])};
    }
    return {
      'Kind': s(obj['k'] ?? 40),
      'Channel': s(obj['n']),
      if (s(obj['a']).isNotEmpty) 'About': s(obj['a']),
      'ID': s(obj['id']),
      if (s(obj['pk']).isNotEmpty) 'Creator': s(obj['pk']),
      if (s(obj['ca']).isNotEmpty && s(obj['ca']) != '0') 'Created': s(obj['ca']),
    };
  }
}

class UniunEncoded {
  const UniunEncoded({required this.magic, required this.grid});
  final String magic;
  final String grid;
}

enum UniunCardKind { user, channel }

class UniunDecoded {
  const UniunDecoded({required this.kind, required this.fields});
  final UniunCardKind kind;
  final Map<String, String> fields;
}
