import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/channels/feed/bloc/channel_feed_bloc.dart';
import 'package:uniun/channels/feed/bloc/channel_feed_event.dart';
import 'package:uniun/channels/feed/bloc/channel_feed_state.dart';
import 'package:uniun/channels/feed/widgets/channel_message_composer.dart';
import 'package:uniun/channels/thread/pages/channel_thread_page.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/channel_message/channel_message_entity.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/core/scan/uniun_qr_card.dart';
import 'package:uniun/vishnu/widgets/note_card.dart';

class ChannelFeedPage extends StatelessWidget {
  const ChannelFeedPage({super.key, required this.channelId});
  final String channelId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChannelFeedBloc()..add(LoadChannelFeedEvent(channelId)),
        ),
        BlocProvider(
          create: (_) => getIt<FollowedNotesCubit>()..load(),
        ),
      ],
      child: _ChannelFeedView(channelId: channelId),
    );
  }
}

class _ChannelFeedView extends StatefulWidget {
  const _ChannelFeedView({required this.channelId});
  final String channelId;

  @override
  State<_ChannelFeedView> createState() => _ChannelFeedViewState();
}

class _ChannelFeedViewState extends State<_ChannelFeedView> {
  final _scrollController = ScrollController();
  bool _didScrollToBottom = false;
  String? _userPubkey;
  String? _userAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final profileResult = await getIt<GetActiveUserProfileUseCase>().call();
    if (!mounted) return;
    setState(() {
      _userPubkey = profileResult.fold((_) => null, (p) => p.pubkeyHex);
      _userAvatarUrl = profileResult.fold((_) => null, (p) => p.avatarUrl);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _toggleFollow(
    BuildContext ctx,
    String noteId,
    String contentPreview,
    bool isCurrentlyFollowed,
  ) async {
    final cubit = ctx.read<FollowedNotesCubit>();
    if (isCurrentlyFollowed) {
      await cubit.unfollowNote(noteId);
    } else {
      await cubit.followNote(noteId, contentPreview);
    }
  }

  void _openThread(BuildContext ctx, ChannelMessageEntity msg, String channelName) {
    final bloc = ctx.read<ChannelFeedBloc>();
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => ChannelThreadPage(
          channelId: widget.channelId,
          messageId: msg.id,
          channelName: channelName,
          parentBloc: bloc,
        ),
      ),
    ).then((_) {
      // Silent refresh — no loading spinner, scroll position preserved.
      // listenWhen fires only if new messages arrived, scrolling to bottom
      // only when there is genuinely new content to show.
      if (mounted) bloc.add(LoadChannelFeedEvent(widget.channelId, silent: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChannelFeedBloc, ChannelFeedState>(
      listenWhen: (prev, curr) =>
          prev.messages.length != curr.messages.length,
      listener: (context, state) {
        if (!_didScrollToBottom &&
            state.status == ChannelFeedStatus.loaded) {
          _didScrollToBottom = true;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        } else if (state.messages.isNotEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      },
      builder: (context, state) {
        final channelName = state.channel?.name ?? '';

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$channelName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                if (state.channel?.about.isNotEmpty == true)
                  Text(
                    state.channel!.about,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            actions: [
              // Show this channel as a scannable card
              if (state.channel != null)
                IconButton(
                  icon: const Icon(Icons.badge_rounded,
                      size: 20, color: AppColors.onSurfaceVariant),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => UniunQrCard.channel(
                      name: state.channel!.name,
                      about: state.channel!.about,
                      channelId: state.channel!.channelId,
                      creatorPubKey: state.channel!.creatorPubKey,
                      picture: state.channel!.picture,
                      createdAt: state.channel!.createdAt,
                    ),
                  ),
                ),
              // Scan another channel card
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded,
                    size: 20, color: AppColors.onSurfaceVariant),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.scanQr),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _buildMessageList(context, state, channelName),
              ),
              ChannelMessageComposer(
                channelId: widget.channelId,
                avatarUrl: _userAvatarUrl,
                pubkeySeed: _userPubkey ?? '',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList(
      BuildContext context, ChannelFeedState state, String channelName) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == ChannelFeedStatus.error) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Something went wrong.',
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    if (state.messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet. Be the first!',
          style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
        ),
      );
    }

    return BlocBuilder<FollowedNotesCubit, FollowedNotesState>(
      builder: (ctx, followedState) {
        final followedIds =
            followedState.notes.map((n) => n.eventId).toSet();
        final bloc = ctx.read<ChannelFeedBloc>();

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          itemCount: state.messages.length,
          itemBuilder: (context, i) {
            final msg = state.messages[i];
            final isSaved = state.savedIds.contains(msg.id);
            final isFollowed = followedIds.contains(msg.id);

            return NoteCard(
              note: msg.toNoteEntity(),
              profile: state.profiles[msg.authorPubkey],
              replyCount: msg.cachedReplyCount,
              isSaved: isSaved,
              isFollowed: isFollowed,
              onTap: () => _openThread(ctx, msg, channelName),
              onSaveTap: () {
                if (isSaved) {
                  bloc.add(UnsaveChannelFeedMessageEvent(msg.id));
                } else {
                  bloc.add(SaveChannelFeedMessageEvent(msg));
                }
              },
              onFollowTap: () => _toggleFollow(
                ctx,
                msg.id,
                msg.content.length > 80
                    ? msg.content.substring(0, 80)
                    : msg.content,
                isFollowed,
              ),
            );
          },
        );
      },
    );
  }
}
