/// One reconcilable collection (Notes, SavedNotes, Profiles, DeletedNote
/// tombstones, …) presented to the [TrustedSyncEngine] as an opaque key→row set.
///
/// The engine never interprets rows; it only diffs [localKeys] against the peer's
/// keys and ships the rows the peer is missing. Each Isar-backed implementation
/// chooses a stable key (e.g. `eventId`) and a `toJson`/`fromJson`, so reconciling
/// stays content-addressed and idempotent.
abstract class SyncScope {
  /// Stable scope identifier on the wire (e.g. 'note', 'savedNote', 'deletedNote').
  String get name;

  /// The keys this device currently holds for the scope.
  Future<Set<String>> localKeys();

  /// Serialized rows for [keys] this device holds (missing keys are skipped).
  Future<List<Map<String, dynamic>>> rows(Set<String> keys);

  /// Idempotently upserts received rows.
  Future<void> upsert(List<Map<String, dynamic>> rows);
}
