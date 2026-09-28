import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/features/shiv/chat/widgets/document_source_tile.dart';
import 'package:uniun/features/shiv/chat/widgets/shiv_sources_sheet.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockResolveNotes extends Mock implements ResolveNotesByIdsUseCase {}

class _MockResolveDocs extends Mock
    implements ResolveDocumentCitationsUseCase {}

/// Covers: ShivSourcesSheet rendering PDF passages as tiles in order, and the
/// empty state.
void main() {
  late _MockResolveDocs docs;
  late _MockResolveNotes notes;

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() async {
    docs = _MockResolveDocs();
    notes = _MockResolveNotes();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<ResolveNotesByIdsUseCase>(notes);
    GetIt.instance.registerSingleton<ResolveDocumentCitationsUseCase>(docs);
  });

  tearDown(() => GetIt.instance.reset());

  Widget host({List<String> chunkIds = const []}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShivSourcesSheet(noteIds: const [], chunkIds: chunkIds),
        ),
      );

  DocumentCitation citation(String id, String snippet,
          {DocumentKind kind = DocumentKind.pdf}) =>
      DocumentCitation(
        chunkId: id,
        sha256: 's',
        kind: kind,
        label: '1',
        snippet: snippet,
        localPath: '/p/doc.pdf',
      );

  testWidgets('chunk ids render as PDF tiles in the order resolved', (t) async {
    when(() => docs.call(any())).thenAnswer((_) async => Right([
          citation('s:0', 'first passage'),
          citation('s:1', 'second passage'),
        ]));

    await t.pumpWidget(host(chunkIds: const ['s:0', 's:1']));
    await t.pumpAndSettle();

    expect(find.byType(DocumentSourceTile), findsNWidgets(2));
    expect(t.getTopLeft(find.text('first passage')).dy,
        lessThan(t.getTopLeft(find.text('second passage')).dy));
  });

  testWidgets('PDF and DOCX passages sit side by side with their locations',
      (t) async {
    when(() => docs.call(any())).thenAnswer((_) async => Right([
          citation('s:0', 'pdf passage'),
          citation('w:0', 'docx passage', kind: DocumentKind.docx),
        ]));

    await t.pumpWidget(host(chunkIds: const ['s:0', 'w:0']));
    await t.pumpAndSettle();

    expect(find.byType(DocumentSourceTile), findsNWidgets(2));
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Section: 1'), findsOneWidget);
  });

  testWidgets('with nothing to show it says so', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.shivSourcesEmpty), findsOneWidget);
    expect(find.byType(DocumentSourceTile), findsNothing);
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  testWidgets('ids that resolve to nothing show the empty state, not a crash',
      (t) async {
    when(() => docs.call(any()))
        .thenAnswer((_) async => const Right(<DocumentCitation>[]));

    await t.pumpWidget(host(chunkIds: const ['gone:0']));
    await t.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.shivSourcesEmpty), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
