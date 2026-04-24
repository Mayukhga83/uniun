import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Bottom input bar.
/// Sits inside a Scaffold with resizeToAvoidBottomInset: true — the scaffold
/// handles keyboard avoidance. We only add safe-area bottom padding (home bar).
class ShivInputComposer extends StatefulWidget {
  const ShivInputComposer({
    super.key,
    required this.onSend,
    required this.onStop,
    required this.isStreaming,
  });

  final void Function(String text) onSend;
  final VoidCallback onStop;
  final bool isStreaming;

  @override
  State<ShivInputComposer> createState() => _ShivInputComposerState();
}

class _ShivInputComposerState extends State<ShivInputComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isStreaming) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _hasText && !widget.isStreaming;
    final isStreaming = widget.isStreaming;
    final l10n = AppLocalizations.of(context)!;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // When keyboard is open: pad by keyboard height + 10px gap so input sits above keyboard.
    // When keyboard is closed: pad 104px to float above the floating nav.
    final bottomPad = keyboardHeight > 0 ? keyboardHeight + 10.0 : 104.0;

    return Container(
      color: AppColors.surfaceContainerLow,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: canSend
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.outlineVariant,
            width: canSend ? 1 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field — no attach button
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: l10n.shivInputHint,
                  hintStyle: const TextStyle(
                    color: AppColors.outline,
                    fontSize: 15,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            // Send / Stop button — swaps while streaming so the user can
            // interrupt long responses.
            Padding(
              padding: const EdgeInsets.all(6),
              child: GestureDetector(
                onTap: isStreaming
                    ? widget.onStop
                    : (canSend ? _submit : null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isStreaming || canSend
                        ? AppColors.primary
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: (isStreaming || canSend)
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    isStreaming
                        ? Icons.stop_rounded
                        : Icons.send_rounded,
                    size: isStreaming ? 20 : 18,
                    color: (isStreaming || canSend)
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
