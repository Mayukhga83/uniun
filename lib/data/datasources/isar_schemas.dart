// isar_schemas.dart

import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/followed_user_model.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/dm/encrypted_dm_model.dart';
import 'package:uniun/data/models/draft_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/ai_model_selection_model.dart';
import 'package:uniun/data/models/shiv_conversation_model.dart';
import 'package:uniun/data/models/shiv_message_model.dart';
import 'package:uniun/data/models/relay_model.dart';
import 'package:uniun/data/models/channel_model.dart';
import 'package:uniun/data/models/missing_profile_pubkey_model.dart';
import 'package:uniun/data/models/private_channel_model.dart';
import 'package:uniun/data/models/encrypted_message_model.dart';
import 'package:uniun/data/models/private_channel_join_request_model.dart';
import 'package:uniun/data/models/graph_node_model.dart';
import 'package:uniun/data/models/graph_edge_model.dart';
import 'package:uniun/data/models/memory_node_model.dart';
import 'package:uniun/data/models/pending_extraction_model.dart';
import 'package:uniun/data/models/note_relation_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/models/blocked_user_model.dart';
import 'package:uniun/data/models/deleted_note_model.dart';
import 'package:uniun/data/models/surrounding_note_model.dart';
import 'package:uniun/data/models/mesh/mesh_peer_state_model.dart';

final List<CollectionSchema> isarSchemas = [
  NoteModelSchema,
  ProfileModelSchema,
  FollowedNoteModelSchema,
  FollowedUserModelSchema,
  EventQueueModelSchema,
  DmConversationModelSchema,
  DraftModelSchema,
  SavedNoteModelSchema,
  AIModelSelectionModelSchema,
  ShivConversationModelSchema,
  ShivMessageModelSchema,
  RelayModelSchema,
  ChannelModelSchema,
  EncryptedDmModelSchema,
  MissingProfilePubkeyModelSchema,
  PrivateChannelModelSchema,
  EncryptedMessageModelSchema,
  PrivateChannelJoinRequestModelSchema,
  GraphNodeModelSchema,
  GraphEdgeModelSchema,
  MemoryNodeModelSchema,
  PendingExtractionModelSchema,
  NoteRelationModelSchema,
  UnreadNoteModelSchema,
  BlockedUserModelSchema,
  DeletedNoteModelSchema,
  SurroundingNoteModelSchema,
  MeshPeerStateModelSchema,
];

