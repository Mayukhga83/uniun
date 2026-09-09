part of 'note_card_cubit.dart';

class NoteCardState {
  const NoteCardState({
    this.profile,
    this.isSaved = false,
    this.isFollowed = false,
    this.isOwnNote = false,
    this.isRemoved = false,
    this.translation,
    this.translationLanguage,
    this.isTranslating = false,
    this.showOriginal = false,
    this.translationError,
  });

  /// Author profile (null until loaded / fetched).
  final ProfileEntity? profile;

  /// Whether the active user has saved this note.
  final bool isSaved;

  /// Whether the active user is following this note's reference graph.
  final bool isFollowed;

  /// Whether this note was authored by the active user (hides the Block
  /// action — self-block is meaningless).
  final bool isOwnNote;

  /// Whether the user deleted this note locally — the card collapses itself.
  final bool isRemoved;

  /// Translated body, null if untranslated. In-memory only — never written to
  /// Isar, published, or embedded.
  final String? translation;

  /// BCP-47 code [translation] is in — drives the "Translated to X" footer.
  final String? translationLanguage;

  final bool isTranslating;

  /// User tapped "Show original"; [translation] is retained so toggling back
  /// costs nothing.
  final bool showOriginal;

  /// Set on failure; surfaced as a snackbar, then cleared.
  final String? translationError;

  /// Whether the card should render [translation] in place of the note body.
  bool get showsTranslation => translation != null && !showOriginal;

  NoteCardState copyWith({
    ProfileEntity? profile,
    bool? isSaved,
    bool? isFollowed,
    bool? isOwnNote,
    bool? isRemoved,
    String? translation,
    String? translationLanguage,
    bool? isTranslating,
    bool? showOriginal,
    String? translationError,
    bool clearTranslation = false,
    bool clearTranslationError = false,
  }) {
    return NoteCardState(
      profile: profile ?? this.profile,
      isSaved: isSaved ?? this.isSaved,
      isFollowed: isFollowed ?? this.isFollowed,
      isOwnNote: isOwnNote ?? this.isOwnNote,
      isRemoved: isRemoved ?? this.isRemoved,
      translation: clearTranslation ? null : (translation ?? this.translation),
      translationLanguage: clearTranslation
          ? null
          : (translationLanguage ?? this.translationLanguage),
      isTranslating: isTranslating ?? this.isTranslating,
      showOriginal: clearTranslation ? false : (showOriginal ?? this.showOriginal),
      translationError:
          clearTranslationError ? null : (translationError ?? this.translationError),
    );
  }
}
