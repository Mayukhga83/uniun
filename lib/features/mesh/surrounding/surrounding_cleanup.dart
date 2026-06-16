import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/surrounding_note_model.dart';

/// Evicts surrounding notes older than a cutoff (called daily). Cache eviction,
/// not deletion — surrounding notes are inherently ephemeral.
class SurroundingCleanup {
  SurroundingCleanup(this._isar);

  final Isar _isar;

  Future<int> evictReceivedBefore(DateTime cutoff) async {
    var count = 0;
    await _isar.writeTxn(() async {
      count = await _isar.surroundingNoteModels
          .filter()
          .receivedAtLessThan(cutoff)
          .deleteAll();
    });
    return count;
  }
}
