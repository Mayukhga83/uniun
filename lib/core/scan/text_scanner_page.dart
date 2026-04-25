import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uniun/core/scan/uniun_payload.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/l10n/app_localizations.dart';

class TextScannerPage extends StatefulWidget {
  const TextScannerPage({super.key});

  @override
  State<TextScannerPage> createState() => _TextScannerPageState();
}

class _TextScannerPageState extends State<TextScannerPage> {
  CameraController? _controller;
  bool _permissionDenied = false;
  bool _scanning = false;
  String? _errorMessage;

  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _recognizer.close();
    super.dispose();
  }

  Future<void> _init() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      back,
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _captureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized || _scanning) {
      return;
    }

    setState(() {
      _scanning = true;
      _errorMessage = null;
    });

    try {
      final file = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final result = await _recognizer.processImage(inputImage);

      // Clean up temp file
      try { await File(file.path).delete(); } catch (_) {}

      if (!mounted) return;

      final parsed = UniunPayload.decode(result.text);
      if (parsed != null) {
        await _showResult(parsed);
      } else {
        setState(() => _errorMessage = AppLocalizations.of(context)!.scanInvalid);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Scan failed — try again');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _showResult(UniunDecoded result) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ScanResultSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(l10n.scanPageTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l10n.scanPermissionDenied,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final isReady = _controller != null && _controller!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.scanPageTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isReady
          ? Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),

                // ── Error banner ─────────────────────────────────────────
                if (_errorMessage != null)
                  Positioned(
                    top: 16,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // ── Hint ─────────────────────────────────────────────────
                Positioned(
                  bottom: 120,
                  left: 32,
                  right: 32,
                  child: Text(
                    l10n.scanPageHint,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

                // ── Capture button ────────────────────────────────────────
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _captureAndScan,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                              color: AppColors.primary, width: 4),
                        ),
                        child: _scanning
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                    color: AppColors.primary, strokeWidth: 3),
                              )
                            : const Icon(Icons.camera_alt_rounded,
                                color: AppColors.primary, size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
    );
  }
}

// ── Scan result bottom sheet ───────────────────────────────────────────────────

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({required this.result});

  final UniunDecoded result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isChannel = result.kind == UniunCardKind.channel;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.scanResultTitle,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isChannel
                      ? l10n.scanResultChannelLabel
                      : l10n.scanResultUserLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.fields.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '${e.key}: ',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant),
                      ),
                      TextSpan(
                        text: e.value,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface,
                            fontFamily: 'monospace'),
                      ),
                    ]),
                    softWrap: true,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.scanResultClose),
                ),
              ),
              if (isChannel) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.scanResultOpenChannel),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
