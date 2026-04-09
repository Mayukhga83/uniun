import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads the all-MiniLM-L6-v2 TFLite model and BERT vocab to the
/// application documents directory so [EmbeddingService] can load them.
///
/// Called automatically by [SelectAIModelCubit] when the user downloads
/// their first LLM model — no separate user action required.
///
/// ## Hosted files
/// Replace these URLs with your own CDN / storage bucket before shipping.
/// The vocab.txt is the standard BERT uncased vocabulary (publicly available).
@lazySingleton
class EmbeddingModelDownloader {
  // all-MiniLM-L6-v2 quantized TFLite — 384-dim, ~6MB, fast on low-end devices.
  // Fallback: swap to MediaPipe BERT embedder if this repo becomes unavailable.
  static const String _modelUrl =
      'https://huggingface.co/Nihal2000/all-MiniLM-L6-v2-quant.tflite/resolve/main/all-MiniLM-L6-v2-quant.tflite';
  static const String _vocabUrl =
      'https://huggingface.co/bert-base-uncased/resolve/main/vocab.txt';

  static const String _modelFilename = 'all_minilm_l6_v2.tflite';
  static const String _vocabFilename = 'vocab.txt';

  /// Returns true if both files already exist (no re-download needed).
  Future<bool> isDownloaded() async {
    final dir = (await getApplicationDocumentsDirectory()).path;
    return File('$dir/$_modelFilename').existsSync() &&
        File('$dir/$_vocabFilename').existsSync();
  }

  /// Download model + vocab if not already present.
  /// Fire-and-forget safe — errors are logged but not rethrown.
  Future<void> downloadIfNeeded() async {
    if (await isDownloaded()) {
      print('📦 Embedding: already downloaded, skipping.');
      return;
    }
    print('📦 Embedding: starting download…');
    try {
      final dir = (await getApplicationDocumentsDirectory()).path;
      await Future.wait([
        _downloadFile(_modelUrl, '$dir/$_modelFilename', 'model'),
        _downloadFile(_vocabUrl, '$dir/$_vocabFilename', 'vocab'),
      ]);
      print('📦 Embedding: download complete ✅');
    } catch (e) {
      print('📦 Embedding: download failed ❌ $e');
      // Non-fatal — EmbeddingService degrades gracefully when files are missing.
    }
  }

  static Future<void> _downloadFile(
      String url, String savePath, String label) async {
    print('📦 Embedding: downloading $label from $url');
    final response = await http.get(Uri.parse(url));
    print('📦 Embedding: $label HTTP ${response.statusCode}');
    if (response.statusCode == 200) {
      await File(savePath).writeAsBytes(response.bodyBytes);
      print('📦 Embedding: $label saved (${response.bodyBytes.length} bytes)');
    } else {
      print('📦 Embedding: $label failed — HTTP ${response.statusCode}');
    }
  }
}
