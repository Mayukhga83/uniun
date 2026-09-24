import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';

/// Covers: chunk id encoding, parsing, round-trip, and malformed ids.
void main() {
  test('chunkIdOf joins sha and ordinal with a colon', () {
    expect(chunkIdOf('abc123', 7), 'abc123:7');
  });

  test('parseChunkId round-trips chunkIdOf', () {
    final parsed = parseChunkId(chunkIdOf('deadbeef', 42));

    expect(parsed?.sha256, 'deadbeef');
    expect(parsed?.ordinal, 42);
  });

  test('ordinal 0 round-trips', () {
    expect(parseChunkId(chunkIdOf('sha', 0))?.ordinal, 0);
  });

  test('a realistic 64-char hex sha round-trips', () {
    const sha =
        '7b0c1a9fdfc67218b8ba2098f448c100c27070db91736b3c87fed63bfa21d418';

    final parsed = parseChunkId(chunkIdOf(sha, 12));

    expect(parsed?.sha256, sha);
    expect(parsed?.ordinal, 12);
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  test('malformed ids parse to null', () {
    for (final bad in [
      '',
      'nocolon',
      ':1',
      'sha:',
      'sha:x',
      'sha:-1',
      'sha:1.5',
      'sha: 1',
      'sha:1 ',
      'sha:+1',
      'sha:０',
    ]) {
      expect(parseChunkId(bad), isNull, reason: '"$bad"');
    }
  });

  test('the last colon separates, so a colon in the prefix survives', () {
    final parsed = parseChunkId('we:ird:3');

    expect(parsed?.sha256, 'we:ird');
    expect(parsed?.ordinal, 3);
  });
}
