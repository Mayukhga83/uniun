import 'package:isar_community/isar.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/draft_model.dart';
import 'package:uniun/gateway/subscriptions/subscription_provider.dart';

/// NIP-37 draft wraps authored by the active user.
///
/// Pulls every Kind 31234 event whose `author == ownPubkey` so a freshly
/// installed device reconciles the user's drafts. NIP-77 negotiation through
/// [Nip77Synchronizer] keeps subsequent re-syncs cheap; only deltas transfer.
class DraftsSubscription extends SubscriptionProvider {
  @override
  String get subId => 'drafts';

  @override
  Future<Map<String, dynamic>?> buildFilter(SubscriptionContext ctx) async {
    final pubkey = ctx.activePubkey;
    if (pubkey == null) return null;
    return {
      'kinds': [kDraftWrapKind],
      'authors': [pubkey],
    };
  }

  @override
  Future<Map<String, int>> localIndex(SubscriptionContext ctx) async {
    final rows = await ctx.isar.draftModels
        .filter()
        .lastSyncedEventIdIsNotNull()
        .findAll();
    return {
      for (final r in rows)
        if (r.lastSyncedEventId != null && r.lastSyncedCreatedAt != null)
          r.lastSyncedEventId!:
              r.lastSyncedCreatedAt!.millisecondsSinceEpoch ~/ 1000,
    };
  }
}
