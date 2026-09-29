import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:uniun/common/snackbar.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// One document passage in Shiv's Sources sheet: file name, where in the file
/// (a PDF's page, a DOCX's heading, or "found in image"), and the passage the
/// answer drew on.
///
/// Tapping opens the file the way an attachment opens elsewhere — a document
/// in the OS viewer, an image in the app's own viewer. Neither can be told
/// where to jump, so the location is shown as text: enough for a reader to
/// find and verify the claim.
class DocumentSourceTile extends StatelessWidget {
  const DocumentSourceTile({super.key, required this.citation});

  final DocumentCitation citation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final kind = citation.kind;
    // A DOCX has no pages; a passage above its first heading has no location
    // at all, and showing an empty "Section:" would claim one.
    final location = switch (kind) {
      DocumentKind.image => l10n.shivSourcesImageFound,
      _ when citation.label.isEmpty => null,
      DocumentKind.pdf => l10n.shivSourcesDocumentPage(citation.label),
      DocumentKind.docx => l10n.shivSourcesDocumentSection(citation.label),
    };
    final untitled = switch (kind) {
      DocumentKind.pdf => l10n.shivSourcesDocumentUntitled,
      DocumentKind.docx => l10n.shivSourcesDocxUntitled,
      DocumentKind.image => l10n.shivSourcesImageUntitled,
    };
    final openLabel = switch (kind) {
      DocumentKind.pdf => l10n.shivSourcesDocumentOpen,
      DocumentKind.docx => l10n.shivSourcesDocxOpen,
      DocumentKind.image => l10n.shivSourcesImageOpen,
    };
    final leading = switch (kind) {
      DocumentKind.pdf => _icon(Icons.picture_as_pdf_outlined, scheme),
      DocumentKind.docx => _icon(Icons.description_outlined, scheme),
      DocumentKind.image => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(citation.localPath),
          width: 44,
          height: 44,
          // Decode at tile size: a camera photo is ~48 MB of pixels at full
          // resolution, for a 44-point square.
          cacheWidth: (44 * MediaQuery.devicePixelRatioOf(context)).round(),
          fit: BoxFit.cover,
          // The cache can lose the file between retrieval and render.
          errorBuilder: (_, __, ___) => _icon(Icons.image_outlined, scheme),
        ),
      ),
    };

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context, l10n),
        child: Tooltip(
          message: openLabel,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        citation.title ?? untitled,
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

  void _open(BuildContext context, AppLocalizations l10n) {
    if (citation.kind != DocumentKind.image) {
      OpenFilex.open(citation.localPath);
      return;
    }
    // The in-app viewer loads by cache row and waits forever when it is gone —
    // which a citation resolved earlier can outlive.
    if (!File(citation.localPath).existsSync()) {
      AppSnackbar.error(context, l10n.shivSourcesImageGone);
      return;
    }
    context.pushNamed(
      AppRoutes.mediaDetail,
      pathParameters: {'sha256': citation.sha256},
    );
  }

  static Widget _icon(IconData icon, ColorScheme scheme) => SizedBox(
    width: 44,
    height: 44,
    child: Icon(icon, size: 22, color: scheme.primary),
  );
}
