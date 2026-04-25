import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/home/pages/home_page.dart';
import 'package:uniun/onboarding/pages/about_you_page.dart';
import 'package:uniun/thread/pages/thread_page.dart';
import 'package:uniun/shiv/model_select/pages/ai_model_selection_page.dart';
import 'package:uniun/settings/pages/edit_profile_page.dart';
import 'package:uniun/settings/pages/privacy_policy_page.dart';
import 'package:uniun/settings/pages/settings_page.dart';
import 'package:uniun/onboarding/pages/import_identity_page.dart';
import 'package:uniun/onboarding/pages/splash_page.dart';
import 'package:uniun/onboarding/pages/welcome_page.dart';
import 'package:uniun/onboarding/pages/your_identity_keys_page.dart';
import 'package:uniun/channels/create/pages/create_channel_page.dart';
import 'package:uniun/channels/feed/pages/channel_feed_page.dart';
import 'package:uniun/core/scan/text_scanner_page.dart';
import 'package:uniun/core/scan/qr_scanner_page.dart';
import 'package:uniun/saved_notes/pages/saved_notes_page.dart';
import 'package:uniun/dm/create/pages/create_dm_page.dart';
import 'package:uniun/dm/chat/pages/dm_chat_page.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/brahma/bloc/brahma_create_bloc.dart';
import 'package:uniun/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/brahma/graph/pages/graph_page.dart';
import 'package:uniun/brahma/graph/pages/graph_compose_page.dart';
import 'package:uniun/gateway/gateway.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  // Preserve native splash only until Flutter renders its first frame
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Remove native splash immediately → SplashPage takes over
  FlutterNativeSplash.remove();

  GatewayBootstrap.start();
  runApp(const UniunApp());
}

class UniunApp extends StatelessWidget {
  const UniunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNIUN',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.welcome: (_) => const WelcomePage(),
        AppRoutes.importIdentity: (_) => const ImportIdentityPage(),
        AppRoutes.yourIdentityKeys: (_) => const YourIdentityKeysPage(),
        AppRoutes.aboutYou: (_) => const AboutYouPage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.settings: (_) => const SettingsPage(),
        AppRoutes.editProfile: (_) => const EditProfilePage(),
        AppRoutes.privacyPolicy: (_) => const PrivacyPolicyPage(),
        AppRoutes.thread: (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments;
          if (args is ThreadRouteArgs) {
            return ThreadPage(noteId: args.noteId, hasUnread: args.hasUnread, savedOnly: args.savedOnly);
          }
          return ThreadPage(noteId: args as String);
        },
        AppRoutes.createChannel: (_) => const CreateChannelPage(),
        AppRoutes.channelDetail: (ctx) => ChannelFeedPage(
          channelId: ModalRoute.of(ctx)!.settings.arguments as String,
        ),
        AppRoutes.aiModelSelection: (_) => const AIModelSelectionPage(),
        AppRoutes.savedNotes: (_) => const SavedNotesPage(),
        AppRoutes.graph: (_) => const GraphPage(),
        AppRoutes.createDm: (_) => const CreateDmPage(),
        AppRoutes.chatDm: (_) => const DmChatPage(),
        AppRoutes.scanCard: (_) => const TextScannerPage(),
        AppRoutes.scanQr: (_) => const QrScannerPage(),
        AppRoutes.graph: (_) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) =>
                      getIt<GraphBloc>()..add(const LoadGraphEvent()),
                ),
                BlocProvider(
                  create: (_) =>
                      getIt<BrahmaCreateBloc>()..add(const LoadDraftsEvent()),
                ),
              ],
              child: const GraphPage(),
            ),
        AppRoutes.brahmaCreate: (ctx) {
              final args = ModalRoute.of(ctx)!.settings.arguments;
              String? draftId;
              bool autoPublish = false;
              if (args is String?) {
                draftId = args;
              } else if (args is Map) {
                draftId = args['draftId'] as String?;
                autoPublish = args['autoPublish'] as bool? ?? false;
              }
              return GraphComposePage(
                initialDraftId: draftId,
                autoPublish: autoPublish,
              );
            },
      },
    );
  }
}
