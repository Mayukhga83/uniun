import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';

enum ShivSourcesStatus { loading, loaded }

class ShivSourcesState {
  const ShivSourcesState({
    this.status = ShivSourcesStatus.loading,
    this.notes = const [],
    this.citations = const [],
  });

  final ShivSourcesStatus status;
  final List<NoteEntity> notes;

  /// PDF passages that grounded the reply, in score order.
  final List<DocumentCitation> citations;

  bool get isEmpty => notes.isEmpty && citations.isEmpty;
}

/// One-shot loader for Shiv's "Sources" sheet: resolves the RAG source-note ids
/// and PDF chunk ids of the last reply into displayable sources.
///
/// Never blocks the UI — either resolution failing degrades to whatever did
/// resolve, so a broken document store cannot hide the source notes.
///
/// Dependencies are constructor-injected (defaulting to the locator) so the
/// resolution paths are testable without driving a service locator.
class ShivSourcesCubit extends Cubit<ShivSourcesState> {
  ShivSourcesCubit({
    ResolveNotesByIdsUseCase? resolveNotes,
    ResolveDocumentCitationsUseCase? resolveCitations,
  })  : _resolveNotes = resolveNotes ?? getIt<ResolveNotesByIdsUseCase>(),
        _resolveCitations =
            resolveCitations ?? getIt<ResolveDocumentCitationsUseCase>(),
        super(const ShivSourcesState());

  final ResolveNotesByIdsUseCase _resolveNotes;
  final ResolveDocumentCitationsUseCase _resolveCitations;

  Future<void> load(
    List<String> noteIds, {
    List<String> chunkIds = const [],
  }) async {
    if (noteIds.isEmpty && chunkIds.isEmpty) {
      emit(const ShivSourcesState(status: ShivSourcesStatus.loaded));
      return;
    }

    var notes = <NoteEntity>[];
    if (noteIds.isNotEmpty) {
      final result = await _resolveNotes.call(noteIds);
      notes = result.fold((_) => <NoteEntity>[], (n) => n);
    }

    var citations = <DocumentCitation>[];
    if (chunkIds.isNotEmpty) {
      final result = await _resolveCitations.call(chunkIds);
      citations = result.fold((_) => <DocumentCitation>[], (c) => c);
    }

    if (isClosed) return;
    emit(ShivSourcesState(
      status: ShivSourcesStatus.loaded,
      notes: notes,
      citations: citations,
    ));
  }
}
