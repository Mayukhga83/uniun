import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';

enum SurroundingStatus { initial, loading, loaded }

class SurroundingState {
  const SurroundingState({
    this.status = SurroundingStatus.initial,
    this.notes = const [],
    this.hasMoreOlder = false,
    this.isLoadingOlder = false,
    this.isLoadingNewer = false,
  });

  final SurroundingStatus status;

  /// All loaded items, oldest→newest by `receivedAt`. The feed renders them
  /// chat-style (newest at the bottom), so the page displays them reversed.
  final List<SurroundingNoteEntity> notes;

  /// More older notes exist above the loaded range (scroll up to load them).
  final bool hasMoreOlder;

  /// An older page is being prepended (scroll-up pagination).
  final bool isLoadingOlder;

  /// A newer page (mesh arrival) is being appended at the bottom.
  final bool isLoadingNewer;

  SurroundingState copyWith({
    SurroundingStatus? status,
    List<SurroundingNoteEntity>? notes,
    bool? hasMoreOlder,
    bool? isLoadingOlder,
    bool? isLoadingNewer,
  }) {
    return SurroundingState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isLoadingNewer: isLoadingNewer ?? this.isLoadingNewer,
    );
  }
}
