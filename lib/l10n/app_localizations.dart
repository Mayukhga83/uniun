import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App version string shown in settings / footer
  ///
  /// In en, this message translates to:
  /// **'UNIUN v1.0.0-beta'**
  String get appVersion;

  /// Hero tagline on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Your notes, your\nnetwork, your identity.'**
  String get appTagline;

  /// Floating nav label for the feed tab
  ///
  /// In en, this message translates to:
  /// **'VISHNU'**
  String get navVishnu;

  /// Floating nav label for the create-note tab
  ///
  /// In en, this message translates to:
  /// **'BRAHMA'**
  String get navBrahma;

  /// Floating nav label for the AI assistant tab
  ///
  /// In en, this message translates to:
  /// **'SHIV'**
  String get navShiv;

  /// Copy button label (uppercase)
  ///
  /// In en, this message translates to:
  /// **'COPY'**
  String get actionCopy;

  /// Feedback after copying
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get actionCopied;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Continue button in onboarding
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Save / bookmark action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// State when note is bookmarked
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get actionSaved;

  /// Follow a note
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get actionFollow;

  /// State when following a note
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get actionFollowing;

  /// Drawer nav item — home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawerHome;

  /// Drawer nav item — saved notes
  ///
  /// In en, this message translates to:
  /// **'Saved Notes'**
  String get drawerSavedNotes;

  /// Drawer section header — channels
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get drawerChannels;

  /// Drawer section header — DMs
  ///
  /// In en, this message translates to:
  /// **'Direct Messages'**
  String get drawerDirectMessages;

  /// Drawer section header — apps
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get drawerApps;

  /// Drawer apps item — AI
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get drawerAiAssistant;

  /// Drawer footer — settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// Drawer section header — followed notes (uppercase)
  ///
  /// In en, this message translates to:
  /// **'FOLLOWING NOTES'**
  String get drawerFollowingNotes;

  /// Empty state for followed notes in drawer
  ///
  /// In en, this message translates to:
  /// **'No followed notes yet'**
  String get drawerNoFollowedNotes;

  /// Empty state for channels in drawer
  ///
  /// In en, this message translates to:
  /// **'No channels yet'**
  String get drawerNoChannels;

  /// Placeholder text in the channel message composer input
  ///
  /// In en, this message translates to:
  /// **'Message channel…'**
  String get channelMessageHint;

  /// Empty state for DMs in drawer
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get drawerNoMessages;

  /// Card sheet action button
  ///
  /// In en, this message translates to:
  /// **'Copy npub'**
  String get drawerCopyNpub;

  /// Snackbar after copying npub
  ///
  /// In en, this message translates to:
  /// **'npub copied'**
  String get drawerNpubCopied;

  /// Drawer header tooltip — show profile card
  ///
  /// In en, this message translates to:
  /// **'My Card'**
  String get drawerShowCard;

  /// Drawer header tooltip — scan a UNIUN card
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get drawerScanCard;

  /// Title of the ML Kit text scanner page
  ///
  /// In en, this message translates to:
  /// **'Scan UNIUN Card'**
  String get scanPageTitle;

  /// Hint label on the scanner page
  ///
  /// In en, this message translates to:
  /// **'Point camera at a UNIUN card'**
  String get scanPageHint;

  /// Snackbar when a channel card is scanned
  ///
  /// In en, this message translates to:
  /// **'Channel found'**
  String get scanChannelFound;

  /// Snackbar when a user card is scanned
  ///
  /// In en, this message translates to:
  /// **'User found'**
  String get scanUserFound;

  /// Snackbar when scan finds unrecognised text
  ///
  /// In en, this message translates to:
  /// **'No UNIUN card detected'**
  String get scanInvalid;

  /// Snackbar when camera permission denied
  ///
  /// In en, this message translates to:
  /// **'Camera permission required to scan'**
  String get scanPermissionDenied;

  /// Machine-readable header on user card (must stay uppercase, scanner detects this exact text)
  ///
  /// In en, this message translates to:
  /// **'UNIUN USER CARD'**
  String get cardUserHeader;

  /// Machine-readable header on channel card (must stay uppercase, scanner detects this exact text)
  ///
  /// In en, this message translates to:
  /// **'UNIUN CHANNEL CARD'**
  String get cardChannelHeader;

  /// Title label on the channel info card widget
  ///
  /// In en, this message translates to:
  /// **'Channel Card'**
  String get channelCardTitle;

  /// Title label on the user profile card widget
  ///
  /// In en, this message translates to:
  /// **'User Card'**
  String get userCardTitle;

  /// Hint under any UNIUN card
  ///
  /// In en, this message translates to:
  /// **'Scan this card with UNIUN to connect'**
  String get userCardScanHint;

  /// Bottom sheet title when a UNIUN card is scanned
  ///
  /// In en, this message translates to:
  /// **'Card Detected'**
  String get scanResultTitle;

  /// Label above the raw OCR dump in the scan result sheet
  ///
  /// In en, this message translates to:
  /// **'Scanned data'**
  String get scanResultRawLabel;

  /// Type badge in scan result sheet
  ///
  /// In en, this message translates to:
  /// **'Type: Channel'**
  String get scanResultChannelLabel;

  /// Type badge in scan result sheet
  ///
  /// In en, this message translates to:
  /// **'Type: User'**
  String get scanResultUserLabel;

  /// Close button on scan result sheet
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get scanResultClose;

  /// CTA on channel scan result sheet
  ///
  /// In en, this message translates to:
  /// **'Open Channel'**
  String get scanResultOpenChannel;

  /// Snackbar for unimplemented features
  ///
  /// In en, this message translates to:
  /// **'{feature} — coming soon'**
  String drawerComingSoon(String feature);

  /// Title of the create-note screen
  ///
  /// In en, this message translates to:
  /// **'Brahma'**
  String get brahmaTitle;

  /// Brahma header tagline shown below the title
  ///
  /// In en, this message translates to:
  /// **'Write & publish to Nostr'**
  String get brahmaTagline;

  /// Placeholder in the note compose field
  ///
  /// In en, this message translates to:
  /// **'Write a new note...'**
  String get brahmaHintText;

  /// Placeholder in the note subject field
  ///
  /// In en, this message translates to:
  /// **'Subject (optional)'**
  String get brahmaSubjectHintText;

  /// Tooltip for attach-image button
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get brahmaAddImage;

  /// Tooltip for tag-people button
  ///
  /// In en, this message translates to:
  /// **'Tag People'**
  String get brahmaTagPeople;

  /// Tooltip for the mention icon in the compose bar
  ///
  /// In en, this message translates to:
  /// **'Mention a Note'**
  String get brahmaReferenceNote;

  /// Title of the mention-search bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Mention a Note'**
  String get brahmaMentionSheetTitle;

  /// Hint text in the mention search field
  ///
  /// In en, this message translates to:
  /// **'Search notes…'**
  String get brahmaMentionSearchHint;

  /// Empty state in mention search results
  ///
  /// In en, this message translates to:
  /// **'No notes found'**
  String get brahmaMentionEmpty;

  /// Badge shown on an already-selected note in the search sheet
  ///
  /// In en, this message translates to:
  /// **'Mentioned'**
  String get brahmaMentionSelected;

  /// Submit button in the compose card
  ///
  /// In en, this message translates to:
  /// **'Create Note'**
  String get brahmaCreateNote;

  /// Fallback error message when publishing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to publish'**
  String get brahmaFailedToPublish;

  /// Section header above the graph preview canvas
  ///
  /// In en, this message translates to:
  /// **'REFERENCE GRAPH PREVIEW'**
  String get brahmaGraphPreviewLabel;

  /// Badge on the graph preview canvas
  ///
  /// In en, this message translates to:
  /// **'Interactive Preview'**
  String get brahmaInteractivePreview;

  /// Save as draft button label
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get brahmaDraft;

  /// Feedback after saving a draft
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get brahmaDraftSaved;

  /// Section header for drafts list
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get brahmaDrafts;

  /// Publish draft button in draft list
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get brahmaPublish;

  /// Tag count display in draft item
  ///
  /// In en, this message translates to:
  /// **'tags'**
  String get brahmaTags;

  /// Empty-feed heading
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get vishnuNoNotes;

  /// Empty-feed body text
  ///
  /// In en, this message translates to:
  /// **'Create your first note in Brahma\nor wait for the relay to sync.'**
  String get vishnuCreateFirst;

  /// Thread indicator badge on note cards
  ///
  /// In en, this message translates to:
  /// **'THREAD'**
  String get vishnuThread;

  /// Reference count badge on note cards
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 REFERENCE} other{{count} REFERENCES}}'**
  String vishnuReferences(num count);

  /// Shown when a referenced note is not in local Isar
  ///
  /// In en, this message translates to:
  /// **'Referenced note not available'**
  String get vishnuReferenceUnavailable;

  /// Placeholder title for the Shiv tab
  ///
  /// In en, this message translates to:
  /// **'Shiv — AI Assistant'**
  String get homeShivTitle;

  /// Placeholder body for the Shiv tab
  ///
  /// In en, this message translates to:
  /// **'On-device AI coming soon.'**
  String get homeShivComingSoon;

  /// Thread screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get threadTitle;

  /// Segmented toggle tab — replies
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get threadReplies;

  /// Segmented toggle tab — references
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get threadReferences;

  /// Empty state heading for replies tab
  ///
  /// In en, this message translates to:
  /// **'No replies yet'**
  String get threadNoReplies;

  /// Empty state body for replies tab
  ///
  /// In en, this message translates to:
  /// **'Be the first to reply.'**
  String get threadBeFirstToReply;

  /// Empty state heading for references tab
  ///
  /// In en, this message translates to:
  /// **'No references'**
  String get threadNoReferences;

  /// Empty state body for references tab
  ///
  /// In en, this message translates to:
  /// **'No notes reference this one yet.'**
  String get threadNoReferencesDetail;

  /// Send button in the reply composer
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get threadPost;

  /// Reply composer hint when no specific target
  ///
  /// In en, this message translates to:
  /// **'Reply to this note…'**
  String get threadReplyToThis;

  /// Reply composer hint when replying to a specific user
  ///
  /// In en, this message translates to:
  /// **'Reply to @{name}…'**
  String threadReplyTo(String name);

  /// Pill label showing who the reply targets
  ///
  /// In en, this message translates to:
  /// **'Replying to @{name}'**
  String threadReplyingTo(String name);

  /// Section header in followed-note detail
  ///
  /// In en, this message translates to:
  /// **'THREAD CONTINUATION'**
  String get threadContinuation;

  /// Reply count label in thread continuation card
  ///
  /// In en, this message translates to:
  /// **'{count} Replies'**
  String threadNReplies(int count);

  /// Last-updated label in thread continuation card
  ///
  /// In en, this message translates to:
  /// **'Updated: {time}'**
  String threadUpdated(String time);

  /// Primary CTA on followed-note detail
  ///
  /// In en, this message translates to:
  /// **'View Thread'**
  String get followedNoteViewThread;

  /// Error state on followed-note detail
  ///
  /// In en, this message translates to:
  /// **'Failed to load note'**
  String get followedNoteFailedToLoad;

  /// Node-type label on note header card
  ///
  /// In en, this message translates to:
  /// **'Research Node'**
  String get followedNoteResearchNode;

  /// Following badge on note header card
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followedNoteFollowing;

  /// Section header for the replies list on followed-note detail
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get followedNoteReferencedBy;

  /// Section header for the references list
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get followedNoteReferences;

  /// Settings screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section label — account
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Settings section label — identity
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get settingsIdentity;

  /// Settings section label — AI
  ///
  /// In en, this message translates to:
  /// **'AI · Shiv'**
  String get settingsAiShiv;

  /// Settings section label — storage
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// Settings section label — alerts
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get settingsAlerts;

  /// Settings section label — style
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get settingsStyle;

  /// Fallback display name when profile has no name
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get profileAnonymous;

  /// Edit profile button on settings
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// Subtitle on the identity card
  ///
  /// In en, this message translates to:
  /// **'This is your login & recovery method.'**
  String get identityLoginRecovery;

  /// Identity card row — keys
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get identityKeys;

  /// Identity card row — relays
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get identityRelays;

  /// Identity card row — export backup
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get identityExportBackup;

  /// Identity card row — privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy & Policy'**
  String get identityPrivacyPolicy;

  /// Keys sheet title
  ///
  /// In en, this message translates to:
  /// **'Your Keys'**
  String get identityYourKeys;

  /// Warning subtitle in the keys sheet
  ///
  /// In en, this message translates to:
  /// **'Never share your private key with anyone.'**
  String get identityNeverShare;

  /// Section label for public key in keys sheet
  ///
  /// In en, this message translates to:
  /// **'Public Key (npub)'**
  String get identityPublicKey;

  /// Snackbar after copying public key from keys sheet
  ///
  /// In en, this message translates to:
  /// **'Public key copied'**
  String get identityPublicKeyCopied;

  /// Section label for private key in keys sheet
  ///
  /// In en, this message translates to:
  /// **'Private Key (nsec)'**
  String get identityPrivateKey;

  /// Button to reveal nsec in keys sheet
  ///
  /// In en, this message translates to:
  /// **'Reveal Private Key'**
  String get identityRevealPrivateKey;

  /// Warning label inside revealed nsec box
  ///
  /// In en, this message translates to:
  /// **'Never share this key'**
  String get identityNeverShareKey;

  /// Inline copy prompt for nsec
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get identityTapToCopy;

  /// Hide nsec inline button
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get identityHide;

  /// Snackbar after copying nsec from keys sheet
  ///
  /// In en, this message translates to:
  /// **'Private key copied — keep it safe!'**
  String get identityPrivateKeyCopied;

  /// Relays bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get identityRelaysSheetTitle;

  /// Relays sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'Nostr relays your client connects to.'**
  String get identityRelaysSubtitle;

  /// Info note in relays sheet
  ///
  /// In en, this message translates to:
  /// **'Custom relay management coming soon.'**
  String get identityRelaysComingSoon;

  /// Toggle label for DM notifications
  ///
  /// In en, this message translates to:
  /// **'DM Alerts'**
  String get alertsDmAlerts;

  /// Toggle label for channel notifications
  ///
  /// In en, this message translates to:
  /// **'Channel Alerts'**
  String get alertsChannelAlerts;

  /// Storage card section heading
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get storageUsage;

  /// Storage bar chart row — notes stored in local DB
  ///
  /// In en, this message translates to:
  /// **'Note Data'**
  String get storageNoteData;

  /// Storage bar chart row — downloaded AI model files
  ///
  /// In en, this message translates to:
  /// **'AI Models'**
  String get storageAiModels;

  /// Subtitle for AI models storage row
  ///
  /// In en, this message translates to:
  /// **'Downloaded model files'**
  String get storageAiModelsSubtitle;

  /// Storage total row label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get storageTotal;

  /// Note count label
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String storageNotes(int count);

  /// Storage card button — opens removal dialog
  ///
  /// In en, this message translates to:
  /// **'Remove Data'**
  String get storageRemoveData;

  /// Title of the delete feed notes confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Feed Notes'**
  String get storageDeleteDialogTitle;

  /// Body of the delete feed notes dialog
  ///
  /// In en, this message translates to:
  /// **'This will delete {count} feed notes from local storage.\n\nYour own notes, saved notes, and followed notes will NOT be affected.'**
  String storageDeleteDialogBody(int count);

  /// Confirm button in delete dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get storageDeleteConfirm;

  /// Snackbar shown after successful deletion
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} notes'**
  String storageDeleteSuccess(int count);

  /// Shown when there are 0 deletable notes
  ///
  /// In en, this message translates to:
  /// **'No feed notes to delete'**
  String get storageNothingToDelete;

  /// Legend label for chat history storage
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get storageChatHistory;

  /// Legend label for miscellaneous app files (caches, config, assets)
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get storageOther;

  /// Bottom sheet option to delete feed notes
  ///
  /// In en, this message translates to:
  /// **'Delete Feed Notes'**
  String get storageDeleteFeedNotes;

  /// Subtitle for delete feed notes option
  ///
  /// In en, this message translates to:
  /// **'{count} feed notes · your own, saved, and followed notes are not affected'**
  String storageDeleteFeedNotesSubtitle(int count);

  /// Bottom sheet option to delete chat history
  ///
  /// In en, this message translates to:
  /// **'Delete Chat History'**
  String get storageDeleteChatHistory;

  /// Subtitle for delete chat history option
  ///
  /// In en, this message translates to:
  /// **'All Shiv conversations and messages'**
  String get storageDeleteChatHistorySubtitle;

  /// Snackbar shown after deleting chat history
  ///
  /// In en, this message translates to:
  /// **'Chat history deleted'**
  String get storageDeleteChatHistorySuccess;

  /// Confirmation dialog body for chat history deletion
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all Shiv conversations and messages. This cannot be undone.'**
  String get storageDeleteChatHistoryDialogBody;

  /// Style card row — theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get styleTheme;

  /// Light theme option label
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get styleThemeLight;

  /// Dark theme option label
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get styleThemeDark;

  /// System default theme option label
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get styleThemeSystem;

  /// Style card row — accent color
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get styleAccent;

  /// AI card row — model selector
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get aiSelectModel;

  /// Subtitle in AI card when no model is active
  ///
  /// In en, this message translates to:
  /// **'No model downloaded'**
  String get aiModelNoneSelected;

  /// AI card destructive action
  ///
  /// In en, this message translates to:
  /// **'Clear AI Cache'**
  String get aiClearCache;

  /// App bar title on the model selection screen
  ///
  /// In en, this message translates to:
  /// **'AI Model Selection'**
  String get aiModelSelectionTitle;

  /// Subtitle under available models header
  ///
  /// In en, this message translates to:
  /// **'Choose the intelligence level that fits your device\'s capabilities.'**
  String get aiModelSelectionSubtitle;

  /// Section header on model selection screen
  ///
  /// In en, this message translates to:
  /// **'Available Models'**
  String get aiModelAvailableHeader;

  /// Badge shown on the recommended model card
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get aiModelRecommendedBadge;

  /// Primary CTA button on model selection screen
  ///
  /// In en, this message translates to:
  /// **'Use This Model'**
  String get aiModelUseThisButton;

  /// Info banner text on model selection screen
  ///
  /// In en, this message translates to:
  /// **'Switching models requires a one-time download. Connect to Wi-Fi to avoid data charges. Your chat history is preserved.'**
  String get aiModelDownloadInfoText;

  /// Capability chip — CPU optimized model
  ///
  /// In en, this message translates to:
  /// **'Optimized for CPU'**
  String get aiModelOptimizedCpu;

  /// Capability chip — GPU+CPU model
  ///
  /// In en, this message translates to:
  /// **'Optimized for GPU / CPU'**
  String get aiModelOptimizedGpuCpu;

  /// Capability chip — GPU-only model
  ///
  /// In en, this message translates to:
  /// **'Optimized for GPU'**
  String get aiModelOptimizedGpu;

  /// Download progress label shown in footer while downloading
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String aiModelDownloadingProgress(int percent);

  /// Badge shown on already-downloaded active model card
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get aiModelAlreadyActive;

  /// Badge shown on downloaded but inactive model card
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get aiModelDownloaded;

  /// Footer button when selected model is downloaded but not active
  ///
  /// In en, this message translates to:
  /// **'Set as Active'**
  String get aiModelSetActive;

  /// Snackbar when model download fails
  ///
  /// In en, this message translates to:
  /// **'Download failed. Please try again.'**
  String get aiModelDownloadError;

  /// Display name for Qwen3 0.6B model
  ///
  /// In en, this message translates to:
  /// **'Qwen3 0.6B'**
  String get aiModelQwen25Name;

  /// Description for Qwen3 0.6B model
  ///
  /// In en, this message translates to:
  /// **'Compact multilingual chat with function calling. Works on any device with 3 GB+ RAM.'**
  String get aiModelQwen25Desc;

  /// Display name for DeepSeek R1 model
  ///
  /// In en, this message translates to:
  /// **'DeepSeek R1'**
  String get aiModelDeepSeekR1Name;

  /// Description for DeepSeek R1 model
  ///
  /// In en, this message translates to:
  /// **'High-performance reasoning and code generation. Requires 4 GB+ RAM.'**
  String get aiModelDeepSeekR1Desc;

  /// Display name for Gemma 4 E2B model
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 E2B'**
  String get aiModelGemma4E2bName;

  /// Description for Gemma 4 E2B model
  ///
  /// In en, this message translates to:
  /// **'Next-gen multimodal chat — text, image, audio. Requires 6 GB+ RAM.'**
  String get aiModelGemma4E2bDesc;

  /// Display name for Gemma 4 E4B model
  ///
  /// In en, this message translates to:
  /// **'Gemma 4 E4B'**
  String get aiModelGemma4E4bName;

  /// Description for Gemma 4 E4B model
  ///
  /// In en, this message translates to:
  /// **'Next-gen multimodal chat — text, image, audio. Best on flagship devices with 8 GB+ RAM.'**
  String get aiModelGemma4E4bDesc;

  /// Progress label shown while the embedding model is downloading after first LLM install
  ///
  /// In en, this message translates to:
  /// **'Setting up AI features…'**
  String get aiEmbeddingSetupInProgress;

  /// Edit profile screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// Snackbar after saving profile
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get editProfileSaved;

  /// Field label — display name
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get editProfileDisplayName;

  /// Field label — username
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get editProfileUsername;

  /// Field label — about / bio
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get editProfileAbout;

  /// Field label — avatar URL
  ///
  /// In en, this message translates to:
  /// **'Avatar URL'**
  String get editProfileAvatarUrl;

  /// Field label — NIP-05
  ///
  /// In en, this message translates to:
  /// **'NIP-05 Identifier'**
  String get editProfileNip05;

  /// Hint for display name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Satoshi'**
  String get editProfileDisplayNameHint;

  /// Hint for username field
  ///
  /// In en, this message translates to:
  /// **'e.g. satoshi'**
  String get editProfileUsernameHint;

  /// Hint for about field
  ///
  /// In en, this message translates to:
  /// **'Tell the world who you are…'**
  String get editProfileAboutHint;

  /// Hint for avatar URL field
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get editProfileAvatarUrlHint;

  /// Hint for NIP-05 field
  ///
  /// In en, this message translates to:
  /// **'you@yourdomain.com'**
  String get editProfileNip05Hint;

  /// Save profile button
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get editProfileSaveButton;

  /// Hero tagline on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Your notes, your\nnetwork, your identity.'**
  String get welcomeTagline;

  /// Primary CTA on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Create New Identity'**
  String get welcomeCreateIdentity;

  /// Secondary CTA on welcome screen
  ///
  /// In en, this message translates to:
  /// **'I Already Have a Key'**
  String get welcomeImportKey;

  /// Learn more link on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Learn how UNIUN works'**
  String get welcomeLearnHow;

  /// Heading on the about-you onboarding page
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get aboutYouTitle;

  /// Body subtitle on about-you page
  ///
  /// In en, this message translates to:
  /// **'Set up your profile. Display Name and Username are required.'**
  String get aboutYouSubtitle;

  /// Caption under the avatar on about-you page
  ///
  /// In en, this message translates to:
  /// **'Auto-generated · Photo optional'**
  String get aboutYouAvatarCaption;

  /// Field label for display name on about-you page
  ///
  /// In en, this message translates to:
  /// **'Display Name *'**
  String get aboutYouDisplayNameLabel;

  /// Hint for display name on about-you page
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get aboutYouDisplayNameHint;

  /// Field label for username on about-you page
  ///
  /// In en, this message translates to:
  /// **'Username *'**
  String get aboutYouUsernameLabel;

  /// Hint for username on about-you page
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get aboutYouUsernameHint;

  /// Helper text under username on about-you page
  ///
  /// In en, this message translates to:
  /// **'Unique handle for mentions and search.'**
  String get aboutYouUsernameHelper;

  /// Field label for bio on about-you page
  ///
  /// In en, this message translates to:
  /// **'Bio  (optional)'**
  String get aboutYouBioLabel;

  /// Hint for bio on about-you page
  ///
  /// In en, this message translates to:
  /// **'Tell the world a bit about yourself…'**
  String get aboutYouBioHint;

  /// Skip button on about-you page
  ///
  /// In en, this message translates to:
  /// **'SET UP LATER'**
  String get aboutYouSetUpLater;

  /// Privacy reassurance chip on about-you page
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted and private.'**
  String get aboutYouEncrypted;

  /// Validation error for display name
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get aboutYouDisplayNameRequired;

  /// Validation error for username
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get aboutYouUsernameRequired;

  /// Heading on the import-identity page
  ///
  /// In en, this message translates to:
  /// **'Import Your Identity'**
  String get importTitle;

  /// Body subtitle on the import-identity page
  ///
  /// In en, this message translates to:
  /// **'Paste your private key to recover your existing profile.'**
  String get importSubtitle;

  /// Field section label on import page
  ///
  /// In en, this message translates to:
  /// **'PRIVATE KEY'**
  String get importPrivateKeyLabel;

  /// Paste action on import page
  ///
  /// In en, this message translates to:
  /// **'Paste from Clipboard'**
  String get importPasteFromClipboard;

  /// Hint for key input on import page
  ///
  /// In en, this message translates to:
  /// **'nsec1... or 64-character hex key'**
  String get importKeyHint;

  /// Security reassurance note on import page
  ///
  /// In en, this message translates to:
  /// **'Your private key is processed locally and never sent to any server.'**
  String get importSecurityNote;

  /// Submit button on import page
  ///
  /// In en, this message translates to:
  /// **'Import & Continue'**
  String get importContinue;

  /// Validation error when field is empty on import page
  ///
  /// In en, this message translates to:
  /// **'Please paste your private key first.'**
  String get importPasteFirst;

  /// Error snackbar on import page
  ///
  /// In en, this message translates to:
  /// **'Failed to import key. Please try again.'**
  String get importFailed;

  /// Error snackbar for unrecognised key format
  ///
  /// In en, this message translates to:
  /// **'Invalid key. Please check and try again.'**
  String get importInvalidKey;

  /// Heading on the identity-keys onboarding page
  ///
  /// In en, this message translates to:
  /// **'Your Identity Keys'**
  String get keysTitle;

  /// Subtitle on the identity-keys onboarding page
  ///
  /// In en, this message translates to:
  /// **'One is for sharing. One is for your eyes only.'**
  String get keysSubtitle;

  /// KeyCard title for npub
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get keysPublicKeyTitle;

  /// KeyCard subtitle for npub
  ///
  /// In en, this message translates to:
  /// **'Share with others to receive messages.'**
  String get keysPublicKeySubtitle;

  /// KeyCard title for nsec
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get keysPrivateKeyTitle;

  /// KeyCard subtitle for nsec
  ///
  /// In en, this message translates to:
  /// **'Never share this. Total access to your identity.'**
  String get keysPrivateKeySubtitle;

  /// KeyCard warning for nsec
  ///
  /// In en, this message translates to:
  /// **'Lose this key = lose your account forever.'**
  String get keysPrivateKeyWarning;

  /// CTA button on identity-keys page
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get keysSaveAndContinue;

  /// Secondary action on identity-keys page
  ///
  /// In en, this message translates to:
  /// **'Download Backup'**
  String get keysDownloadBackup;

  /// Badge on identity-keys page footer
  ///
  /// In en, this message translates to:
  /// **'E2E ENCRYPTED'**
  String get keysE2eEncrypted;

  /// Snackbar after copying npub on identity-keys page
  ///
  /// In en, this message translates to:
  /// **'Public key copied — now reveal your private key'**
  String get keysPublicCopied;

  /// Snackbar after copying nsec on identity-keys page
  ///
  /// In en, this message translates to:
  /// **'Private key copied — store it somewhere safe!'**
  String get keysPrivateCopied;

  /// Error snackbar when key save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save keys: {error}'**
  String keysFailedToSave(String error);

  /// Snackbar after saving backup file
  ///
  /// In en, this message translates to:
  /// **'Backup saved to {path}'**
  String keysBackupSaved(String path);

  /// Error snackbar when backup write fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save backup'**
  String get keysBackupFailed;

  /// Hint shown in place of private key card until npub is copied
  ///
  /// In en, this message translates to:
  /// **'Copy your public key above to reveal your private key.'**
  String get keysCopyPublicAbove;

  /// App-bar title for privacy policy page
  ///
  /// In en, this message translates to:
  /// **'Privacy & Policy'**
  String get privacyPageTitle;

  /// Section heading inside privacy policy page
  ///
  /// In en, this message translates to:
  /// **'Privacy & Policy'**
  String get privacyIntroTitle;

  /// Intro paragraph on privacy policy page
  ///
  /// In en, this message translates to:
  /// **'UNIUN is built on transparency. Your data stays on your device. Below is everything you need to know — no legal jargon.'**
  String get privacyIntroBody;

  /// Expandable section title — privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyExpandPrivacy;

  /// Expandable section title — terms of use
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get privacyExpandTerms;

  /// Footer date on privacy policy page
  ///
  /// In en, this message translates to:
  /// **'Last updated: June 2025'**
  String get privacyLastUpdated;

  /// Contact email shown on privacy policy page
  ///
  /// In en, this message translates to:
  /// **'privacy@uniun.app'**
  String get privacyContactEmail;

  /// No description provided for @privacyStoredLocallyTitle.
  ///
  /// In en, this message translates to:
  /// **'What We Store Locally'**
  String get privacyStoredLocallyTitle;

  /// No description provided for @privacyStoredLocallyBody.
  ///
  /// In en, this message translates to:
  /// **'UNIUN stores your notes, profile, saved items, channel messages, and settings directly on your device. This data is not sent to any server controlled by UNIUN.'**
  String get privacyStoredLocallyBody;

  /// No description provided for @privacySharedPubliclyTitle.
  ///
  /// In en, this message translates to:
  /// **'What Gets Shared Publicly'**
  String get privacySharedPubliclyTitle;

  /// No description provided for @privacySharedPubliclyBody.
  ///
  /// In en, this message translates to:
  /// **'When you publish a note or send a message in a public channel, that content is broadcast to Nostr relays. Nostr is an open public protocol — once published, your notes may be visible to anyone connected to those relays. UNIUN does not control third-party relays.'**
  String get privacySharedPubliclyBody;

  /// No description provided for @privacyIdentityKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Identity & Keys'**
  String get privacyIdentityKeysTitle;

  /// No description provided for @privacyIdentityKeysBody.
  ///
  /// In en, this message translates to:
  /// **'Your identity is a cryptographic key pair. Your public key is visible to others on the Nostr network. Your private key (nsec) is stored exclusively in your device\'s secure system keychain (iOS Keychain / Android Keystore). UNIUN never transmits your private key to any server.'**
  String get privacyIdentityKeysBody;

  /// No description provided for @privacyLocalAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Local AI (Shiv)'**
  String get privacyLocalAiTitle;

  /// No description provided for @privacyLocalAiBody.
  ///
  /// In en, this message translates to:
  /// **'The Shiv AI assistant runs entirely on your device. It accesses only your locally saved notes. No note content is sent to any external AI service or API.'**
  String get privacyLocalAiBody;

  /// No description provided for @privacyMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Media & Blossom Servers'**
  String get privacyMediaTitle;

  /// No description provided for @privacyMediaBody.
  ///
  /// In en, this message translates to:
  /// **'If you attach images or media, they may be uploaded to a Blossom content server of your choice. UNIUN does not operate Blossom servers. Content uploaded there may be publicly accessible by design of the protocol.'**
  String get privacyMediaBody;

  /// No description provided for @privacyDmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Messages'**
  String get privacyDmsTitle;

  /// No description provided for @privacyDmsBody.
  ///
  /// In en, this message translates to:
  /// **'DMs are end-to-end encrypted using the Nostr NIP-17 standard. Only the intended recipient can read the message content. Message routing metadata may be visible to relays.'**
  String get privacyDmsBody;

  /// No description provided for @privacyControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Control'**
  String get privacyControlTitle;

  /// No description provided for @privacyControlBody.
  ///
  /// In en, this message translates to:
  /// **'You can delete your local data at any time from Settings. Because Nostr is a public protocol, notes already published to relays cannot be retracted — this is an intentional property of the network, not a limitation of the app.'**
  String get privacyControlBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In en, this message translates to:
  /// **'For privacy questions: privacy@uniun.app'**
  String get privacyContactBody;

  /// No description provided for @termsResponsibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Responsibility'**
  String get termsResponsibilityTitle;

  /// No description provided for @termsResponsibilityBody.
  ///
  /// In en, this message translates to:
  /// **'You are solely responsible for all content you publish on UNIUN. By using the app, you agree not to post content that is illegal, abusive, harassing, or violates others\' rights.'**
  String get termsResponsibilityBody;

  /// No description provided for @termsNoAbuseTitle.
  ///
  /// In en, this message translates to:
  /// **'No Abuse or Spam'**
  String get termsNoAbuseTitle;

  /// No description provided for @termsNoAbuseBody.
  ///
  /// In en, this message translates to:
  /// **'Do not use UNIUN to spam, harass, impersonate others, or conduct automated activity that disrupts the Nostr network.'**
  String get termsNoAbuseBody;

  /// No description provided for @termsPrivateKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Your Private Key Safe'**
  String get termsPrivateKeyTitle;

  /// No description provided for @termsPrivateKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Your private key (nsec) is your identity and login. If you lose it, your account cannot be recovered — UNIUN has no way to reset or recover private keys. Back it up in a secure location.'**
  String get termsPrivateKeyBody;

  /// No description provided for @termsPublicContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Public Content on Relays'**
  String get termsPublicContentTitle;

  /// No description provided for @termsPublicContentBody.
  ///
  /// In en, this message translates to:
  /// **'Notes and channel messages you publish are sent to Nostr relays and may be visible to anyone on the network. Do not share sensitive personal information in public notes.'**
  String get termsPublicContentBody;

  /// No description provided for @termsAppMayChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'App May Change'**
  String get termsAppMayChangeTitle;

  /// No description provided for @termsAppMayChangeBody.
  ///
  /// In en, this message translates to:
  /// **'UNIUN is in active development. Features, relay behavior, and policies may change over time. We will communicate significant updates within the app.'**
  String get termsAppMayChangeBody;

  /// No description provided for @termsNoWarrantyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Warranty'**
  String get termsNoWarrantyTitle;

  /// No description provided for @termsNoWarrantyBody.
  ///
  /// In en, this message translates to:
  /// **'UNIUN is provided as-is. We make no guarantees about relay uptime, third-party server availability, or persistence of content on external relays.'**
  String get termsNoWarrantyBody;

  /// Shiv AI assistant name label (uppercase)
  ///
  /// In en, this message translates to:
  /// **'SHIV'**
  String get shivName;

  /// Shiv landing header tagline
  ///
  /// In en, this message translates to:
  /// **'Think in threads'**
  String get shivTagline;

  /// Shiv landing screen body subtitle
  ///
  /// In en, this message translates to:
  /// **'Your on-device AI.\nThink in threads.'**
  String get shivLandingBody;

  /// Shiv no-model placeholder body text
  ///
  /// In en, this message translates to:
  /// **'Download an AI model to start chatting with Shiv. Everything runs on your device — no internet needed after setup.'**
  String get shivNoModelBody;

  /// Button to open AI model selection
  ///
  /// In en, this message translates to:
  /// **'Set up AI'**
  String get shivSetUpAi;

  /// Button label to create a new Shiv conversation
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get shivNewConversation;

  /// Link to view existing conversations on Shiv landing
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{View 1 conversation} other{View {count} conversations}}'**
  String shivViewConversations(int count);

  /// Title of the conversations history sheet
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get shivConversations;

  /// Tooltip on new conversation icon button
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get shivNewConversationTooltip;

  /// Tooltip on the history icon in chat header
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get shivConversationsTooltip;

  /// Tooltip on the branch tree icon in chat header
  ///
  /// In en, this message translates to:
  /// **'Branch tree'**
  String get shivBranchTreeTooltip;

  /// Snackbar shown when tapping the branch tree button
  ///
  /// In en, this message translates to:
  /// **'Branch tree — coming in Phase 4'**
  String get shivBranchTreeComingSoon;

  /// Title of the branch tree page
  ///
  /// In en, this message translates to:
  /// **'Conversation Tree'**
  String get shivConversationTree;

  /// Button to open the selected branch in chat
  ///
  /// In en, this message translates to:
  /// **'Open Branch'**
  String get shivNodeOpenBranch;

  /// Button to set selected node as active branch point
  ///
  /// In en, this message translates to:
  /// **'Continue From Here'**
  String get shivNodeContinueFromHere;

  /// Button to fork a new branch from selected node
  ///
  /// In en, this message translates to:
  /// **'New Branch'**
  String get shivNodeNewBranch;

  /// Badge label on the active branch node panel
  ///
  /// In en, this message translates to:
  /// **'Active Branch'**
  String get shivActiveBranch;

  /// Message count shown in node panel
  ///
  /// In en, this message translates to:
  /// **'{count} msgs'**
  String shivNodeMessages(int count);

  /// Default title for a newly created conversation
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get shivDefaultConversationTitle;

  /// Empty chat state heading
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get shivEmptyTitle;

  /// Empty chat state body text
  ///
  /// In en, this message translates to:
  /// **'Ask Shiv anything — your saved notes\ngive it context about what you know.'**
  String get shivEmptyBody;

  /// Tree view empty state heading
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get shivEmptyTreeTitle;

  /// Tree view empty state body text
  ///
  /// In en, this message translates to:
  /// **'Start a conversation to see the\nbranch tree here.'**
  String get shivEmptyTreeBody;

  /// Label shown while the model is in a thinking/reasoning block
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get shivThinking;

  /// Collapsed section header for the model's internal thinking
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get shivThinkingLabel;

  /// Hint text inside the Shiv chat input field
  ///
  /// In en, this message translates to:
  /// **'Ask Shiv anything…'**
  String get shivInputHint;

  /// Empty state in the conversations history sheet
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get shivNoConversations;

  /// Badge on the currently active conversation in history
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get shivActiveLabel;

  /// Relative time: less than 1 minute ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get shivTimeJustNow;

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String shivTimeMinutesAgo(int count);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String shivTimeHoursAgo(int count);

  /// Relative time in days
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String shivTimeDaysAgo(int count);

  /// Page title for the saved notes list
  ///
  /// In en, this message translates to:
  /// **'Saved Notes'**
  String get savedNotesTitle;

  /// Placeholder for saved notes search bar
  ///
  /// In en, this message translates to:
  /// **'Search saved notes…'**
  String get savedNotesSearch;

  /// Empty state headline on saved notes page
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get savedNotesEmpty;

  /// Empty state sub-text on saved notes page
  ///
  /// In en, this message translates to:
  /// **'Bookmark notes from your feed to read them later.'**
  String get savedNotesEmptySub;

  /// Graph legend label for saved notes (blue nodes)
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get graphLegendSaved;

  /// Graph legend label for own published notes (green nodes)
  ///
  /// In en, this message translates to:
  /// **'Own'**
  String get graphLegendOwn;

  /// Graph legend label for draft notes (amber nodes)
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get graphLegendDraft;

  /// FAB option to create a plain text note from the graph
  ///
  /// In en, this message translates to:
  /// **'Text note'**
  String get graphFabTextNote;

  /// FAB option to create a reference/mention note from the graph
  ///
  /// In en, this message translates to:
  /// **'Reference note'**
  String get graphFabReferenceNote;

  /// Edit action on a draft node panel
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get graphDraftEdit;

  /// Delete action on a draft node panel
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get graphDraftDelete;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
