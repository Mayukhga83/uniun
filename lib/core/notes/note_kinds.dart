/// Nostr event kinds stored in the unified `Note` collection.
///
/// Every user-visible message — feed note, channel message, DM, private-channel
/// message — lives in one `NoteModel` collection discriminated by [kind].
///   - [kNoteKind]            (1)    short text note (Vishnu feed)
///   - [kChannelMessageKind]  (42)   NIP-28 public channel message
///   - [kDmTextKind]          (14)   NIP-17 direct message (text)
///   - [kDmFileKind]          (15)   NIP-17 direct message (file)
///   - [kPrivateChannelKind]  (9023) NIP-29 private channel message
///
/// Decrypted MLS payloads for private channels carry no real Nostr kind; we
/// store the wire-envelope kind (9023) as a stable, documented sentinel so the
/// resolver/feed can discriminate them.
const int kNoteKind = 1;
const int kChannelMessageKind = 42;
const int kDmTextKind = 14;
const int kDmFileKind = 15;
const int kPrivateChannelKind = 9023;

/// NIP-37 draft wrap. Parameterized replaceable; `["d", draftId]` keys it. The
/// inner draft event (Kind 1 unsigned payload) is JSON-stringified, NIP-44
/// self-encrypted, and placed in `.content`. Empty content signals deletion.
const int kDraftWrapKind = 31234;
