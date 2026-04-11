import 'package:flutter/material.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// A single chat bubble — user on the right, Shiv on the left.
/// Matches the "Ethereal Interface" design: gradient user bubble,
/// surface-container-lowest Shiv card with ambient tinted shadow.
class ShivMessageBubble extends StatelessWidget {
  const ShivMessageBubble({
    super.key,
    required this.message,
    this.streamingContent,
  });

  final ShivMessageEntity message;

  /// Non-null only while this is the live-streaming assistant bubble.
  final String? streamingContent;

  bool get _isUser => message.role == MessageRole.user;

  String get _displayText => streamingContent ?? message.content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: _isUser ? 56 : 16,
        right: _isUser ? 16 : 56,
        bottom: 24,
      ),
      child: _isUser ? _UserBubble(text: _displayText) : _ShivBubble(text: _displayText, isStreaming: streamingContent != null),
    );
  }
}

// ── User bubble ─────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
              topRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(DateTime.now()),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

// ── Shiv bubble ─────────────────────────────────────────────────────────────

class _ShivBubble extends StatelessWidget {
  const _ShivBubble({required this.text, required this.isStreaming});
  final String text;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + label row
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Builder(
              builder: (context) => Text(
                AppLocalizations.of(context)!.shivName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Message card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: isStreaming && text.isEmpty
              ? const _TypingIndicator()
              : _MarkdownText(text: text),
        ),
      ],
    );
  }
}

// ── Lightweight markdown renderer ────────────────────────────────────────────
// Handles: **bold**, *italic*, `code`, # headers, - bullet lists.
// Everything else is rendered as plain text.

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text});
  final String text;

  static const _base = TextStyle(
    fontSize: 15,
    height: 1.6,
    color: AppColors.onSurface,
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Heading: # / ## / ###
      final headMatch = RegExp(r'^(#{1,3})\s+(.+)').firstMatch(line);
      if (headMatch != null) {
        final level = headMatch.group(1)!.length;
        final content = headMatch.group(2)!;
        widgets.add(Padding(
          padding: EdgeInsets.only(top: i > 0 ? 8 : 0, bottom: 2),
          child: Text(
            content,
            style: _base.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: level == 1 ? 18 : level == 2 ? 16 : 15,
            ),
          ),
        ));
        continue;
      }

      // Bullet: - item or * item
      final bulletMatch = RegExp(r'^[\-\*]\s+(.+)').firstMatch(line);
      if (bulletMatch != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: _base.copyWith(fontWeight: FontWeight.w600)),
              Expanded(child: _InlineText(text: bulletMatch.group(1)!, base: _base)),
            ],
          ),
        ));
        continue;
      }

      // Empty line → spacing
      if (line.trim().isEmpty) {
        if (i > 0 && i < lines.length - 1) widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Regular paragraph with inline formatting
      widgets.add(_InlineText(text: line, base: _base));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

/// Renders inline markdown: **bold**, *italic*, `code`.
class _InlineText extends StatelessWidget {
  const _InlineText({required this.text, required this.base});
  final String text;
  final TextStyle base;

  @override
  Widget build(BuildContext context) {
    return Text.rich(_parseInline(text, base));
  }

  static TextSpan _parseInline(String input, TextStyle base) {
    // Pattern priority: **bold**, *italic*, `code`
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    int cursor = 0;

    for (final m in pattern.allMatches(input)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: input.substring(cursor, m.start), style: base));
      }
      if (m.group(1) != null) {
        // **bold**
        spans.add(TextSpan(text: m.group(1), style: base.copyWith(fontWeight: FontWeight.w700)));
      } else if (m.group(2) != null) {
        // *italic*
        spans.add(TextSpan(text: m.group(2), style: base.copyWith(fontStyle: FontStyle.italic)));
      } else if (m.group(3) != null) {
        // `code`
        spans.add(TextSpan(
          text: m.group(3),
          style: base.copyWith(
            fontFamily: 'monospace',
            backgroundColor: AppColors.onSurface.withValues(alpha: 0.08),
            fontSize: 13,
          ),
        ));
      }
      cursor = m.end;
    }
    if (cursor < input.length) {
      spans.add(TextSpan(text: input.substring(cursor), style: base));
    }

    return TextSpan(children: spans);
  }
}

// ── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => _Dot(delay: Duration(milliseconds: i * 200)),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});
  final Duration delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FadeTransition(
        opacity: _anim,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
