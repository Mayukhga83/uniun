/// FNV-1a 64-bit hash of [string]. Used to derive a deterministic Isar `Id` from
/// a natural string key (Isar primary keys must be `int`, so a stable string key
/// is hashed to an int). The same string yields the same id on every device,
/// which is what makes such rows safe to reconcile across devices by their
/// natural key. Collision probability across realistic key counts is negligible.
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;
  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }
  return hash;
}
