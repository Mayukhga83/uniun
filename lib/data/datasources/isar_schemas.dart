// isar_schemas.dart

import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/user_key_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/dm/dm_message_model.dart';
import 'package:uniun/data/models/dm/encrypted_dm_model.dart';
import 'package:uniun/data/models/draft_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/ai_model_selection_model.dart';
import 'package:uniun/data/models/app_settings_model.dart';
import 'package:uniun/data/models/shiv_conversation_model.dart';
import 'package:uniun/data/models/shiv_message_model.dart';
import 'package:uniun/data/models/relay_model.dart';
import 'package:uniun/data/models/channel_model.dart';
import 'package:uniun/data/models/channel_message_model.dart';
import 'package:uniun/data/models/subscription_record_model.dart';
import 'package:uniun/data/models/missing_profile_pubkey_model.dart';
import 'package:uniun/data/models/graph_node_model.dart';
import 'package:uniun/data/models/graph_edge_model.dart';
import 'package:uniun/data/models/memory_node_model.dart';

final List<CollectionSchema> isarSchemas = [
  NoteModelSchema,
  UserKeyModelSchema,
  ProfileModelSchema,
  FollowedNoteModelSchema,
  EventQueueModelSchema,
  DmConversationModelSchema,
  DmMessageModelSchema,
  DraftModelSchema,
  SavedNoteModelSchema,
  AIModelSelectionModelSchema,
  AppSettingsModelSchema,
  ShivConversationModelSchema,
  ShivMessageModelSchema,
  RelayModelSchema,
  ChannelModelSchema,
  ChannelMessageModelSchema,
  SubscriptionRecordModelSchema,
  EncryptedDmModelSchema,
  MissingProfilePubkeyModelSchema,
  GraphNodeModelSchema,
  GraphEdgeModelSchema,
  MemoryNodeModelSchema,
];
