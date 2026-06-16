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
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:tostore/tostore.dart' as _i789;
import 'package:uniun/common/widgets/composer/cubit/reference_picker_cubit.dart'
    as _i734;
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart'
    as _i226;
import 'package:uniun/data/datasources/app_settings_store.dart' as _i107;
import 'package:uniun/data/datasources/feed_read_state_store.dart' as _i752;
import 'package:uniun/data/datasources/isar_module.dart' as _i146;
import 'package:uniun/data/datasources/llm/llm_credentials_data_source.dart'
    as _i981;
import 'package:uniun/data/datasources/llm/llm_preferences_data_source.dart'
    as _i634;
import 'package:uniun/data/datasources/llm/local_inference_queue.dart' as _i393;
import 'package:uniun/data/datasources/llm/local_llm_data_source.dart' as _i937;
import 'package:uniun/data/datasources/llm/local_llm_runner.dart' as _i937;
import 'package:uniun/data/datasources/llm/remote_llm_data_source.dart'
    as _i141;
import 'package:uniun/data/datasources/surrounding_read_state_store.dart'
    as _i156;
import 'package:uniun/data/datasources/tostore_module.dart' as _i740;
import 'package:uniun/data/repositories/ai_model_repository_impl.dart' as _i72;
import 'package:uniun/data/repositories/blocked_user_repository_impl.dart'
    as _i877;
import 'package:uniun/data/repositories/channel_message_repository_impl.dart'
    as _i929;
import 'package:uniun/data/repositories/channel_repository_impl.dart' as _i1009;
import 'package:uniun/data/repositories/deleted_note_repository_impl.dart'
    as _i438;
import 'package:uniun/data/repositories/dm_conversation_repository_impl.dart'
    as _i1011;
import 'package:uniun/data/repositories/dm_message_repository_impl.dart'
    as _i398;
import 'package:uniun/data/repositories/draft_repository_impl.dart' as _i640;
import 'package:uniun/data/repositories/e2ee_group_repository_impl.dart'
    as _i896;
import 'package:uniun/data/repositories/event_queue_repository_impl.dart'
    as _i116;
import 'package:uniun/data/repositories/feed_repository_impl.dart' as _i689;
import 'package:uniun/data/repositories/followed_note_repository_impl.dart'
    as _i107;
import 'package:uniun/data/repositories/followed_user_repository_impl.dart'
    as _i791;
import 'package:uniun/data/repositories/graph_repository_impl.dart' as _i250;
import 'package:uniun/data/repositories/llm_credentials_repository_impl.dart'
    as _i147;
import 'package:uniun/data/repositories/llm_repository_impl.dart' as _i19;
import 'package:uniun/data/repositories/memory_repository_impl.dart' as _i849;
import 'package:uniun/data/repositories/note_relation_repository_impl.dart'
    as _i126;
import 'package:uniun/data/repositories/note_repository_impl.dart' as _i348;
import 'package:uniun/data/repositories/note_resolver_repository_impl.dart'
    as _i526;
import 'package:uniun/data/repositories/pending_extraction_repository_impl.dart'
    as _i754;
import 'package:uniun/data/repositories/profile_repository_impl.dart' as _i484;
import 'package:uniun/data/repositories/relay_repository_impl.dart' as _i542;
import 'package:uniun/data/repositories/saved_note_repository_impl.dart'
    as _i669;
import 'package:uniun/data/repositories/share_repository_impl.dart' as _i593;
import 'package:uniun/data/repositories/shiv_repository_impl.dart' as _i412;
import 'package:uniun/data/repositories/source_label_repository_impl.dart'
    as _i395;
import 'package:uniun/data/repositories/storage_repository_impl.dart' as _i209;
import 'package:uniun/data/repositories/surrounding_note_repository_impl.dart'
    as _i670;
import 'package:uniun/data/repositories/tostore_vector_repository_impl.dart'
    as _i831;
import 'package:uniun/data/repositories/unread_repository_impl.dart' as _i1024;
import 'package:uniun/data/repositories/user_repository_impl.dart' as _i582;
import 'package:uniun/domain/entities/note/note_entity.dart' as _i697;
import 'package:uniun/domain/repositories/ai_model_repository.dart' as _i646;
import 'package:uniun/domain/repositories/blocked_user_repository.dart'
    as _i756;
import 'package:uniun/domain/repositories/channel_message_repository.dart'
    as _i964;
import 'package:uniun/domain/repositories/channel_repository.dart' as _i127;
import 'package:uniun/domain/repositories/deleted_note_repository.dart'
    as _i775;
import 'package:uniun/domain/repositories/dm_conversation_repository.dart'
    as _i189;
import 'package:uniun/domain/repositories/dm_message_repository.dart' as _i551;
import 'package:uniun/domain/repositories/draft_repository.dart' as _i170;
import 'package:uniun/domain/repositories/e2ee_group_repository.dart' as _i635;
import 'package:uniun/domain/repositories/event_queue_repository.dart'
    as _i1039;
import 'package:uniun/domain/repositories/feed_repository.dart' as _i250;
import 'package:uniun/domain/repositories/followed_note_repository.dart'
    as _i836;
import 'package:uniun/domain/repositories/followed_user_repository.dart'
    as _i849;
import 'package:uniun/domain/repositories/graph_repository.dart' as _i649;
import 'package:uniun/domain/repositories/llm_credentials_repository.dart'
    as _i819;
import 'package:uniun/domain/repositories/llm_repository.dart' as _i205;
import 'package:uniun/domain/repositories/memory_repository.dart' as _i331;
import 'package:uniun/domain/repositories/note_relation_repository.dart'
    as _i1017;
import 'package:uniun/domain/repositories/note_repository.dart' as _i47;
import 'package:uniun/domain/repositories/note_resolver_repository.dart'
    as _i789;
import 'package:uniun/domain/repositories/pending_extraction_repository.dart'
    as _i1000;
import 'package:uniun/domain/repositories/profile_repository.dart' as _i967;
import 'package:uniun/domain/repositories/relay_repository.dart' as _i993;
import 'package:uniun/domain/repositories/saved_note_repository.dart' as _i43;
import 'package:uniun/domain/repositories/share_repository.dart' as _i1019;
import 'package:uniun/domain/repositories/shiv_repository.dart' as _i266;
import 'package:uniun/domain/repositories/source_label_repository.dart'
    as _i633;
import 'package:uniun/domain/repositories/storage_repository.dart' as _i240;
import 'package:uniun/domain/repositories/surrounding_note_repository.dart'
    as _i956;
import 'package:uniun/domain/repositories/unread_repository.dart' as _i497;
import 'package:uniun/domain/repositories/user_repository.dart' as _i103;
import 'package:uniun/domain/repositories/vector_repository.dart' as _i739;
import 'package:uniun/domain/services/marmot_mls_service.dart' as _i168;
import 'package:uniun/domain/services/marmot_transport_service.dart' as _i761;
import 'package:uniun/domain/usecases/ai_model_usecases.dart' as _i894;
import 'package:uniun/domain/usecases/blocked_user_usecases.dart' as _i278;
import 'package:uniun/domain/usecases/create_channel_message_usecase.dart'
    as _i524;
import 'package:uniun/domain/usecases/create_channel_usecase.dart' as _i1033;
import 'package:uniun/domain/usecases/delete_relay_usecase.dart' as _i700;
import 'package:uniun/domain/usecases/deleted_note_usecases.dart' as _i232;
import 'package:uniun/domain/usecases/dm_usecases.dart' as _i1023;
import 'package:uniun/domain/usecases/draft_usecases.dart' as _i537;
import 'package:uniun/domain/usecases/feed_usecases.dart' as _i837;
import 'package:uniun/domain/usecases/followed_note_usecases.dart' as _i561;
import 'package:uniun/domain/usecases/followed_user_usecases.dart' as _i63;
import 'package:uniun/domain/usecases/get_channel_by_id_usecase.dart' as _i263;
import 'package:uniun/domain/usecases/get_channel_messages_usecase.dart'
    as _i689;
import 'package:uniun/domain/usecases/get_channels_usecase.dart' as _i722;
import 'package:uniun/domain/usecases/get_relays_usecase.dart' as _i985;
import 'package:uniun/domain/usecases/knowledge_usecases.dart' as _i179;
import 'package:uniun/domain/usecases/llm_usecases.dart' as _i918;
import 'package:uniun/domain/usecases/note_usecases.dart' as _i475;
import 'package:uniun/domain/usecases/post_reply_usecase.dart' as _i924;
import 'package:uniun/domain/usecases/private_channel_usecases.dart' as _i78;
import 'package:uniun/domain/usecases/profile_usecases.dart' as _i391;
import 'package:uniun/domain/usecases/save_channel_usecase.dart' as _i67;
import 'package:uniun/domain/usecases/save_relay_usecase.dart' as _i433;
import 'package:uniun/domain/usecases/saved_note_usecases.dart' as _i858;
import 'package:uniun/domain/usecases/share_usecases.dart' as _i1;
import 'package:uniun/domain/usecases/shiv_usecases.dart' as _i604;
import 'package:uniun/domain/usecases/source_label_usecases.dart' as _i978;
import 'package:uniun/domain/usecases/storage_usecases.dart' as _i58;
import 'package:uniun/domain/usecases/unread_usecases.dart' as _i719;
import 'package:uniun/domain/usecases/user_usecases.dart' as _i799;
import 'package:uniun/domain/usecases/vector_usecases.dart' as _i756;
import 'package:uniun/features/brahma/bloc/brahma_create_bloc.dart' as _i886;
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart' as _i830;
import 'package:uniun/features/channels/create/bloc/create_channel_bloc.dart'
    as _i501;
import 'package:uniun/features/channels/join/bloc/join_channel_bloc.dart'
    as _i750;
import 'package:uniun/features/dm/chat/bloc/dm_chat_bloc.dart' as _i60;
import 'package:uniun/features/dm/create/bloc/create_dm_bloc.dart' as _i399;
import 'package:uniun/features/mesh/service/mesh_service.dart' as _i421;
import 'package:uniun/features/private_channels/create/bloc/create_private_channel_bloc.dart'
    as _i636;
import 'package:uniun/features/private_channels/detail/bloc/private_channel_detail_bloc.dart'
    as _i10;
import 'package:uniun/features/private_channels/join/bloc/join_private_channel_bloc.dart'
    as _i926;
import 'package:uniun/features/profile/bloc/user_profile_bloc.dart' as _i959;
import 'package:uniun/features/settings/cubit/edit_profile_cubit.dart' as _i859;
import 'package:uniun/features/settings/cubit/settings_cubit.dart' as _i331;
import 'package:uniun/features/settings/cubit/storage_cubit.dart' as _i13;
import 'package:uniun/features/share/bloc/share_sheet_bloc.dart' as _i574;
import 'package:uniun/features/shiv/chat/bloc/shiv_ai_bloc.dart' as _i190;
import 'package:uniun/features/shiv/model_select/cubit/select_ai_model_cubit.dart'
    as _i687;
import 'package:uniun/features/shiv/rag/embedding/embedding_model_downloader.dart'
    as _i850;
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart'
    as _i587;
import 'package:uniun/features/shiv/rag/pipeline/rag_pipeline.dart' as _i681;
import 'package:uniun/features/shiv/rag/prompt/prompt_builder.dart' as _i207;
import 'package:uniun/features/shiv/rag/retrieval/vector_search_service.dart'
    as _i961;
import 'package:uniun/features/thread/bloc/thread_bloc.dart' as _i807;
import 'package:uniun/features/vishnu/bloc/vishnu_feed_bloc.dart' as _i1039;
import 'package:uniun/features/vishnu/drawer/bloc/drawer_bloc.dart' as _i666;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final sharedPreferencesModule = _$SharedPreferencesModule();
    final isarModule = _$IsarModule();
    final tostoreModule = _$TostoreModule();
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => sharedPreferencesModule.sharedPreferences(),
      preResolve: true,
    );
    await gh.singletonAsync<_i214.Isar>(
      () => isarModule.createIsar(),
      preResolve: true,
    );
    gh.singleton<_i981.LlmCredentialsDataSource>(
      () => _i981.LlmCredentialsDataSource(),
    );
    await gh.singletonAsync<_i789.ToStore>(
      () => tostoreModule.createTostore(),
      preResolve: true,
    );
    gh.lazySingleton<_i393.ModelTaskQueue>(() => _i393.ModelTaskQueue());
    gh.lazySingleton<_i168.MarmotMlsService>(() => _i168.MarmotMlsService());
    gh.lazySingleton<_i850.EmbeddingModelDownloader>(
      () => _i850.EmbeddingModelDownloader(),
    );
    gh.lazySingleton<_i587.EmbeddingService>(() => _i587.EmbeddingService());
    gh.lazySingleton<_i207.PromptBuilder>(() => const _i207.PromptBuilder());
    gh.lazySingleton<_i739.VectorRepository>(
      () => _i831.TostoreVectorRepositoryImpl(
        gh<_i789.ToStore>(),
        gh<_i214.Isar>(),
      ),
    );
    gh.factory<_i266.ShivRepository>(
      () => _i412.ShivRepositoryImpl(gh<_i214.Isar>()),
    );
    gh.factory<_i633.SourceLabelRepository>(
      () => _i395.SourceLabelRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i189.DmConversationRepository>(
      () => _i1011.DmConversationRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i1017.NoteRelationRepository>(
      () => _i126.NoteRelationRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i1000.PendingExtractionRepository>(
      () => _i754.PendingExtractionRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i756.BlockedUserRepository>(
      () => _i877.BlockedUserRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i649.GraphRepository>(
      () => _i250.GraphRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.singleton<_i107.AppSettingsStore>(
      () => _i107.AppSettingsStore(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i107.UserKeyStore>(
      () => _i107.UserKeyStore(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i752.FeedReadStateStore>(
      () => _i752.FeedReadStateStore(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i634.LlmPreferencesDataSource>(
      () => _i634.LlmPreferencesDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i156.SurroundingReadStateStore>(
      () => _i156.SurroundingReadStateStore(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i836.FollowedNoteRepository>(
      () => _i107.FollowedNoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i775.DeletedNoteRepository>(
      () => _i438.DeletedNoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i761.MarmotTransportService>(
      () => _i761.MarmotTransportService(
        gh<_i214.Isar>(),
        gh<_i168.MarmotMlsService>(),
        gh<_i1017.NoteRelationRepository>(),
      ),
    );
    gh.factory<_i43.SavedNoteRepository>(
      () => _i669.SavedNoteRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
      ),
    );
    gh.lazySingleton<_i635.E2EEGroupRepository>(
      () => _i896.E2EEGroupRepositoryImpl(gh<_i214.Isar>()),
    );
    gh.factory<_i1039.EventQueueRepository>(
      () => _i116.EventQueueRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i103.UserRepository>(
      () => _i582.UserRepositoryImpl(gh<_i107.UserKeyStore>()),
    );
    gh.factory<_i967.ProfileRepository>(
      () => _i484.ProfileRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i789.NoteResolverRepository>(
      () => _i526.NoteResolverRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
      ),
    );
    gh.lazySingleton<_i937.AIModelRunner>(
      () => _i937.AIModelRunner(
        gh<_i393.ModelTaskQueue>(),
        gh<_i107.AppSettingsStore>(),
      ),
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
    gh.lazySingleton<_i67.SaveChannelUseCase>(
      () => _i67.SaveChannelUseCase(gh<_i127.ChannelRepository>()),
    );
    gh.lazySingleton<_i1023.GetDmConversationsUseCase>(
      () => _i1023.GetDmConversationsUseCase(
        gh<_i189.DmConversationRepository>(),
      ),
    );
    gh.lazySingleton<_i1023.CreateDmConversationUseCase>(
      () => _i1023.CreateDmConversationUseCase(
        gh<_i189.DmConversationRepository>(),
      ),
    );
    gh.lazySingleton<_i799.GetActiveUserProfileUseCase>(
      () => _i799.GetActiveUserProfileUseCase(
        gh<_i103.UserRepository>(),
        gh<_i967.ProfileRepository>(),
      ),
    );
    gh.lazySingleton<_i978.ResolveSourceLabelsUseCase>(
      () => _i978.ResolveSourceLabelsUseCase(gh<_i633.SourceLabelRepository>()),
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
    gh.lazySingleton<_i561.WatchIsFollowedUseCase>(
      () => _i561.WatchIsFollowedUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_i561.ClearNewReferencesUseCase>(
      () => _i561.ClearNewReferencesUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.factory<_i331.MemoryRepository>(
      () => _i849.MemoryRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i497.UnreadRepository>(
      () => _i1024.UnreadRepositoryImpl(isar: gh<_i214.Isar>()),
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
    gh.lazySingleton<_i391.WatchProfileUseCase>(
      () => _i391.WatchProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_i391.RequestProfileFetchUseCase>(
      () => _i391.RequestProfileFetchUseCase(gh<_i967.ProfileRepository>()),
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
    gh.lazySingleton<_i858.GetSavedRepliesUseCase>(
      () => _i858.GetSavedRepliesUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.GetSavedReferencesUseCase>(
      () => _i858.GetSavedReferencesUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i421.MeshService>(
      () => _i421.MeshService(
        gh<_i214.Isar>(),
        gh<_i103.UserRepository>(),
        gh<_i107.AppSettingsStore>(),
      ),
    );
    gh.factory<_i240.StorageRepository>(
      () => _i209.StorageRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i78.CreatePrivateChannelUsecase>(
      () =>
          _i78.CreatePrivateChannelUsecase(gh<_i761.MarmotTransportService>()),
    );
    gh.lazySingleton<_i78.SendPrivateChannelMessageUsecase>(
      () => _i78.SendPrivateChannelMessageUsecase(
        gh<_i761.MarmotTransportService>(),
      ),
    );
    gh.lazySingleton<_i78.JoinPrivateChannelUsecase>(
      () => _i78.JoinPrivateChannelUsecase(gh<_i761.MarmotTransportService>()),
    );
    gh.lazySingleton<_i78.ApprovePrivateChannelJoinUsecase>(
      () => _i78.ApprovePrivateChannelJoinUsecase(
        gh<_i761.MarmotTransportService>(),
      ),
    );
    gh.lazySingleton<_i78.LeavePrivateChannelUsecase>(
      () => _i78.LeavePrivateChannelUsecase(gh<_i761.MarmotTransportService>()),
    );
    gh.factory<_i47.NoteRepository>(
      () => _i348.NoteRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
        resolver: gh<_i789.NoteResolverRepository>(),
      ),
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
    gh.lazySingleton<_i78.GetPrivateChannelsUsecase>(
      () => _i78.GetPrivateChannelsUsecase(gh<_i635.E2EEGroupRepository>()),
    );
    gh.lazySingleton<_i78.GetPrivateChannelEntityUsecase>(
      () =>
          _i78.GetPrivateChannelEntityUsecase(gh<_i635.E2EEGroupRepository>()),
    );
    gh.lazySingleton<_i78.GetPrivateChannelMessagesUsecase>(
      () => _i78.GetPrivateChannelMessagesUsecase(
        gh<_i635.E2EEGroupRepository>(),
      ),
    );
    gh.lazySingleton<_i78.GetPrivateChannelJoinRequestsUsecase>(
      () => _i78.GetPrivateChannelJoinRequestsUsecase(
        gh<_i635.E2EEGroupRepository>(),
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
    gh.lazySingleton<_i858.UnsaveNoteUseCase>(
      () => _i858.UnsaveNoteUseCase(
        gh<_i43.SavedNoteRepository>(),
        gh<_i179.DeleteKnowledgeForNoteUseCase>(),
      ),
    );
    gh.lazySingleton<_i232.DeleteNoteUseCase>(
      () => _i232.DeleteNoteUseCase(gh<_i775.DeletedNoteRepository>()),
    );
    gh.factory<_i849.FollowedUserRepository>(
      () => _i791.FollowedUserRepositoryImpl(
        isar: gh<_i214.Isar>(),
        eventQueue: gh<_i1039.EventQueueRepository>(),
        getActiveUserKeys: gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factory<_i170.DraftRepository>(
      () => _i640.DraftRepositoryImpl(
        isar: gh<_i214.Isar>(),
        eventQueue: gh<_i1039.EventQueueRepository>(),
        getActiveUserKeys: gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factory<_i646.AIModelRepository>(
      () => _i72.AIModelRepositoryImpl(
        gh<_i214.Isar>(),
        gh<_i107.AppSettingsStore>(),
      ),
    );
    gh.factory<_i636.CreatePrivateChannelBloc>(
      () => _i636.CreatePrivateChannelBloc(
        gh<_i78.CreatePrivateChannelUsecase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factory<_i399.CreateDmBloc>(
      () => _i399.CreateDmBloc(
        gh<_i993.RelayRepository>(),
        gh<_i1023.CreateDmConversationUseCase>(),
      ),
    );
    gh.factory<_i956.SurroundingNoteRepository>(
      () => _i670.SurroundingNoteRepositoryImpl(
        isar: gh<_i214.Isar>(),
        readStore: gh<_i156.SurroundingReadStateStore>(),
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
    gh.lazySingleton<_i278.GetBlockedUsersUseCase>(
      () => _i278.GetBlockedUsersUseCase(gh<_i756.BlockedUserRepository>()),
    );
    gh.lazySingleton<_i278.BlockUserUseCase>(
      () => _i278.BlockUserUseCase(gh<_i756.BlockedUserRepository>()),
    );
    gh.lazySingleton<_i278.UnblockUserUseCase>(
      () => _i278.UnblockUserUseCase(gh<_i756.BlockedUserRepository>()),
    );
    gh.lazySingleton<_i961.VectorSearchService>(
      () => _i961.VectorSearchService(gh<_i756.SearchVectorNotesUseCase>()),
    );
    gh.lazySingleton<_i700.DeleteRelayUseCase>(
      () => _i700.DeleteRelayUseCase(gh<_i993.RelayRepository>()),
    );
    gh.lazySingleton<_i985.GetRelaysUseCase>(
      () => _i985.GetRelaysUseCase(gh<_i993.RelayRepository>()),
    );
    gh.lazySingleton<_i433.SaveRelayUseCase>(
      () => _i433.SaveRelayUseCase(gh<_i993.RelayRepository>()),
    );
    gh.lazySingleton<_i719.MarkUnreadSeenUseCase>(
      () => _i719.MarkUnreadSeenUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i719.MarkChannelSeenUseCase>(
      () => _i719.MarkChannelSeenUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i719.MarkPrivateChannelSeenUseCase>(
      () => _i719.MarkPrivateChannelSeenUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i719.MarkConversationSeenUseCase>(
      () => _i719.MarkConversationSeenUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i719.GetChannelOldestUnreadTimeUseCase>(
      () =>
          _i719.GetChannelOldestUnreadTimeUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i141.RemoteLlmDataSource>(
      () => _i141.RemoteLlmDataSource(
        gh<_i981.LlmCredentialsDataSource>(),
        gh<_i634.LlmPreferencesDataSource>(),
      ),
    );
    gh.lazySingleton<_i937.LocalLlmDataSource>(
      () => _i937.LocalLlmDataSource(
        gh<_i937.AIModelRunner>(),
        gh<_i393.ModelTaskQueue>(),
        gh<_i646.AIModelRepository>(),
      ),
    );
    gh.factoryParam<_i10.PrivateChannelDetailBloc, String, dynamic>(
      (groupId, _) => _i10.PrivateChannelDetailBloc(
        gh<_i78.GetPrivateChannelEntityUsecase>(),
        gh<_i78.GetPrivateChannelMessagesUsecase>(),
        gh<_i78.GetPrivateChannelJoinRequestsUsecase>(),
        gh<_i78.SendPrivateChannelMessageUsecase>(),
        gh<_i78.ApprovePrivateChannelJoinUsecase>(),
        gh<_i78.LeavePrivateChannelUsecase>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i719.MarkUnreadSeenUseCase>(),
        gh<_i719.MarkPrivateChannelSeenUseCase>(),
        groupId,
      ),
    );
    gh.factory<_i551.DmMessageRepository>(
      () => _i398.DmMessageRepositoryImpl(
        isar: gh<_i214.Isar>(),
        resolver: gh<_i789.NoteResolverRepository>(),
      ),
    );
    gh.lazySingleton<_i1033.CreateChannelUseCase>(
      () => _i1033.CreateChannelUseCase(
        gh<_i127.ChannelRepository>(),
        gh<_i1039.EventQueueRepository>(),
      ),
    );
    gh.factory<_i964.ChannelMessageRepository>(
      () => _i929.ChannelMessageRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
        resolver: gh<_i789.NoteResolverRepository>(),
      ),
    );
    gh.factory<_i331.SettingsCubit>(
      () => _i331.SettingsCubit(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
      ),
    );
    gh.factory<_i501.CreateChannelBloc>(
      () => _i501.CreateChannelBloc(
        gh<_i985.GetRelaysUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i1033.CreateChannelUseCase>(),
      ),
    );
    gh.factory<_i13.StorageCubit>(
      () => _i13.StorageCubit(
        gh<_i58.GetStorageStatsUseCase>(),
        gh<_i58.DeleteFeedNotesUseCase>(),
        gh<_i58.DeleteAllChatHistoryUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
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
    gh.lazySingleton<_i1023.SendDmUseCase>(
      () => _i1023.SendDmUseCase(
        gh<_i214.Isar>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i189.DmConversationRepository>(),
      ),
    );
    gh.factory<_i205.LlmRepository>(
      () => _i19.LlmRepositoryImpl(
        gh<_i937.LocalLlmDataSource>(),
        gh<_i141.RemoteLlmDataSource>(),
        gh<_i634.LlmPreferencesDataSource>(),
        gh<_i981.LlmCredentialsDataSource>(),
        gh<_i107.AppSettingsStore>(),
        gh<_i646.AIModelRepository>(),
      ),
    );
    gh.lazySingleton<_i179.GetMemoriesByNoteIdsUseCase>(
      () => _i179.GetMemoriesByNoteIdsUseCase(gh<_i331.MemoryRepository>()),
    );
    gh.lazySingleton<_i391.PublishProfileMetadataUseCase>(
      () => _i391.PublishProfileMetadataUseCase(
        gh<_i1039.EventQueueRepository>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.lazySingleton<_i1023.GetDmUseCase>(
      () => _i1023.GetDmUseCase(
        gh<_i214.Isar>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factory<_i926.JoinPrivateChannelBloc>(
      () => _i926.JoinPrivateChannelBloc(
        gh<_i78.JoinPrivateChannelUsecase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factory<_i250.FeedRepository>(
      () => _i689.FeedRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
        sourceLabels: gh<_i633.SourceLabelRepository>(),
        follows: gh<_i849.FollowedUserRepository>(),
        users: gh<_i103.UserRepository>(),
        feedReadState: gh<_i752.FeedReadStateStore>(),
        resolver: gh<_i789.NoteResolverRepository>(),
      ),
    );
    gh.lazySingleton<_i1023.FetchDmUseCase>(
      () => _i1023.FetchDmUseCase(
        gh<_i189.DmConversationRepository>(),
        gh<_i551.DmMessageRepository>(),
      ),
    );
    gh.factory<_i60.DmChatBloc>(
      () => _i60.DmChatBloc(
        gh<_i1023.FetchDmUseCase>(),
        gh<_i1023.SendDmUseCase>(),
        gh<_i1023.GetDmUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i799.GetActiveUserProfileUseCase>(),
        gh<_i719.MarkUnreadSeenUseCase>(),
        gh<_i719.MarkConversationSeenUseCase>(),
        gh<_i214.Isar>(),
      ),
    );
    gh.lazySingleton<_i689.GetChannelMessagesUseCase>(
      () =>
          _i689.GetChannelMessagesUseCase(gh<_i964.ChannelMessageRepository>()),
    );
    gh.lazySingleton<_i689.GetChannelMessagesAfterUseCase>(
      () => _i689.GetChannelMessagesAfterUseCase(
        gh<_i964.ChannelMessageRepository>(),
      ),
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
    gh.lazySingleton<_i63.FollowUserUseCase>(
      () => _i63.FollowUserUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.UnfollowUserUseCase>(
      () => _i63.UnfollowUserUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.IsFollowingUseCase>(
      () => _i63.IsFollowingUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.GetFollowedUsersUseCase>(
      () => _i63.GetFollowedUsersUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.GetFollowedPubkeysUseCase>(
      () => _i63.GetFollowedPubkeysUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.WatchFollowedUsersUseCase>(
      () => _i63.WatchFollowedUsersUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.factory<_i750.JoinChannelBloc>(
      () => _i750.JoinChannelBloc(
        gh<_i985.GetRelaysUseCase>(),
        gh<_i433.SaveRelayUseCase>(),
        gh<_i67.SaveChannelUseCase>(),
      ),
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
    gh.factory<_i830.GraphBloc>(
      () => _i830.GraphBloc(
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i475.GetOwnNotesUseCase>(),
        gh<_i537.GetDraftsUseCase>(),
        gh<_i799.GetActiveUserProfileUseCase>(),
        gh<_i537.DeleteDraftUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i214.Isar>(),
      ),
    );
    gh.factory<_i734.ReferencePickerCubit>(
      () => _i734.ReferencePickerCubit(
        gh<_i475.GetFeedUseCase>(),
        gh<_i475.SearchNotesUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
      ),
    );
    gh.lazySingleton<_i524.CreateChannelMessageUseCase>(
      () => _i524.CreateChannelMessageUseCase(
        gh<_i964.ChannelMessageRepository>(),
        gh<_i1039.EventQueueRepository>(),
      ),
    );
    gh.factory<_i959.UserProfileBloc>(
      () => _i959.UserProfileBloc(
        gh<_i475.GetOwnNotesUseCase>(),
        gh<_i63.IsFollowingUseCase>(),
        gh<_i63.FollowUserUseCase>(),
        gh<_i63.UnfollowUserUseCase>(),
        gh<_i391.WatchProfileUseCase>(),
        gh<_i391.RequestProfileFetchUseCase>(),
      ),
    );
    gh.factory<_i859.EditProfileCubit>(
      () => _i859.EditProfileCubit(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i391.SaveProfileUseCase>(),
        gh<_i391.PublishProfileMetadataUseCase>(),
      ),
    );
    gh.factory<_i819.LlmCredentialsRepository>(
      () => _i147.LlmCredentialsRepositoryImpl(
        gh<_i981.LlmCredentialsDataSource>(),
        gh<_i141.RemoteLlmDataSource>(),
      ),
    );
    gh.factory<_i666.DrawerBloc>(
      () => _i666.DrawerBloc(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i561.GetAllFollowedNotesUseCase>(),
        gh<_i722.GetChannelsUseCase>(),
        gh<_i78.GetPrivateChannelsUsecase>(),
        gh<_i63.GetFollowedUsersUseCase>(),
        gh<_i985.GetRelaysUseCase>(),
        gh<_i214.Isar>(),
      ),
    );
    gh.lazySingleton<_i918.HasActiveLlmModelUseCase>(
      () => _i918.HasActiveLlmModelUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.OpenLlmConversationUseCase>(
      () => _i918.OpenLlmConversationUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.CloseLlmConversationUseCase>(
      () => _i918.CloseLlmConversationUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.SendChatStreamUseCase>(
      () => _i918.SendChatStreamUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.GenerateOneShotUseCase>(
      () => _i918.GenerateOneShotUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.PreemptBackgroundWorkUseCase>(
      () => _i918.PreemptBackgroundWorkUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.ResumeBackgroundWorkUseCase>(
      () => _i918.ResumeBackgroundWorkUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.GetActiveLlmBackendUseCase>(
      () => _i918.GetActiveLlmBackendUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.SetActiveLlmBackendUseCase>(
      () => _i918.SetActiveLlmBackendUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.ListAvailableLlmModelsUseCase>(
      () => _i918.ListAvailableLlmModelsUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.SetActiveLlmModelUseCase>(
      () => _i918.SetActiveLlmModelUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.GetActiveLlmModelUseCase>(
      () => _i918.GetActiveLlmModelUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i681.RagPipeline>(
      () => _i681.RagPipeline(
        gh<_i587.EmbeddingService>(),
        gh<_i961.VectorSearchService>(),
        gh<_i207.PromptBuilder>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i179.GetMemoriesByNoteIdsUseCase>(),
        gh<_i179.GetGraphNeighboursUseCase>(),
        gh<_i179.GetGraphNodesByKeysUseCase>(),
        gh<_i918.GetActiveLlmModelUseCase>(),
      ),
    );
    gh.factory<_i687.SelectAIModelCubit>(
      () => _i687.SelectAIModelCubit(
        gh<_i894.GetAvailableAIModelsUseCase>(),
        gh<_i894.GetActiveAIModelUseCase>(),
        gh<_i894.GetDownloadedModelIdsUseCase>(),
        gh<_i894.DownloadAndActivateAIModelUseCase>(),
        gh<_i894.DeleteAIModelUseCase>(),
        gh<_i850.EmbeddingModelDownloader>(),
      ),
    );
    gh.factory<_i1019.ShareRepository>(
      () => _i593.ShareRepositoryImpl(
        gh<_i789.NoteResolverRepository>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i475.PublishNoteUseCase>(),
        gh<_i524.CreateChannelMessageUseCase>(),
        gh<_i1023.SendDmUseCase>(),
        gh<_i78.SendPrivateChannelMessageUsecase>(),
      ),
    );
    gh.lazySingleton<_i918.SaveOpenRouterKeyUseCase>(
      () =>
          _i918.SaveOpenRouterKeyUseCase(gh<_i819.LlmCredentialsRepository>()),
    );
    gh.lazySingleton<_i918.ClearOpenRouterKeyUseCase>(
      () =>
          _i918.ClearOpenRouterKeyUseCase(gh<_i819.LlmCredentialsRepository>()),
    );
    gh.lazySingleton<_i918.HasOpenRouterKeyUseCase>(
      () => _i918.HasOpenRouterKeyUseCase(gh<_i819.LlmCredentialsRepository>()),
    );
    gh.lazySingleton<_i1.ShareNoteUseCase>(
      () => _i1.ShareNoteUseCase(gh<_i1019.ShareRepository>()),
    );
    gh.lazySingleton<_i837.GetOrInitFeedLoadedAtUseCase>(
      () => _i837.GetOrInitFeedLoadedAtUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.SetFeedLoadedAtUseCase>(
      () => _i837.SetFeedLoadedAtUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.GetUnreadPageUseCase>(
      () => _i837.GetUnreadPageUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.GetSeenPageUseCase>(
      () => _i837.GetSeenPageUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.WatchNewBufferCountUseCase>(
      () => _i837.WatchNewBufferCountUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.MarkFeedItemSeenUseCase>(
      () => _i837.MarkFeedItemSeenUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i179.ExtractKnowledgeUseCase>(
      () => _i179.ExtractKnowledgeUseCase(
        gh<_i918.HasActiveLlmModelUseCase>(),
        gh<_i918.GenerateOneShotUseCase>(),
        gh<_i207.PromptBuilder>(),
        gh<_i756.SearchVectorNotesUseCase>(),
        gh<_i649.GraphRepository>(),
        gh<_i331.MemoryRepository>(),
        gh<_i1000.PendingExtractionRepository>(),
      ),
    );
    gh.factory<_i574.ShareSheetBloc>(
      () => _i574.ShareSheetBloc(
        gh<_i722.GetChannelsUseCase>(),
        gh<_i78.GetPrivateChannelsUsecase>(),
        gh<_i1023.GetDmConversationsUseCase>(),
        gh<_i1.ShareNoteUseCase>(),
      ),
    );
    gh.lazySingleton<_i756.EmbedAndStoreNoteUseCase>(
      () => _i756.EmbedAndStoreNoteUseCase(
        gh<_i587.EmbeddingService>(),
        gh<_i739.VectorRepository>(),
        gh<_i179.ExtractKnowledgeUseCase>(),
      ),
    );
    gh.factory<_i1039.VishnuFeedBloc>(
      () => _i1039.VishnuFeedBloc(
        gh<_i837.GetOrInitFeedLoadedAtUseCase>(),
        gh<_i837.SetFeedLoadedAtUseCase>(),
        gh<_i837.GetUnreadPageUseCase>(),
        gh<_i837.GetSeenPageUseCase>(),
        gh<_i837.WatchNewBufferCountUseCase>(),
        gh<_i837.MarkFeedItemSeenUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i858.SaveNoteUseCase>(),
        gh<_i858.UnsaveNoteUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
        gh<_i63.WatchFollowedUsersUseCase>(),
      ),
    );
    gh.factory<_i886.BrahmaCreateBloc>(
      () => _i886.BrahmaCreateBloc(
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
    gh.factoryParam<_i226.NoteCardCubit, _i697.NoteEntity, dynamic>(
      (note, _) => _i226.NoteCardCubit(
        gh<_i391.WatchProfileUseCase>(),
        gh<_i391.RequestProfileFetchUseCase>(),
        gh<_i858.IsSavedNoteUseCase>(),
        gh<_i858.SaveNoteUseCase>(),
        gh<_i858.UnsaveNoteUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
        gh<_i561.WatchIsFollowedUseCase>(),
        gh<_i561.FollowNoteUseCase>(),
        gh<_i561.UnfollowNoteUseCase>(),
        gh<_i278.BlockUserUseCase>(),
        gh<_i232.DeleteNoteUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
        note,
      ),
    );
    gh.lazySingleton<_i179.DrainPendingExtractionsUseCase>(
      () => _i179.DrainPendingExtractionsUseCase(
        gh<_i1000.PendingExtractionRepository>(),
        gh<_i179.ExtractKnowledgeUseCase>(),
      ),
    );
    gh.lazySingleton<_i924.PostReplyUseCase>(
      () => _i924.PostReplyUseCase(
        gh<_i475.PublishNoteUseCase>(),
        gh<_i524.CreateChannelMessageUseCase>(),
        gh<_i78.SendPrivateChannelMessageUsecase>(),
        gh<_i1023.SendDmUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
      ),
    );
    gh.factory<_i807.ThreadBloc>(
      () => _i807.ThreadBloc(
        gh<_i789.NoteResolverRepository>(),
        gh<_i924.PostReplyUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i858.GetSavedRepliesUseCase>(),
        gh<_i858.GetSavedReferencesUseCase>(),
      ),
    );
    gh.factory<_i190.ShivAIBloc>(
      () => _i190.ShivAIBloc(
        gh<_i604.GetConversationsUseCase>(),
        gh<_i604.CreateConversationUseCase>(),
        gh<_i604.DeleteConversationUseCase>(),
        gh<_i604.GetMessagesUseCase>(),
        gh<_i604.SaveMessageUseCase>(),
        gh<_i604.UpdateMessageContentUseCase>(),
        gh<_i604.UpdateConversationTitleUseCase>(),
        gh<_i604.UpdateActiveLeafUseCase>(),
        gh<_i918.HasActiveLlmModelUseCase>(),
        gh<_i918.OpenLlmConversationUseCase>(),
        gh<_i918.CloseLlmConversationUseCase>(),
        gh<_i918.SendChatStreamUseCase>(),
        gh<_i918.PreemptBackgroundWorkUseCase>(),
        gh<_i918.ResumeBackgroundWorkUseCase>(),
        gh<_i681.RagPipeline>(),
        gh<_i179.DrainPendingExtractionsUseCase>(),
      ),
    );
    return this;
  }
}

class _$SharedPreferencesModule extends _i107.SharedPreferencesModule {}

class _$IsarModule extends _i146.IsarModule {}

class _$TostoreModule extends _i740.TostoreModule {}
