// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:isar_community/isar.dart' as _i214;
import 'package:tostore/tostore.dart' as _i789;
import 'package:uniun/brahma/bloc/brahma_create_bloc.dart' as _i787;
import 'package:uniun/brahma/graph/bloc/graph_bloc.dart' as _i536;
import 'package:uniun/channels/create/bloc/create_channel_bloc.dart' as _i234;
import 'package:uniun/data/datasources/isar_module.dart' as _i146;
import 'package:uniun/data/datasources/tostore_module.dart' as _i740;
import 'package:uniun/data/repositories/ai_model_repository_impl.dart' as _i72;
import 'package:uniun/data/repositories/channel_message_repository_impl.dart'
    as _i929;
import 'package:uniun/data/repositories/channel_repository_impl.dart' as _i1009;
import 'package:uniun/data/repositories/dm_conversation_repository_impl.dart'
    as _i1011;
import 'package:uniun/data/repositories/dm_message_repository_impl.dart'
    as _i398;
import 'package:uniun/data/repositories/draft_repository_impl.dart' as _i640;
import 'package:uniun/data/repositories/event_queue_repository_impl.dart'
    as _i116;
import 'package:uniun/data/repositories/followed_note_repository_impl.dart'
    as _i107;
import 'package:uniun/data/repositories/graph_repository_impl.dart' as _i250;
import 'package:uniun/data/repositories/memory_repository_impl.dart' as _i849;
import 'package:uniun/data/repositories/note_repository_impl.dart' as _i348;
import 'package:uniun/data/repositories/profile_repository_impl.dart' as _i484;
import 'package:uniun/data/repositories/relay_repository_impl.dart' as _i542;
import 'package:uniun/data/repositories/saved_note_repository_impl.dart'
    as _i669;
import 'package:uniun/data/repositories/shiv_repository_impl.dart' as _i412;
import 'package:uniun/data/repositories/storage_repository_impl.dart' as _i209;
import 'package:uniun/data/repositories/subscription_record_repository_impl.dart'
    as _i364;
import 'package:uniun/data/repositories/tostore_vector_repository_impl.dart'
    as _i831;
import 'package:uniun/data/repositories/user_repository_impl.dart' as _i582;
import 'package:uniun/domain/repositories/ai_model_repository.dart' as _i646;
import 'package:uniun/domain/repositories/channel_message_repository.dart'
    as _i964;
import 'package:uniun/domain/repositories/channel_repository.dart' as _i127;
import 'package:uniun/domain/repositories/dm_conversation_repository.dart'
    as _i189;
import 'package:uniun/domain/repositories/dm_message_repository.dart' as _i551;
import 'package:uniun/domain/repositories/draft_repository.dart' as _i170;
import 'package:uniun/domain/repositories/event_queue_repository.dart'
    as _i1039;
import 'package:uniun/domain/repositories/followed_note_repository.dart'
    as _i836;
import 'package:uniun/domain/repositories/graph_repository.dart' as _i649;
import 'package:uniun/domain/repositories/memory_repository.dart' as _i331;
import 'package:uniun/domain/repositories/note_repository.dart' as _i47;
import 'package:uniun/domain/repositories/profile_repository.dart' as _i967;
import 'package:uniun/domain/repositories/relay_repository.dart' as _i993;
import 'package:uniun/domain/repositories/saved_note_repository.dart' as _i43;
import 'package:uniun/domain/repositories/shiv_repository.dart' as _i266;
import 'package:uniun/domain/repositories/storage_repository.dart' as _i240;
import 'package:uniun/domain/repositories/subscription_record_repository.dart'
    as _i194;
import 'package:uniun/domain/repositories/user_repository.dart' as _i103;
import 'package:uniun/domain/repositories/vector_repository.dart' as _i739;
import 'package:uniun/domain/usecases/ai_model_usecases.dart' as _i894;
import 'package:uniun/domain/usecases/create_channel_message_usecase.dart'
    as _i524;
import 'package:uniun/domain/usecases/create_channel_usecase.dart' as _i1033;
import 'package:uniun/domain/usecases/draft_usecases.dart' as _i537;
import 'package:uniun/domain/usecases/followed_note_usecases.dart' as _i561;
import 'package:uniun/domain/usecases/get_channel_by_id_usecase.dart' as _i263;
import 'package:uniun/domain/usecases/get_channel_messages_usecase.dart'
    as _i689;
import 'package:uniun/domain/usecases/get_channels_usecase.dart' as _i722;
import 'package:uniun/domain/usecases/get_relays_usecase.dart' as _i985;
import 'package:uniun/domain/usecases/knowledge_usecases.dart' as _i179;
import 'package:uniun/domain/usecases/note_usecases.dart' as _i475;
import 'package:uniun/domain/usecases/profile_usecases.dart' as _i391;
import 'package:uniun/domain/usecases/saved_note_usecases.dart' as _i858;
import 'package:uniun/domain/usecases/shiv_usecases.dart' as _i604;
import 'package:uniun/domain/usecases/storage_usecases.dart' as _i58;
import 'package:uniun/domain/usecases/subscribe_channel_usecase.dart' as _i163;
import 'package:uniun/domain/usecases/user_usecases.dart' as _i799;
import 'package:uniun/domain/usecases/vector_usecases.dart' as _i756;
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart' as _i97;
import 'package:uniun/settings/cubit/edit_profile_cubit.dart' as _i195;
import 'package:uniun/settings/cubit/settings_cubit.dart' as _i731;
import 'package:uniun/settings/cubit/storage_cubit.dart' as _i888;
import 'package:uniun/shiv/chat/bloc/shiv_ai_bloc.dart' as _i334;
import 'package:uniun/shiv/model_select/cubit/select_ai_model_cubit.dart'
    as _i53;
import 'package:uniun/shiv/rag/embedding/embedding_model_downloader.dart'
    as _i113;
import 'package:uniun/shiv/rag/embedding/embedding_service.dart' as _i828;
import 'package:uniun/shiv/rag/pipeline/rag_pipeline.dart' as _i1067;
import 'package:uniun/shiv/rag/prompt/prompt_builder.dart' as _i197;
import 'package:uniun/shiv/rag/retrieval/vector_search_service.dart' as _i285;
import 'package:uniun/shiv/services/ai_model_runner.dart' as _i761;
import 'package:uniun/thread/bloc/thread_bloc.dart' as _i118;
import 'package:uniun/vishnu/bloc/vishnu_feed_bloc.dart' as _i558;
import 'package:uniun/vishnu/drawer/bloc/drawer_bloc.dart' as _i801;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final isarModule = _$IsarModule();
    final tostoreModule = _$TostoreModule();
    await gh.singletonAsync<_i214.Isar>(
      () => isarModule.createIsar(),
      preResolve: true,
    );
    await gh.singletonAsync<_i789.ToStore>(
      () => tostoreModule.createTostore(),
      preResolve: true,
    );
    gh.lazySingleton<_i113.EmbeddingModelDownloader>(
      () => _i113.EmbeddingModelDownloader(),
    );
    gh.lazySingleton<_i828.EmbeddingService>(() => _i828.EmbeddingService());
    gh.lazySingleton<_i197.PromptBuilder>(() => const _i197.PromptBuilder());
    gh.lazySingleton<_i761.AIModelRunner>(() => _i761.AIModelRunner());
    gh.lazySingleton<_i739.VectorRepository>(
      () => _i831.TostoreVectorRepositoryImpl(
        gh<_i789.ToStore>(),
        gh<_i214.Isar>(),
      ),
    );
    gh.factory<_i646.AIModelRepository>(
      () => _i72.AIModelRepositoryImpl(gh<_i214.Isar>()),
    );
    gh.factory<_i266.ShivRepository>(
      () => _i412.ShivRepositoryImpl(gh<_i214.Isar>()),
    );
    gh.factory<_i189.DmConversationRepository>(
      () => _i1011.DmConversationRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i47.NoteRepository>(
      () => _i348.NoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i649.GraphRepository>(
      () => _i250.GraphRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i836.FollowedNoteRepository>(
      () => _i107.FollowedNoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i170.DraftRepository>(
      () => _i640.DraftRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i43.SavedNoteRepository>(
      () => _i669.SavedNoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i194.SubscriptionRecordRepository>(
      () => _i364.SubscriptionRecordRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i551.DmMessageRepository>(
      () => _i398.DmMessageRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i1039.EventQueueRepository>(
      () => _i116.EventQueueRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i967.ProfileRepository>(
      () => _i484.ProfileRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i163.SubscribeChannelUseCase>(
      () => _i163.SubscribeChannelUseCase(
        gh<_i194.SubscriptionRecordRepository>(),
      ),
    );
    gh.lazySingleton<_i537.SaveDraftUseCase>(
      () => _i537.SaveDraftUseCase(gh<_i170.DraftRepository>()),
    );
    gh.lazySingleton<_i537.GetDraftsUseCase>(
      () => _i537.GetDraftsUseCase(gh<_i170.DraftRepository>()),
    );
    gh.lazySingleton<_i537.GetDraftByIdUseCase>(
      () => _i537.GetDraftByIdUseCase(gh<_i170.DraftRepository>()),
    );
    gh.lazySingleton<_i537.DeleteDraftUseCase>(
      () => _i537.DeleteDraftUseCase(gh<_i170.DraftRepository>()),
    );
    gh.factory<_i127.ChannelRepository>(
      () => _i1009.ChannelRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i993.RelayRepository>(
      () => _i542.RelayRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i263.GetChannelByIdUseCase>(
      () => _i263.GetChannelByIdUseCase(gh<_i127.ChannelRepository>()),
    );
    gh.lazySingleton<_i722.GetChannelsUseCase>(
      () => _i722.GetChannelsUseCase(gh<_i127.ChannelRepository>()),
    );
    gh.factory<_i964.ChannelMessageRepository>(
      () => _i929.ChannelMessageRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i561.GetAllFollowedNotesUseCase>(
      () =>
          _i561.GetAllFollowedNotesUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_i561.FollowNoteUseCase>(
      () => _i561.FollowNoteUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_i561.UnfollowNoteUseCase>(
      () => _i561.UnfollowNoteUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_i561.ClearNewReferencesUseCase>(
      () => _i561.ClearNewReferencesUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.factory<_i331.MemoryRepository>(
      () => _i849.MemoryRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i103.UserRepository>(
      () => _i582.UserRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i604.GetConversationsUseCase>(
      () => _i604.GetConversationsUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.CreateConversationUseCase>(
      () => _i604.CreateConversationUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.DeleteConversationUseCase>(
      () => _i604.DeleteConversationUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.GetMessagesUseCase>(
      () => _i604.GetMessagesUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.SaveMessageUseCase>(
      () => _i604.SaveMessageUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.UpdateMessageContentUseCase>(
      () => _i604.UpdateMessageContentUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.UpdateConversationTitleUseCase>(
      () => _i604.UpdateConversationTitleUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.UpdateActiveLeafUseCase>(
      () => _i604.UpdateActiveLeafUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i391.GetProfileUseCase>(
      () => _i391.GetProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_i391.GetOwnProfileUseCase>(
      () => _i391.GetOwnProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_i391.SaveProfileUseCase>(
      () => _i391.SaveProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_i858.SaveNoteUseCase>(
      () => _i858.SaveNoteUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.IsSavedNoteUseCase>(
      () => _i858.IsSavedNoteUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.GetAllSavedNotesUseCase>(
      () => _i858.GetAllSavedNotesUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.GetSavedReplyCountUseCase>(
      () => _i858.GetSavedReplyCountUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.factory<_i240.StorageRepository>(
      () => _i209.StorageRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i475.GetFeedUseCase>(
      () => _i475.GetFeedUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetNoteByIdUseCase>(
      () => _i475.GetNoteByIdUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetRepliesUseCase>(
      () => _i475.GetRepliesUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.SaveNoteUseCase>(
      () => _i475.SaveNoteUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.MarkSeenUseCase>(
      () => _i475.MarkSeenUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetThreadUseCase>(
      () => _i475.GetThreadUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i179.GetGraphNeighboursUseCase>(
      () => _i179.GetGraphNeighboursUseCase(gh<_i649.GraphRepository>()),
    );
    gh.lazySingleton<_i179.GetGraphNodesByKeysUseCase>(
      () => _i179.GetGraphNodesByKeysUseCase(gh<_i649.GraphRepository>()),
    );
    gh.lazySingleton<_i756.SearchVectorNotesUseCase>(
      () => _i756.SearchVectorNotesUseCase(gh<_i739.VectorRepository>()),
    );
    gh.lazySingleton<_i799.GetActiveUserUseCase>(
      () => _i799.GetActiveUserUseCase(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_i799.GetActiveUserKeysUseCase>(
      () => _i799.GetActiveUserKeysUseCase(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_i799.ImportKeyUseCase>(
      () => _i799.ImportKeyUseCase(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_i179.DeleteKnowledgeForNoteUseCase>(
      () => _i179.DeleteKnowledgeForNoteUseCase(
        gh<_i649.GraphRepository>(),
        gh<_i331.MemoryRepository>(),
      ),
    );
    gh.lazySingleton<_i689.GetChannelMessagesUseCase>(
      () =>
          _i689.GetChannelMessagesUseCase(gh<_i964.ChannelMessageRepository>()),
    );
    gh.lazySingleton<_i689.GetChannelMessageByIdUseCase>(
      () => _i689.GetChannelMessageByIdUseCase(
        gh<_i964.ChannelMessageRepository>(),
      ),
    );
    gh.lazySingleton<_i689.GetChannelMessageRepliesUseCase>(
      () => _i689.GetChannelMessageRepliesUseCase(
        gh<_i964.ChannelMessageRepository>(),
      ),
    );
    gh.lazySingleton<_i689.GetChannelMessageReplyCountUseCase>(
      () => _i689.GetChannelMessageReplyCountUseCase(
        gh<_i964.ChannelMessageRepository>(),
      ),
    );
    gh.lazySingleton<_i58.GetStorageStatsUseCase>(
      () => _i58.GetStorageStatsUseCase(gh<_i240.StorageRepository>()),
    );
    gh.lazySingleton<_i58.DeleteFeedNotesUseCase>(
      () => _i58.DeleteFeedNotesUseCase(gh<_i240.StorageRepository>()),
    );
    gh.lazySingleton<_i58.DeleteAllChatHistoryUseCase>(
      () => _i58.DeleteAllChatHistoryUseCase(gh<_i240.StorageRepository>()),
    );
    gh.lazySingleton<_i894.GetAvailableAIModelsUseCase>(
      () => _i894.GetAvailableAIModelsUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i894.GetActiveAIModelUseCase>(
      () => _i894.GetActiveAIModelUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i894.DownloadAndActivateAIModelUseCase>(
      () => _i894.DownloadAndActivateAIModelUseCase(
        gh<_i646.AIModelRepository>(),
      ),
    );
    gh.lazySingleton<_i894.ClearActiveAIModelUseCase>(
      () => _i894.ClearActiveAIModelUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i894.GetDownloadedModelIdsUseCase>(
      () => _i894.GetDownloadedModelIdsUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i894.DeleteAIModelUseCase>(
      () => _i894.DeleteAIModelUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i858.UnsaveNoteUseCase>(
      () => _i858.UnsaveNoteUseCase(
        gh<_i43.SavedNoteRepository>(),
        gh<_i179.DeleteKnowledgeForNoteUseCase>(),
      ),
    );
    gh.lazySingleton<_i524.CreateChannelMessageUseCase>(
      () => _i524.CreateChannelMessageUseCase(
        gh<_i964.ChannelMessageRepository>(),
        gh<_i1039.EventQueueRepository>(),
      ),
    );
    gh.lazySingleton<_i1033.CreateChannelUseCase>(
      () => _i1033.CreateChannelUseCase(
        gh<_i127.ChannelRepository>(),
        gh<_i1039.EventQueueRepository>(),
        gh<_i194.SubscriptionRecordRepository>(),
      ),
    );
    gh.factory<_i801.DrawerBloc>(
      () => _i801.DrawerBloc(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i561.GetAllFollowedNotesUseCase>(),
        gh<_i722.GetChannelsUseCase>(),
      ),
    );
    gh.lazySingleton<_i179.ExtractKnowledgeUseCase>(
      () => _i179.ExtractKnowledgeUseCase(
        gh<_i761.AIModelRunner>(),
        gh<_i197.PromptBuilder>(),
        gh<_i756.SearchVectorNotesUseCase>(),
        gh<_i649.GraphRepository>(),
        gh<_i331.MemoryRepository>(),
      ),
    );
    gh.lazySingleton<_i475.PublishNoteUseCase>(
      () => _i475.PublishNoteUseCase(
        gh<_i47.NoteRepository>(),
        gh<_i1039.EventQueueRepository>(),
      ),
    );
    gh.lazySingleton<_i475.GetReplyCountUseCase>(
      () => _i475.GetReplyCountUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetThreadReplyCountUseCase>(
      () => _i475.GetThreadReplyCountUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetOwnNotesUseCase>(
      () => _i475.GetOwnNotesUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.SearchNotesUseCase>(
      () => _i475.SearchNotesUseCase(gh<_i47.NoteRepository>()),
    );
    gh.factory<_i97.FollowedNotesCubit>(
      () => _i97.FollowedNotesCubit(
        gh<_i561.GetAllFollowedNotesUseCase>(),
        gh<_i561.FollowNoteUseCase>(),
        gh<_i561.UnfollowNoteUseCase>(),
        gh<_i561.ClearNewReferencesUseCase>(),
      ),
    );
    gh.factory<_i195.EditProfileCubit>(
      () => _i195.EditProfileCubit(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i391.SaveProfileUseCase>(),
      ),
    );
    gh.lazySingleton<_i285.VectorSearchService>(
      () => _i285.VectorSearchService(gh<_i756.SearchVectorNotesUseCase>()),
    );
    gh.lazySingleton<_i985.GetRelaysUseCase>(
      () => _i985.GetRelaysUseCase(gh<_i993.RelayRepository>()),
    );
    gh.lazySingleton<_i756.EmbedAndStoreNoteUseCase>(
      () => _i756.EmbedAndStoreNoteUseCase(
        gh<_i828.EmbeddingService>(),
        gh<_i739.VectorRepository>(),
        gh<_i179.ExtractKnowledgeUseCase>(),
      ),
    );
    gh.factory<_i53.SelectAIModelCubit>(
      () => _i53.SelectAIModelCubit(
        gh<_i894.GetAvailableAIModelsUseCase>(),
        gh<_i894.GetActiveAIModelUseCase>(),
        gh<_i894.GetDownloadedModelIdsUseCase>(),
        gh<_i894.DownloadAndActivateAIModelUseCase>(),
        gh<_i894.DeleteAIModelUseCase>(),
        gh<_i113.EmbeddingModelDownloader>(),
      ),
    );
    gh.factory<_i731.SettingsCubit>(
      () => _i731.SettingsCubit(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
      ),
    );
    gh.factory<_i234.CreateChannelBloc>(
      () => _i234.CreateChannelBloc(
        gh<_i985.GetRelaysUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i1033.CreateChannelUseCase>(),
      ),
    );
    gh.factory<_i888.StorageCubit>(
      () => _i888.StorageCubit(
        gh<_i58.GetStorageStatsUseCase>(),
        gh<_i58.DeleteFeedNotesUseCase>(),
        gh<_i58.DeleteAllChatHistoryUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
      ),
    );
    gh.lazySingleton<_i179.GetMemoriesByNoteIdsUseCase>(
      () => _i179.GetMemoriesByNoteIdsUseCase(gh<_i331.MemoryRepository>()),
    );
    gh.lazySingleton<_i799.GetActiveUserProfileUseCase>(
      () => _i799.GetActiveUserProfileUseCase(
        gh<_i103.UserRepository>(),
        gh<_i967.ProfileRepository>(),
      ),
    );
    gh.lazySingleton<_i1067.RagPipeline>(
      () => _i1067.RagPipeline(
        gh<_i828.EmbeddingService>(),
        gh<_i285.VectorSearchService>(),
        gh<_i197.PromptBuilder>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i179.GetMemoriesByNoteIdsUseCase>(),
        gh<_i179.GetGraphNeighboursUseCase>(),
        gh<_i179.GetGraphNodesByKeysUseCase>(),
        gh<_i894.GetActiveAIModelUseCase>(),
      ),
    );
    gh.factory<_i334.ShivAIBloc>(
      () => _i334.ShivAIBloc(
        gh<_i604.GetConversationsUseCase>(),
        gh<_i604.CreateConversationUseCase>(),
        gh<_i604.DeleteConversationUseCase>(),
        gh<_i604.GetMessagesUseCase>(),
        gh<_i604.SaveMessageUseCase>(),
        gh<_i604.UpdateMessageContentUseCase>(),
        gh<_i604.UpdateConversationTitleUseCase>(),
        gh<_i604.UpdateActiveLeafUseCase>(),
        gh<_i761.AIModelRunner>(),
        gh<_i1067.RagPipeline>(),
      ),
    );
    gh.factory<_i536.GraphBloc>(
      () => _i536.GraphBloc(
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i475.GetOwnNotesUseCase>(),
        gh<_i537.GetDraftsUseCase>(),
        gh<_i799.GetActiveUserProfileUseCase>(),
        gh<_i537.DeleteDraftUseCase>(),
        gh<_i391.GetProfileUseCase>(),
      ),
    );
    gh.factory<_i558.VishnuFeedBloc>(
      () => _i558.VishnuFeedBloc(
        gh<_i475.GetFeedUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i858.SaveNoteUseCase>(),
        gh<_i858.UnsaveNoteUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
      ),
    );
    gh.factory<_i787.BrahmaCreateBloc>(
      () => _i787.BrahmaCreateBloc(
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i475.PublishNoteUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
        gh<_i537.SaveDraftUseCase>(),
        gh<_i537.GetDraftsUseCase>(),
        gh<_i537.DeleteDraftUseCase>(),
        gh<_i475.SearchNotesUseCase>(),
        gh<_i475.GetNoteByIdUseCase>(),
      ),
    );
    gh.factory<_i118.ThreadBloc>(
      () => _i118.ThreadBloc(
        gh<_i475.GetNoteByIdUseCase>(),
        gh<_i475.GetRepliesUseCase>(),
        gh<_i475.PublishNoteUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
      ),
    );
    return this;
  }
}

class _$IsarModule extends _i146.IsarModule {}

class _$TostoreModule extends _i740.TostoreModule {}
