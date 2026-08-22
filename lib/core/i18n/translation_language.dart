/// Target languages offered by the note-translation feature.
///
/// Deliberately NOT tied to [AppLocalizations.supportedLocales] — that list is
/// the languages UNIUN's own UI is translated into (currently en + hi), while
/// this is the set a user may want a *note* rendered in. The model does the
/// work, so the list is limited only by what the active model handles well.
///
/// [nativeName] is what the picker shows: a user looking for their language
/// scans for "हिन्दी", not "Hindi".
class TranslationLanguage {
  const TranslationLanguage(this.code, this.englishName, this.nativeName);

  /// BCP-47 primary subtag — also what gets persisted in settings.
  final String code;

  /// Name handed to the model in the prompt (models respond far more reliably
  /// to "Hindi" than to "hi").
  final String englishName;

  /// Endonym, shown in the picker and on the translated-note footer.
  final String nativeName;

  static const List<TranslationLanguage> all = [
    TranslationLanguage('en', 'English', 'English'),
    TranslationLanguage('hi', 'Hindi', 'हिन्दी'),
    TranslationLanguage('bn', 'Bengali', 'বাংলা'),
    TranslationLanguage('ta', 'Tamil', 'தமிழ்'),
    TranslationLanguage('te', 'Telugu', 'తెలుగు'),
    TranslationLanguage('mr', 'Marathi', 'मराठी'),
    TranslationLanguage('gu', 'Gujarati', 'ગુજરાતી'),
    TranslationLanguage('kn', 'Kannada', 'ಕನ್ನಡ'),
    TranslationLanguage('ml', 'Malayalam', 'മലയാളം'),
    TranslationLanguage('pa', 'Punjabi', 'ਪੰਜਾਬੀ'),
    TranslationLanguage('ur', 'Urdu', 'اردو'),
    TranslationLanguage('ar', 'Arabic', 'العربية'),
    TranslationLanguage('es', 'Spanish', 'Español'),
    TranslationLanguage('fr', 'French', 'Français'),
    TranslationLanguage('de', 'German', 'Deutsch'),
    TranslationLanguage('pt', 'Portuguese', 'Português'),
    TranslationLanguage('ru', 'Russian', 'Русский'),
    TranslationLanguage('ja', 'Japanese', '日本語'),
    TranslationLanguage('ko', 'Korean', '한국어'),
    TranslationLanguage('zh', 'Chinese', '中文'),
    TranslationLanguage('id', 'Indonesian', 'Bahasa Indonesia'),
    TranslationLanguage('tr', 'Turkish', 'Türkçe'),
  ];

  /// Falls back to English rather than returning null — every caller here has
  /// to translate into *something*, and a stored code can outlive its entry
  /// (list trimmed, or a locale like `zh-Hant` narrowed to `zh`).
  static TranslationLanguage fromCode(String? code) {
    if (code == null) return all.first;
    final primary = code.split(RegExp('[-_]')).first.toLowerCase();
    for (final l in all) {
      if (l.code == primary) return l;
    }
    return all.first;
  }
}
