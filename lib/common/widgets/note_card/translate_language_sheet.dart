import 'package:flutter/material.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Language picker for note translation.
///
/// Shown on the FIRST Translate tap only — the chosen language is persisted and
/// every later tap translates in one go. Re-openable from the "Change" action
/// on a translated note's footer.
///
/// Returns the picked [TranslationLanguage], or null if dismissed.
class TranslateLanguageSheet extends StatefulWidget {
  const TranslateLanguageSheet({super.key, required this.initial});

  /// Pre-selected on open — the persisted choice, or the app locale on first
  /// run so the common case is confirm-and-go.
  final TranslationLanguage initial;

  static Future<TranslationLanguage?> show(
    BuildContext context, {
    required TranslationLanguage initial,
  }) {
    return showModalBottomSheet<TranslationLanguage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TranslateLanguageSheet(initial: initial),
    );
  }

  @override
  State<TranslateLanguageSheet> createState() => _TranslateLanguageSheetState();
}

class _TranslateLanguageSheetState extends State<TranslateLanguageSheet> {
  late TranslationLanguage _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.translateSheetTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: TranslationLanguage.all.length,
                itemBuilder: (context, i) {
                  final lang = TranslationLanguage.all[i];
                  final isSelected = lang.code == _selected.code;
                  return ListTile(
                    dense: true,
                    onTap: () => setState(() => _selected = lang),
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                    title: Text(
                      lang.nativeName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    // Endonym alone isn't always enough to identify a row, and
                    // the app-language row is worth calling out on first run.
                    subtitle: Text(
                      lang.code == widget.initial.code
                          ? '${lang.englishName} · ${l10n.translateSheetSettingsHint}'
                          : lang.englishName,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text(l10n.translateSheetAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
