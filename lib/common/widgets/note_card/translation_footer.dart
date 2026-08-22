import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/common/widgets/note_card/translate_language_sheet.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// The "Translated to X · Show original · Change" strip under a note body.
///
/// Renders nothing until the note is being translated or has been — an
/// untranslated card is byte-for-byte what it was before this feature.
class TranslationFooter extends StatelessWidget {
  const TranslationFooter({super.key});

  Future<void> _changeLanguage(BuildContext context) async {
    final cubit = context.read<NoteCardCubit>();
    final current = TranslationLanguage.fromCode(
      cubit.state.translationLanguage,
    );
    final picked =
        await TranslateLanguageSheet.show(context, initial: current);
    if (picked == null) return;
    // Changing here also changes the remembered default — the user has told
    // us twice now which language they want.
    await getIt<SetTranslationLanguageUseCase>().call(picked.code);
    await cubit.translate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<NoteCardCubit, NoteCardState>(
      listenWhen: (p, c) => p.translationError != c.translationError,
      listener: (context, state) {
        final err = state.translationError;
        if (err == null) return;
        final lang = TranslationLanguage.fromCode(state.translationLanguage);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            err == NoteCardCubit.kAlreadyInTargetLanguage
                ? l10n.translationAlreadyInLanguage(lang.nativeName)
                : l10n.translationFailed,
          ),
          behavior: SnackBarBehavior.floating,
        ));
        context.read<NoteCardCubit>().clearTranslationError();
      },
      buildWhen: (p, c) =>
          p.isTranslating != c.isTranslating ||
          p.translation != c.translation ||
          p.showOriginal != c.showOriginal,
      builder: (context, state) {
        if (!state.isTranslating && state.translation == null) {
          return const SizedBox.shrink();
        }

        final lang = TranslationLanguage.fromCode(state.translationLanguage);
        final labelStyle = TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        );
        final actionStyle = TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        );

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.translate_rounded,
                  size: 13, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  state.isTranslating
                      ? l10n.translatingLabel
                      : l10n.translatedToLabel(lang.nativeName),
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              if (!state.isTranslating && state.translation != null) ...[
                const SizedBox(width: 10),
                _Action(
                  label: state.showOriginal
                      ? l10n.translationShowTranslation
                      : l10n.translationShowOriginal,
                  style: actionStyle,
                  onTap: () => context.read<NoteCardCubit>().toggleOriginal(),
                ),
                const SizedBox(width: 12),
                _Action(
                  label: l10n.translationChangeLanguage,
                  style: actionStyle,
                  onTap: () => _changeLanguage(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.style,
    required this.onTap,
  });
  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // The card's own onTap opens the thread; give these a hit box of their
      // own so a mistap doesn't navigate away instead.
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(label, style: style),
      ),
    );
  }
}
