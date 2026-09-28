import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// One PDF passage in Shiv's Sources sheet: file name, page, and the passage
/// the answer drew on.
///
/// Tapping opens the cached PDF in the OS viewer, exactly as an attachment does
/// elsewhere. The viewer cannot be told to jump to a page, so the page is shown
/// as text — enough for a reader to find and verify the claim.
class DocumentSourceTile extends StatelessWidget {
  const DocumentSourceTile({super.key, required this.citation});

  final DocumentCitation citation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => OpenFilex.open(citation.localPath),
        child: Tooltip(
          message: l10n.shivSourcesDocumentOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 22,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        citation.title ?? l10n.shivSourcesDocumentUntitled,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.shivSourcesDocumentPage(citation.label),
                        style: TextStyle(fontSize: 12, color: scheme.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        citation.snippet,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: context.custom.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
