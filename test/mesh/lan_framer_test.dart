import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/mesh/link/mesh_link.dart';
import 'package:uniun/features/mesh/transport/lan/lan_framer.dart';
import 'package:uniun/features/mesh/transport/lan/lan_link.dart';

Uint8List _bytes(String s) => Uint8List.fromList(s.codeUnits);
String _str(Uint8List b) => String.fromCharCodes(b);

void main() {
  group('LanFrameDecoder', () {
    test('single framed message round-trips', () {
      final dec = LanFrameDecoder();
      final out = dec.add(lanFrame(_bytes('hello'))).toList();
      expect(out.map(_str), ['hello']);
    });

    test('two messages in one chunk', () {
      final dec = LanFrameDecoder();
      final chunk = Uint8List.fromList(
        [...lanFrame(_bytes('one')), ...lanFrame(_bytes('two'))],
      );
      expect(dec.add(chunk).map(_str).toList(), ['one', 'two']);
    });

    test('message split across chunks (payload boundary)', () {
      final dec = LanFrameDecoder();
      final framed = lanFrame(_bytes('splitme'));
      expect(dec.add(Uint8List.sublistView(framed, 0, 6)).toList(), isEmpty);
      expect(
        dec.add(Uint8List.sublistView(framed, 6)).map(_str).toList(),
        ['splitme'],
      );
    });

    test('header split across chunks', () {
      final dec = LanFrameDecoder();
      final framed = lanFrame(_bytes('abcd'));
      expect(dec.add(Uint8List.sublistView(framed, 0, 2)).toList(), isEmpty);
      expect(dec.add(Uint8List.sublistView(framed, 2, 3)).toList(), isEmpty);
      expect(
        dec.add(Uint8List.sublistView(framed, 3)).map(_str).toList(),
        ['abcd'],
      );
    });

    test('byte-at-a-time delivery reassembles correctly', () {
      final dec = LanFrameDecoder();
      final framed = Uint8List.fromList(
        [...lanFrame(_bytes('aa')), ...lanFrame(_bytes('bbbb'))],
      );
      final got = <String>[];
      for (final byte in framed) {
        got.addAll(dec.add(Uint8List.fromList([byte])).map(_str));
      }
      expect(got, ['aa', 'bbbb']);
    });

    test('empty (zero-length) message is delivered', () {
      final dec = LanFrameDecoder();
      expect(dec.add(lanFrame(Uint8List(0))).map((m) => m.length).toList(), [0]);
    });

    test('oversized declared length throws', () {
      final dec = LanFrameDecoder();
      final bad = Uint8List(4);
      ByteData.view(bad.buffer).setUint32(0, kLanMaxMessageBytes + 1, Endian.big);
      expect(() => dec.add(bad).toList(), throwsA(isA<LanFrameException>()));
    });
  });

  group('LanLink', () {
    test('frames outbound and de-frames inbound', () async {
      final inbound = StreamController<Uint8List>();
      final sent = <Uint8List>[];
      final link = LanLink(
        linkId: 'test:1',
        inbound: inbound.stream,
        rawSend: sent.add,
        rawClose: () async {},
      );

      expect(link.transportKind, TransportKind.lan);

      // Outbound is length-framed.
      link.send(_bytes('ping'));
      expect(sent.single, lanFrame(_bytes('ping')));

      // Inbound raw bytes are de-framed into whole messages.
      final received = <String>[];
      link.messages.listen((m) => received.add(_str(m)));
      inbound.add(lanFrame(_bytes('pong')));
      // Two messages arriving in one chunk.
      inbound.add(Uint8List.fromList(
        [...lanFrame(_bytes('a')), ...lanFrame(_bytes('b'))],
      ));
      await Future<void>.delayed(Duration.zero);
      expect(received, ['pong', 'a', 'b']);

      await link.close();
      await inbound.close();
    });

    test('send after close is a no-op', () async {
      final inbound = StreamController<Uint8List>();
      final sent = <Uint8List>[];
      final link = LanLink(
        linkId: 'test:2',
        inbound: inbound.stream,
        rawSend: sent.add,
        rawClose: () async {},
      );
      await link.close();
      link.send(_bytes('nope'));
      expect(sent, isEmpty);
      expect(link.isConnected, isFalse);
      await inbound.close();
    });
  });
}
