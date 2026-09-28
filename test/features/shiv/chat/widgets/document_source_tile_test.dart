import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/features/shiv/chat/widgets/document_source_tile.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: PDF source tile title, page label, snippet, untitled fallback, and
/// overflow safety.
void main() {
  Widget host(DocumentCitation c) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DocumentSourceTile(citation: c)),
      );

  DocumentCitation citation({String? title, String label = '4'}) =>
      DocumentCitation(
        chunkId: 's:0',
        sha256: 's',
        label: label,
        snippet: 'Employees may carry forward ten days of leave.',
        localPath: '/p/doc.pdf',
        title: title,
      );

  testWidgets('shows the title, the page and the passage', (t) async {
    await t.pumpWidget(host(citation(title: 'Leave Circular.pdf')));

    expect(find.text('Leave Circular.pdf'), findsOneWidget);
    expect(find.text('Page 4'), findsOneWidget);
    expect(find.text('Employees may carry forward ten days of leave.'),
        findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });

  testWidgets('without a title it falls back to the generic label', (t) async {
    await t.pumpWidget(host(citation()));

    expect(find.text('PDF document'), findsOneWidget);
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  testWidgets('a very long passage is clipped, not overflowing', (t) async {
    await t.pumpWidget(host(DocumentCitation(
      chunkId: 's:0',
      sha256: 's',
      label: '1',
      snippet: 'word ' * 400,
      localPath: '/p/doc.pdf',
    )));

    expect(t.takeException(), isNull);
  });

  testWidgets('a very long title is clipped, not overflowing', (t) async {
    await t.pumpWidget(host(citation(title: 'circular-${'x' * 300}.pdf')));

    expect(t.takeException(), isNull);
  });

  testWidgets('unicode and RTL content render without error', (t) async {
    await t.pumpWidget(host(DocumentCitation(
      chunkId: 's:0',
      sha256: 's',
      label: '२',
      snippet: 'भारत सरकार की नीति — مرحبا 😀',
      localPath: '/p/doc.pdf',
      title: 'परिपत्र.pdf',
    )));

    expect(find.text('परिपत्र.pdf'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
