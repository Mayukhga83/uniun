import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/features/shiv/chat/widgets/document_source_tile.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: document source tile title, location (page for PDF, heading for
/// DOCX), snippet, per-kind icon and untitled fallback, and overflow safety.
void main() {
  Widget host(DocumentCitation c) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DocumentSourceTile(citation: c)),
      );

  DocumentCitation citation({
    String? title,
    String label = '4',
    DocumentKind kind = DocumentKind.pdf,
  }) =>
      DocumentCitation(
        chunkId: 's:0',
        sha256: 's',
        kind: kind,
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

  testWidgets('a DOCX shows its section, not a page, with a document icon',
      (t) async {
    await t.pumpWidget(host(citation(
        title: 'Leave Policy.docx',
        label: 'Annual Leave',
        kind: DocumentKind.docx)));

    expect(find.text('Section: Annual Leave'), findsOneWidget);
    expect(find.textContaining('Page'), findsNothing);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
  });

  testWidgets('a DOCX without a title falls back to "Word document"',
      (t) async {
    await t.pumpWidget(
        host(citation(label: 'Annual Leave', kind: DocumentKind.docx)));

    expect(find.text('Word document'), findsOneWidget);
  });

  testWidgets('each kind has its own open tooltip', (t) async {
    await t.pumpWidget(host(citation(kind: DocumentKind.docx)));
    expect(find.byTooltip('Open document'), findsOneWidget);

    await t.pumpWidget(host(citation()));
    expect(find.byTooltip('Open PDF'), findsOneWidget);
  });

  testWidgets('a passage with no heading shows no location line', (t) async {
    await t.pumpWidget(host(citation(
        title: 'Memo.docx', label: '', kind: DocumentKind.docx)));

    expect(find.textContaining('Section'), findsNothing);
    expect(find.textContaining('Page'), findsNothing);
    expect(find.text('Employees may carry forward ten days of leave.'),
        findsOneWidget);
  });

  testWidgets('the Hindi locale localises the section line', (t) async {
    await t.pumpWidget(MaterialApp(
      locale: const Locale('hi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DocumentSourceTile(
            citation: citation(label: 'वार्षिक अवकाश', kind: DocumentKind.docx)),
      ),
    ));
    await t.pumpAndSettle();

    expect(find.text('अनुभाग: वार्षिक अवकाश'), findsOneWidget);
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  testWidgets('a very long passage is clipped, not overflowing', (t) async {
    await t.pumpWidget(host(DocumentCitation(
      chunkId: 's:0',
      sha256: 's',
      kind: DocumentKind.pdf,
      label: '1',
      snippet: 'word ' * 400,
      localPath: '/p/doc.pdf',
    )));

    expect(t.takeException(), isNull);
  });

  testWidgets('a 100-char heading wraps without overflowing', (t) async {
    await t.pumpWidget(host(citation(
        label: '${('Heading ' * 13).substring(0, 99)}…',
        kind: DocumentKind.docx)));

    expect(t.takeException(), isNull);
  });

  testWidgets('a very long title is clipped, not overflowing', (t) async {
    await t.pumpWidget(host(citation(title: 'circular-${'x' * 300}.pdf')));

    expect(t.takeException(), isNull);
  });

  testWidgets('unicode and RTL content render without error', (t) async {
    await t.pumpWidget(host(const DocumentCitation(
      chunkId: 's:0',
      sha256: 's',
      kind: DocumentKind.pdf,
      label: '२',
      snippet: 'भारत सरकार की नीति — مرحبا 😀',
      localPath: '/p/doc.pdf',
      title: 'परिपत्र.pdf',
    )));

    expect(find.text('परिपत्र.pdf'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
