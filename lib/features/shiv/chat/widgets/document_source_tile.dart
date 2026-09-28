import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// One document passage in Shiv's Sources sheet: file name, where in the file
/// (a PDF's page, or a DOCX's heading), and the passage the answer drew on.
///
/// Tapping opens the cached file in the OS viewer, exactly as an attachment
/// does elsewhere. The viewer cannot be told where to jump, so the location is
/// shown as text — enough for a reader to find and verify the claim.
class DocumentSourceTile extends StatelessWidget {
  const DocumentSourceTile({super.key, required this.citation});

  final DocumentCitation citation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isPdf = citation.kind == DocumentKind.pdf;
    // A DOCX has no pages; a passage above its first heading has no location
    // at all, and showing an empty "Section:" would claim one.
    final location = citation.label.isEmpty
        ? null
        : isPdf
        ? l10n.shivSourcesDocumentPage(citation.label)
        : l10n.shivSourcesDocumentSection(citation.label);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => OpenFilex.open(citation.localPath),
        child: Tooltip(
          message: isPdf
              ? l10n.shivSourcesDocumentOpen
              : l10n.shivSourcesDocxOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  size: 22,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        citation.title ??
                            (isPdf
                                ? l10n.shivSourcesDocumentUntitled
                                : l10n.shivSourcesDocxUntitled),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (location != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          location,
                          style: TextStyle(fontSize: 12, color: scheme.primary),
                        ),
                      ],
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
