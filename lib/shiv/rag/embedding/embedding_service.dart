import 'dart:io';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// On-device text embedding using all-MiniLM-L6-v2 (TFLite).
///
/// ## Files needed (downloaded to documents directory)
///   - all_minilm_l6_v2.tflite  (~80 MB) — TFLite export of sentence-transformers model
///   - vocab.txt                 (~230 KB) — BERT uncased vocabulary
///
/// Downloaded automatically by [EmbeddingModelDownloader] when the user
/// downloads their first LLM model via [SelectAIModelCubit].
/// If files are not present, RAG silently degrades to no-context mode.
///
/// Output: 384-dimensional L2-normalised float vector.
@lazySingleton
class EmbeddingService {
  static const int _maxSeqLen = 128;
  static const int _embeddingDim = 384;
  static const String _modelFilename = 'all_minilm_l6_v2.tflite';
  static const String _vocabFilename = 'vocab.txt';

  static const int _clsToken = 101;
  static const int _sepToken = 102;
  static const int _unkToken = 100;
  static const int _padToken = 0;

  Interpreter? _interpreter;
  Map<String, int>? _vocab;

  bool get isReady => _interpreter != null && _vocab != null;

  // ── Init ───────────────────────────────────────────────────────────────────

  /// Loads model from the documents directory (downloaded by [EmbeddingModelDownloader]).
  /// Safe to call multiple times — no-op after a successful load.
  /// If files are not present yet, does nothing — RAG degrades to no-context mode.
  Future<void> init() async {
    if (isReady) return;
    try {
      final dir = (await getApplicationDocumentsDirectory()).path;
      final modelFile = File('$dir/$_modelFilename');
      final vocabFile = File('$dir/$_vocabFilename');

      if (!modelFile.existsSync() || !vocabFile.existsSync()) return;

      _vocab = _parseVocab(await vocabFile.readAsString());
      _interpreter = Interpreter.fromFile(modelFile);
    } catch (_) {
      _interpreter = null;
      _vocab = null;
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Embed [text] → 384-dim L2-normalised vector.
  /// Returns [] if model is not loaded (no crash, just no RAG context).
  Future<List<double>> embed(String text) async {
    if (!isReady) await init();
    if (!isReady) return [];

    final tokenIds = _tokenize(text);
    final attentionMask = tokenIds.map((t) => t != _padToken ? 1 : 0).toList();

    final inputIds = [tokenIds];
    final maskInput = [attentionMask];

    // This quantized model has 2 inputs (input_ids, attention_mask) — no token_type_ids.
    // Output 0: already-pooled sentence embedding [1, 384] — no mean pooling needed.
    final output0 = [List.filled(_embeddingDim, 0.0)];

    _interpreter!.runForMultipleInputs(
      [inputIds, maskInput],
      {0: output0},
    );

    return _l2Normalize(output0[0]);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  // ── Tokeniser ──────────────────────────────────────────────────────────────

  List<int> _tokenize(String text) {
    final tokens = <int>[_clsToken];
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);

    for (final word in words) {
      if (tokens.length >= _maxSeqLen - 1) break;
      tokens.addAll(_wordPiece(word));
    }

    tokens.add(_sepToken);
    while (tokens.length < _maxSeqLen) tokens.add(_padToken);
    return tokens.take(_maxSeqLen).toList();
  }

  List<int> _wordPiece(String word) {
    final vocab = _vocab!;
    if (vocab.containsKey(word)) return [vocab[word]!];

    final subTokens = <int>[];
    var start = 0;
    while (start < word.length) {
      var matched = false;
      for (var end = word.length; end > start; end--) {
        final sub = start == 0
            ? word.substring(start, end)
            : '##${word.substring(start, end)}';
        if (vocab.containsKey(sub)) {
          subTokens.add(vocab[sub]!);
          start = end;
          matched = true;
          break;
        }
      }
      if (!matched) {
        subTokens.add(_unkToken);
        start++;
      }
    }
    return subTokens.isEmpty ? [_unkToken] : subTokens;
  }

  // ── L2 normalisation ──────────────────────────────────────────────────────

  List<double> _l2Normalize(List<double> vec) {
    final norm = sqrt(vec.fold(0.0, (acc, v) => acc + v * v));
    if (norm == 0) return vec;
    return vec.map((v) => v / norm).toList();
  }

  // ── Vocab parsing ──────────────────────────────────────────────────────────

  static Map<String, int> _parseVocab(String raw) {
    final lines = raw.split('\n');
    final vocab = <String, int>{};
    for (var i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) vocab[token] = i;
    }
    return vocab;
  }
}
