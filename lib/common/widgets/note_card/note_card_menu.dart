import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/common/widgets/note_card/translate_language_sheet.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/features/brahma/manas/widgets/manas_membership_sheet.dart';
import 'package:uniun/features/moderation/pages/report_sheet_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Top-right overflow menu shared by [NoteCard] and [LargeNoteCard].
///
/// Items (rendered top-down):
///   • "Add to Manas" (always) — opens the membership sheet for this note.
///     A Manas only surfaces a note that survives retention, so a note that
///     isn't the active user's is saved first (own notes are kept forever, so
///     they're added directly). See [NoteCardCubit.ensureSavedForManas].
///   • "Translate" (always) — translates the body in place. The language is
///     asked for once, then reused; see [_onTranslate].
///   • Destructive "Delete note" (always) + "Block user" (when the note
///     isn't authored by the active user).
class NoteCardMenu extends StatelessWidget {
  const NoteCardMenu({
    super.key,
    required this.cubit,
    required this.isOwnNote,
    required this.displayName,
    this.onDelete,
  });

  final NoteCardCubit cubit;
  final bool isOwnNote;
  final String displayName;

  /// Overrides what "Delete note" does. When null the default applies (suppress
  /// the note in the unified `Note` store via the cubit). Surfaces backed by a
  /// different store — e.g. the Surrounding feed — pass their own deleter here.
  /// Either way the card collapses itself on success.
  final Future<Either<Failure, Unit>> Function()? onDelete;

  Future<void> _onReport(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await ReportSheetPage.show(
      context,
      targetEventId: cubit.note.id,
      targetPubkey: cubit.note.authorPubkey,
    );
    if (result == null) return;

    // Always hide the reported note locally — this collapses the card
    // immediately via NoteCardState.isRemoved (same path as the "Delete note"
    // menu item). The published Kind-1984 event keeps existing on the relay;
    // this is purely the reporter's local view.
    await cubit.deleteNote();
    // Optional escalation: drop every future event from this pubkey at the
    // gateway. Best-effort — a failure here doesn't undo the report.
    if (result.alsoBlock) {
      await cubit.blockUser();
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.reportSentSnackbar)),
    );
  }

  Future<void> _onBlock(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final result = await cubit.blockUser();
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(
          content: Text(failure.toMessage()),
          backgroundColor: errorColor,
        ),
      ),
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.blockUserSnackbar(displayName))),
      ),
    );
  }

  Future<void> _onManas(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final saved = await cubit.ensureSavedForManas();
    if (!saved) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.noteCardManasSaveFailed),
          backgroundColor: errorColor,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    ManasMembershipSheet.show(context, cubit.note.id);
  }

  /// Translate this note.
  ///
  /// The picker opens on EVERY translate, preselected with the last language
  /// used (app locale on first run), so confirming is one tap but the target
  /// is never a surprise — the previous "ask once, then silently reuse"
  /// behaviour made a wrong stored language impossible to notice. See #43.
  Future<void> _onTranslate(BuildContext context) async {
    final stored = await getIt<GetTranslationLanguageUseCase>().call();
    final storedCode = stored.fold((_) => null, (c) => c);
    if (!context.mounted) return;

    // Fall back to the app locale only until the user has chosen once.
    final seed = TranslationLanguage.fromCode(
      storedCode ?? Localizations.localeOf(context).languageCode,
    );
    final picked = await TranslateLanguageSheet.show(
      context,
      initial: seed,
      seededFromAppLocale: storedCode == null,
    );
    if (picked == null) return;

    if (picked.code != storedCode) {
      await getIt<SetTranslationLanguageUseCase>().call(picked.code);
    }
    await cubit.translate(picked);
  }

  Future<void> _onDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final result = await cubit.deleteNote(onDelete);
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(
          content: Text(failure.toMessage()),
          backgroundColor: errorColor,
        ),
      ),
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.deleteNoteSnackbar)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      padding: const EdgeInsets.all(10),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      elevation: 8,
      color: colorScheme.surface,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      onSelected: (value) {
        if (value == 'manas') _onManas(context);
        if (value == 'translate') _onTranslate(context);
        if (value == 'report') _onReport(context);
        if (value == 'block') _onBlock(context);
        if (value == 'delete') _onDelete(context);
      },
      child: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: colorScheme.outline,
      ),
      itemBuilder: (context) => [
        _neutralItem(colorScheme, 'manas', Icons.man_3_rounded,
            l10n.noteCardAddToManas),
        _neutralItem(colorScheme, 'translate', Icons.translate_rounded,
            l10n.noteCardTranslate),
        const PopupMenuDivider(),
        _destructiveItem(colorScheme, 'delete', Icons.delete_outline_rounded,
            l10n.noteCardDeleteNote),
        if (!isOwnNote) ...[
          _destructiveItem(
              colorScheme, 'report', Icons.flag_outlined, l10n.noteCardReport),
          _destructiveItem(colorScheme, 'block', Icons.block_rounded,
              l10n.noteCardBlockUser),
        ],
      ],
    );
  }

  /// Non-destructive row (primary-coloured) — used for "Add to Manas".
  PopupMenuItem<String> _neutralItem(
      ColorScheme colorScheme, String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Compact, uniform destructive menu row.
  PopupMenuItem<String> _destructiveItem(
      ColorScheme colorScheme, String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: colorScheme.error),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
