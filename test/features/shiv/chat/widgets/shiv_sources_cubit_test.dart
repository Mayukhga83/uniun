import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/features/shiv/chat/widgets/shiv_sources_cubit.dart';

import '../../../../_helpers/fixtures.dart';

class _MockResolveNotes extends Mock implements ResolveNotesByIdsUseCase {}

class _MockResolveDocs extends Mock
    implements ResolveDocumentCitationsUseCase {}

/// Covers: ShivSourcesCubit resolving notes and PDF citations together, empty
/// input, and independent failure of either resolver.
void main() {
  late _MockResolveNotes notes;
  late _MockResolveDocs docs;

  const citation = DocumentCitation(
    chunkId: 's:0',
    sha256: 's',
    kind: DocumentKind.pdf,
    label: '2',
    snippet: 'passage',
    localPath: '/p/doc.pdf',
  );

  ShivSourcesCubit build() =>
      ShivSourcesCubit(resolveNotes: notes, resolveCitations: docs);

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() {
    notes = _MockResolveNotes();
    docs = _MockResolveDocs();
  });

  test('with no ids it loads empty without calling either resolver', () async {
    final cubit = build();

    await cubit.load(const []);

    expect(cubit.state.status, ShivSourcesStatus.loaded);
    expect(cubit.state.isEmpty, isTrue);
    verifyNever(() => notes.call(any()));
    verifyNever(() => docs.call(any()));
    await cubit.close();
  });

  test('chunk ids alone resolve to citations without touching notes', () async {
    when(() => docs.call(any())).thenAnswer((_) async => const Right([citation]));
    final cubit = build();

    await cubit.load(const [], chunkIds: const ['s:0']);

    expect(cubit.state.citations, [citation]);
    expect(cubit.state.notes, isEmpty);
    verifyNever(() => notes.call(any()));
    await cubit.close();
  });

  test('note ids alone resolve without touching documents', () async {
    when(() => notes.call(any())).thenAnswer((_) async => Right([aNote(id: 'n1')]));
    final cubit = build();

    await cubit.load(const ['n1']);

    expect(cubit.state.notes.single.id, 'n1');
    verifyNever(() => docs.call(any()));
    await cubit.close();
  });

  test('notes and chunks resolve together', () async {
    when(() => notes.call(any())).thenAnswer((_) async => Right([aNote(id: 'n1')]));
    when(() => docs.call(any())).thenAnswer((_) async => const Right([citation]));
    final cubit = build();

    await cubit.load(const ['n1'], chunkIds: const ['s:0']);

    expect(cubit.state.notes.single.id, 'n1');
    expect(cubit.state.citations, [citation]);
    expect(cubit.state.isEmpty, isFalse);
    await cubit.close();
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('one resolver failing never hides the other', () {
    test('a citation failure still shows the notes', () async {
      when(() => notes.call(any()))
          .thenAnswer((_) async => Right([aNote(id: 'n1')]));
      when(() => docs.call(any()))
          .thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      final cubit = build();

      await cubit.load(const ['n1'], chunkIds: const ['s:0']);

      expect(cubit.state.status, ShivSourcesStatus.loaded);
      expect(cubit.state.notes, hasLength(1));
      expect(cubit.state.citations, isEmpty);
      await cubit.close();
    });

    test('a note failure still shows the citations', () async {
      when(() => notes.call(any()))
          .thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      when(() => docs.call(any()))
          .thenAnswer((_) async => const Right([citation]));
      final cubit = build();

      await cubit.load(const ['n1'], chunkIds: const ['s:0']);

      expect(cubit.state.notes, isEmpty);
      expect(cubit.state.citations, hasLength(1));
      await cubit.close();
    });

    test('both failing loads an empty but settled state', () async {
      when(() => notes.call(any()))
          .thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      when(() => docs.call(any()))
          .thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      final cubit = build();

      await cubit.load(const ['n1'], chunkIds: const ['s:0']);

      expect(cubit.state.status, ShivSourcesStatus.loaded);
      expect(cubit.state.isEmpty, isTrue);
      await cubit.close();
    });
  });
}
