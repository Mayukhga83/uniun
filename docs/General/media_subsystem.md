# UNIUN Media Subsystem

How photos, videos and files travel from one device through our relay to another. Read top to bottom and you'll be able to answer any question about it.

---

## 1. What problem does this solve?

A Nostr event is a tiny signed JSON blob. Putting raw photo bytes inside it would be terrible:
- Every relay would store and forward megabytes per post.
- Most relays cap event size at 64–256 KB and would just reject big events.
- The same picture quoted into ten chats would be transmitted ten times.

So Nostr splits the job in two:

| Layer | Carries | Stored by | Format |
|-------|---------|-----------|--------|
| **Nostr relay** | Tiny **signed events** that *reference* a blob by its hash | Khatru + BadgerDB | JSON over WebSocket |
| **Blossom server** | The actual **bytes** of the blob | Khatru blossom + Azure Blob Storage | Raw HTTP PUT / GET |

Our backend in `uniun-backend/` runs **both** services on the same host (`dev.uniun.in:8080`) — `wss://` is the relay, `https://` is Blossom — but they're logically independent.

---

## 2. NIPs used

### NIP-92 — Inline media metadata

Defines the `imeta` tag that attaches blob metadata to *any* Nostr event:

```
["imeta",
  "url https://dev.uniun.in:8080/<sha256>.jpg",
  "m image/jpeg",
  "x <sha256-hex>",
  "size 482133",
  "dim 1920x1080",
  "blurhash LKO2?U%2Tw=w]~RBVZRi};RPxuwH"
]
```

Each sub-string after the tag name is `key value`. Multiple `imeta` tags = multiple attachments.

The `m` (mime) field is **mime-agnostic** — `image/jpeg`, `video/mp4`, `audio/ogg`, `application/pdf` all valid.

The mime also picks the cached file's extension (`media/<sha256>.<ext>`). A **download** carries no filename, so the mime alone must map — a mime missing from `_mimeToExt` caches as a bare `<sha256>` that the OS cannot open. Once cached, a PDF or `.docx` is also indexed for Shiv (`DocumentIndexer`); see `docs/SHIVA/rag.md` → "Documents (PDF, DOCX)".

### NIP-B7 — Blossom

The HTTP protocol for content-addressed blob storage. Three BUDs we use:

- **BUD-01** — the upload / download / list / delete endpoints. Auth via Kind 24242.
- **BUD-02** — list / delete (we use list, not delete in v1).
- **BUD-03** — Kind 10063 `User Server List`. Tells other clients which Blossom servers a user prefers.

### Kind 24242 — Blossom auth

A signed Nostr event that proves to a Blossom server "this user authorized this action on this blob right now". Not stored anywhere — it's sent inline in the HTTP `Authorization` header as `Nostr <base64(JSON event)>`.

```jsonc
{
  "kind": 24242,
  "created_at": <unixSec>,
  "tags": [
    ["t", "upload"],                 // or "get" | "list" | "delete"
    ["x", "<sha256-of-blob>"],       // omitted for list
    ["expiration", "<unixSec+300>"]  // 5-minute window
  ],
  "content": "Upload",
  "pubkey": "<own>", "id": "...", "sig": "..."
}
```

### Kind 10063 — User server list (BUD-03)

Replaceable per-pubkey event listing the user's preferred Blossom servers.

```jsonc
{
  "kind": 10063,
  "tags": [["server", "https://dev.uniun.in:8080"]],
  "content": ""
}
```

We publish one on first upload so a second device knows where to fetch the user's media from.

### Kind 1 / Kind 42 — host events

The text note (`kind: 1`) or channel message (`kind: 42`) is what actually goes on the timeline. Its `tags` array carries one `imeta` per attachment. The host event is what gets re-broadcast; the bytes never leave the Blossom server until someone explicitly downloads them.

---

## 3. Big picture

Imeta metadata lives **on the note**. The only side table is a small cache
that tracks which blobs are on this device. No ref counts, no automatic GC,
no `MediaBlobModel`, no `NoteMediaRefModel`. Removal is user-driven via the
gallery.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            UNIUN CLIENT (Flutter)                        │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ Presentation                                                      │   │
│  │   BrahmaCreateBloc · NoteCard · MediaAttachmentView · Gallery    │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              │ use cases                                 │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ Domain                                                            │   │
│  │   NoteEntity · MediaBlobEntity · MediaRepository ports            │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              │                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ Data                                                              │   │
│  │   ┌──────────────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │   │ Isar                 │  │ BlossomClient│  │ MediaCacheDS │  │   │
│  │   │  NoteModel           │  │   (HTTP)     │  │   (path_     │  │   │
│  │   │   ├ attachments      │  │              │  │   provider)  │  │   │
│  │   │   │  (embedded list  │  │              │  │              │  │   │
│  │   │   │   of imeta)      │  │              │  │  media/      │  │   │
│  │   │   └ hasMedia (bool)  │  │              │  │   <sha>.<ext>│  │   │
│  │   │  MediaCacheModel     │  │              │  │              │  │   │
│  │   │   sha→localPath      │  │              │  │              │  │   │
│  │   └──────────────────────┘  └──────────────┘  └──────────────┘  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              ↑ writes Isar                               │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ Gateway isolate                                                   │   │
│  │   inbound handlers (Kind1/Kind42/Kind10063)  ·  EventQueue        │   │
│  │   CleanupManager (note retention only — no media GC)              │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└────────────────────┬─────────────────────┬──────────────────────────────┘
                     │ WSS                 │ HTTPS
                     │ Nostr (events)      │ Blossom (bytes)
┌────────────────────▼─────────────────────▼──────────────────────────────┐
│                         UNIUN BACKEND (Go)                               │
│   ┌──────────────────────────┐    ┌────────────────────────────┐        │
│   │ Khatru relay             │    │ Khatru blossom handler     │        │
│   │  · BadgerDB (events)     │    │  PUT/GET/HEAD/list/delete  │        │
│   │  · MySQL mirror          │    │                            │        │
│   └──────────────────────────┘    └─────────────┬──────────────┘        │
│                                                  │                        │
│                                                  ▼                        │
│                                       ┌────────────────────┐             │
│                                       │ Azure Blob Storage │             │
│                                       └────────────────────┘             │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 4. End-to-end flows

### 4.1 Upload — sender publishes a note with a photo

```
┌─ Compose page (graph_compose_page.dart) ─────────────────────────────┐
│                                                                       │
│  User taps 📷 ─► showComposeMediaSheet(context)                       │
│                       │                                               │
│                       ▼                                               │
│            ┌─────────────────────────────┐                            │
│            │  Bottom sheet               │                            │
│            │   • Photo                   │                            │
│            │   • Video                   │                            │
│            │   • File                    │                            │
│            └─────────────┬───────────────┘                            │
│                          │ pick Photo                                 │
│                          ▼                                            │
│             ImagePicker.pickImage(gallery)                            │
│                          │                                            │
│                          ▼                                            │
│            ┌────────────────────────────────┐                         │
│            │ ImageCompressor.compressToTarget│                        │
│            │   target = 950 KB              │                         │
│            │   88q/2048 → 30q/800 schedule  │                         │
│            └────────────┬───────────────────┘                         │
│                         │  ok                                         │
│                         ▼                                             │
│         decode dim via dart:ui (width × height)                       │
│                         │                                             │
│                         ▼                                             │
│  bloc.add(UploadAndAttachMediaEvent(bytes, mime, dim, filename))      │
└──────────────────────────────┬────────────────────────────────────────┘
                               │
┌──────────────────────────────▼────────────────────────────────────────┐
│ BrahmaCreateBloc._onUploadAndAttachMedia                              │
│   emit(isAttachingMedia=true)   ─►   composer shows spinner            │
│                                                                        │
│   ┌──────────────────────────────────────────────────────────────┐    │
│   │ MediaRepositoryImpl.uploadBytes                              │    │
│   │   sha = sha256(bytes)                                        │    │
│   │   server = AppConstants.kUniunBlossom                        │    │
│   │                                                              │    │
│   │   HEAD /<sha>           ┐                                    │    │
│   │     200 → skip PUT (server already has it; dedup)            │    │
│   │     404 → PUT /upload   ┘                                    │    │
│   │         Authorization: Nostr <base64 Kind-24242 event>       │    │
│   │         Content-Type: image/jpeg                             │    │
│   │         body: <bytes>                                        │    │
│   │   ─► response: { url, sha256, size, type }                   │    │
│   │       NOTE: response.url is *ignored*. Khatru derives it from│    │
│   │       relay.URL which is `wss://…` — useless for HTTP fetch. │    │
│   │       We build publicUrl from `kUniunBlossom` ourselves.     │    │
│   │                                                              │    │
│   │   write local cache: media/<sha>.jpg                         │    │
│   │   upsert MediaCacheModel(sha, localPath, downloadedAt)       │    │
│   │   first upload only: setServers([primary]) → Kind 10063      │    │
│   └──────────────────────────────────────────────────────────────┘    │
│                                                                        │
│   state.attachedMedia += MediaBlobEntity (sha + imeta fields)          │
│   emit(isAttachingMedia=false)   ─►   thumbnail shows, send unlocks    │
└────────────────────────────────────────────────────────────────────────┘

User types text · taps Send

┌─ BrahmaCreateBloc._onSubmitNote ───────────────────────────────────────┐
│                                                                        │
│   tags = buildNoteTags(root, reply, mentions, hashtags)                │
│   for each attached blob:                                              │
│      tags += ["imeta", "url …", "m …", "x …", "size …",                │
│               "dim WxH", "blurhash …"]                                 │
│                                                                        │
│   signed = Event.from(kind:1, tags:tags, content, privkey)             │
│                                                                        │
│   NoteEntity built with attachments=[…] (hasMedia derived)             │
│                                                                        │
│   ┌──────────────────────────────────────────────────────────────┐    │
│   │ PublishMediaNoteUseCase                                      │    │
│   │   noteRepo.saveNote(entity) → NoteModel with embedded        │    │
│   │                                attachments list              │    │
│   │   eventQueue.enqueueSignedEvent(                             │    │
│   │       content = note content (text only),                    │    │
│   │       imeta   = input.attachments)                           │    │
│   └──────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘

Gateway isolate · OutboundPump
   row.toSerializedRelayMessage()           ← single path, every kind
   WebSocketService.send(["EVENT", { …reconstructed with imeta… }])
   relay: ["OK", id, true]  ✓
```

### 4.2 Inbound — another device receives the note

```
Relay pushes ["EVENT", "feed_notes", { kind:1, tags:[imeta,…], … }]
       │
       ▼
InboundBus → Kind1NoteHandler
       │
       ├─► _parseNoteModel(event):
       │     - walks tags (e/p/t/q/subject)
       │     - calls ImetaParser.parseAsAttachments(event)
       │       → List<MediaAttachment> embedded directly on the note
       │     - NoteModel constructor derives hasMedia = attachments.isNotEmpty
       │
       ├─► writeTxn: noteModels.put(model)  ← one write, one row
       │
       └─► unread row, reply edges (existing logic)
```

At this point the receiver's Isar has **metadata only** — no bytes were transferred, no separate blob table, no join table. The note appears in the feed; the photo shows as a **blurhash placeholder + Download button**.

### 4.3 Read — viewer scrolls past the note

```
Vishnu feed loads page
       │
       ▼
FeedRepository.getUnseenQueue / getSeen
       │ rows from NoteModel (kind 1/42, author allow-list)
       │ each row already carries its embedded attachments
       ▼
NoteResolverRepository.enrichWithQuotes
       │
       ├─► quote-target NoteEntity lookup (single bulk query)
       ├─► NoteAttachmentsEnricher.enrichAll([page, quoteTargets])
       │     ONE query into MediaCacheModel for the unique sha256s
       │     mentioned by the page. Patches localPath/downloadedAt onto
       │     each MediaBlobEntity already on the NoteEntity.
       │
       ▼
List<NoteEntity> arrives at BLoC, attachments fully resolved.

NoteCard.build
       │
       └─► if (note.hasMedia) MediaAttachmentView(note, compact: true)
                                     │
                                     ▼
            _AttachmentTile          (StatefulWidget)
                                     │
                  ┌──────────────────┴───────────────────┐
                  │ localPath != null                    │ localPath == null
                  ▼                                      ▼
            Image.file(...)                  blurhash + Download button
            BoxFit.cover                     tap → DownloadMediaUseCase
            height ≤ 280px (compact)              (sha, url, mime)
                                                       │
                                                       ▼
                                BlossomClient.download(url)
                                      cache.write(sha, ext, bytes)
                                      upsert MediaCacheModel(localPath set)
                                      setState in tile → image shows
```

### 4.4 Gallery — user opens Settings → Storage → Media

```
MediaGalleryCubit.load
       │
       └─► WatchMediaUseCase
              ▼
       MediaRepository.watchAll(filter)
              ▼
       isar.mediaCacheModels.where().sortByDownloadedAtDesc()
              .watch(fireImmediately: true)
              .asyncMap: join each row to the first NoteModel that
                         carries the matching sha (recovers imeta
                         metadata for rendering) → MediaBlobEntity

Gallery only ever lists files actually on disk — `MediaCacheModel`
is the source of truth.

Each tile = MediaTile widget
  status badge : ✅ cached (the only state the tile has now)
  long-press   : toggles multi-select for bulk Remove from device

Tap → MediaDetailPage(sha256)
       loads cached entity (no network), shows preview + metadata
       + actions: Open / Save to device / Copy sha / Remove
```

### 4.5 Cleanup — note retention only

```
CleanupManager.runOnce  (every 6h)
   └─► Note eviction
         for each Kind 1 older than 7d:
           skip if authorPubkey == ownPubkey      (own forever)
           skip if in SavedNoteModel              (saved forever)
           else delete from NoteModel
         same logic for Kind 42 / >3d
```

**No media GC.** Files stay on disk until the user removes them via
Settings → Storage → Media (`MediaRepository.removeLocal`). Manual
control by design — the user decides when to free space.

---

## 5. Data model

### 5.1 Isar collections

```
NoteModel                  (existing — gained two media fields)
├── eventId   (unique)
├── content, sig, authorPubkey, …
├── attachments  List<MediaAttachment>   — embedded, one per imeta tag
├── hasMedia     (bool, indexed)         — derived = attachments.isNotEmpty
└── … (kind, threading, etc.)

MediaAttachment            (@embedded — lives inside NoteModel.attachments)
├── sha256
├── mime
├── sizeBytes
├── url
├── width / height
├── blurhash
└── filename

MediaCacheModel            (only media side table — "what's on this device")
├── id           (auto)
├── sha256       (unique)
├── localPath
└── downloadedAt

UserServerListModel        (single-row, id=0 — deferred SharedPreferences migration)
├── serverUrls                 default []
└── lastSyncedCreatedAt        nullable — LWW for inbound Kind 10063
```

There is **no** `MediaBlobModel` and **no** `NoteMediaRefModel`. Same SHA
appearing in three notes = three embedded entries (small — ~120 bytes
each) and one cache row. Cross-note rendering is consistent because the
cache lookup is keyed by SHA, not by note.

### 5.2 Domain entity enrichment

`NoteEntity` carries attachments pre-resolved by the data layer — same pattern as `cachedReplyCount`, `referenceCount`, `quotedNote`:

```dart
@freezed
abstract class NoteEntity with _$NoteEntity {
  const factory NoteEntity({
    // … existing fields
    @Default(false) bool hasMedia,
    @Default([])    List<MediaBlobEntity> attachments,
    // attachments is excluded from JSON via @JsonKey(includeFromJson: false,
    // includeToJson: false) — it's an in-memory enrichment, not wire data.
  }) = _NoteEntity;
}
```

UI widgets read `note.attachments` directly; nobody hits Isar from a card.

### 5.3 Retention table

| What | Retention |
|------|-----------|
| Own notes (any kind) | Forever |
| Saved notes (`SavedNoteModel`) | Forever |
| Kind 1 (regular) | 7 days |
| Kind 42 (channel) | 3 days |
| DM / private channel content | Forever |
| Media files (`MediaCacheModel` rows + disk bytes) | Forever (until user removes from device) |

---

## 6. UI behavior

### 6.1 Attachment tile sizing (Twitter/X pattern)

`MediaAttachmentView({required note, compact = true})` — single flag.

| Surface | Mode | Max height |
|---------|------|------------|
| Vishnu / channel / private channel feed | compact | **280 px** |
| Embedded quoted note | compact | 280 px |
| DM bubble (in / out) | compact | 280 px |
| Thread parent (`LargeNoteCard`) | **expanded** | **480 px** |
| Media detail page | n/a | full native aspect |

Layout in `_AttachmentTile`:
```dart
final naturalH = parentWidth / aspect;
final height = naturalH.clamp(0.0, maxH);
SizedBox(width: parentWidth, height: height,
         child: Image.file(..., fit: BoxFit.cover))
```

Wide / panoramic images render at natural aspect. Portraits and squares get cropped from top + bottom equally so the card stays scannable. The full image is always one tap away on the detail page.

### 6.2 Composer

`UniunComposer` exposes `onAttachMedia` + `attachments` + `isAttachingMedia` props.

- Round media button (📷) sits next to the reference and markdown buttons.
- A 72×72 thumbnail strip appears above the text field for each attached blob (× to remove).
- A 72×72 spinner tile shows while an upload is in flight.
- Send button disables while `isAttachingMedia` is true — prevents publishing a note before the imeta is ready.

### 6.3 Gallery

`Settings → Storage → Media` opens `MediaGalleryPage`.

Filter chips: **All · Images · Videos · Audio · Files**.

The gallery lists files actually on disk — `MediaCacheModel.findAll()`
joined to the first NoteModel that referenced each sha (for imeta
metadata). Inbound-only notes whose bytes haven't been downloaded yet
do **not** appear here; their NoteCard's Download button is where the
user pulls them.

Each tile shows a single ✅ cached badge. Long-press toggles multi-select;
the bulk action is "Remove from device" (deletes the file + cache row).

Tap → `MediaDetailPage` for the full preview, Open (non-images),
Save to device (OS share sheet → Photos/Files/Drive), Remove from
device, Copy sha. No pin, no copy URL — the URL is in the note's
imeta tag and anyone with the SHA can already derive it.

---

## 7. Capability matrix — what works today

| Capability | Server | Nostr | Client | Status |
|-----------|--------|-------|--------|--------|
| Upload image (≤950 KB after compression) | ✓ | ✓ | ✓ | **Works** |
| Auto-compress image to fit cap | n/a | n/a | ✓ (`flutter_image_compress`) | **Works** |
| Display image in feed (compact) | n/a | n/a | ✓ | **Works** |
| Display image in thread (expanded) | n/a | n/a | ✓ | **Works** |
| Display image in DM / quote / channel | n/a | n/a | ✓ | **Works** |
| Blurhash placeholder before download | n/a | ✓ (NIP-92 field) | ✓ render, ✗ encode | **Render works**, we don't compute blurhash on upload yet — placeholder falls back to mime icon |
| Multi-device sync of own-server list | ✓ | ✓ (Kind 10063) | ✓ | **Works** |
| Dedup via sha256 (HEAD before PUT) | ✓ | n/a | ✓ | **Works** |
| Pin / GC retention | n/a | n/a | ✓ | **Works** |
| Upload video (≤950 KB) | ✓ (mime-agnostic) | ✓ (NIP-92 `m video/*`) | ✓ upload works | **Works for tiny clips**. We don't transcode — anything bigger gets a snackbar |
| Render inline video player | n/a | n/a | ✗ | **Not yet** — tile shows movie icon; tap goes to detail page; detail also shows icon, no player |
| Upload arbitrary file (≤950 KB) | ✓ | ✓ (NIP-92 `m application/*`) | ✓ upload works | **Works for small files** |
| Open / preview file (PDF, doc, …) | n/a | n/a | ✗ | **Not yet** — file icon only |
| Large uploads (>950 KB) | ✓ Khatru can handle, but nginx caps at 1 MB by default | ✓ | ✗ — client refuses | **Blocked at nginx**. Two options: (a) bump `client_max_body_size` on the proxy; (b) keep the 950 KB cap and do background chunked upload in v2 |

### Plain-English answer to the question

**Does our backend support video / files?**
Yes. Khatru's blossom handler is **content-agnostic** — it hashes whatever bytes you PUT, regardless of mime. Azure Blob Storage stores whatever bytes the handler hands it. The relay accepts any Kind 1 / Kind 42 event with `imeta` tags regardless of the mime field.

**Does Nostr support video / files?**
Yes. NIP-92 makes no assumption about mime type — `image/*`, `video/*`, `audio/*`, `application/*` all valid.

**So what's missing?**
1. **nginx default cap of 1 MB** in front of the relay. Bigger videos hit this before reaching Khatru. Until raised, we cap the client at 950 KB.
2. **No inline video player** in the client (`MediaAttachmentView` shows a movie icon for `video/*`). Adding one is a UI-layer change only — the upload / download / cache plumbing is mime-agnostic and already works.
3. **No file viewer** for arbitrary mime types (PDF, doc, etc.). Same shape as above — tap → detail page → "Open externally" via `open_file` is a future addition.

So today: **images full end-to-end**. Videos/files are correctly plumbed through every layer; they're just bottlenecked at nginx and don't have rich preview UI yet. Lifting both is incremental, not a redesign.

---

## 8. Wire-format cheat sheet

### Kind 1 with one image attached (what flows to the relay)

```jsonc
{
  "id":   "<sha256 of canonical serialization>",
  "kind": 1,
  "created_at": 1789012345,
  "pubkey": "<own>",
  "tags": [
    ["e", "<root>",  "", "root"],
    ["p", "<mention>"],
    ["t", "uniun"],
    ["imeta",
      "url https://dev.uniun.in:8080/abc…123.jpg",
      "m image/jpeg",
      "x abc…123",
      "size 482133",
      "dim 1920x1080"
    ]
  ],
  "content": "look at this view!",
  "sig": "<schnorr signature>"
}
```

### Kind 24242 Blossom auth (sent as HTTP header, never to the relay)

```
Authorization: Nostr <base64({
  "kind":24242, "content":"Upload",
  "tags":[["t","upload"],["x","abc…123"],["expiration","1789012345"]],
  "pubkey":"<own>", "id":"…", "sig":"…"
})>
```

### Kind 10063 (BUD-03 user server list)

```jsonc
{
  "kind": 10063,
  "tags": [["server", "https://dev.uniun.in:8080"]],
  "content": ""
}
```

### Single serialization path — no raw-passthrough

Every kind serializes through `EventQueueModel.toSerializedRelayMessage`.
The model gained typed columns (`hTag`, `dTag`, `expirationSec`,
`serverTags`, `imeta`) so the shaped rebuilder can emit every tag the
publisher signed. Canonical order:

```
e root → e reply → e mention…
p…
t…
h          (NIP-29 private channel)
d          (NIP-37 draft id)
k          (NIP-18 quoted kind; also "1" for drafts)
q          (NIP-18 quote)
expiration (NIP-37)
server…    (BUD-03 / Kind 10063)
imeta…     (NIP-92)
```

Publishers must sign in this exact order — otherwise the re-serialized
event SHA-256 won't match the signed `eventId` and the relay rejects
the signature. The order lives in `event_queue_model.dart`; that file
is authoritative.

---

## 9. File map

```
Domain                                                            
├── lib/domain/entities/media/media_blob_entity.dart              freezed entity
├── lib/domain/entities/media/media_dim.dart                      freezed (w,h)
├── lib/domain/entities/media/media_filter.dart                   gallery filter
├── lib/domain/entities/note/note_entity.dart                     +attachments
├── lib/domain/repositories/media_repository.dart                 abstract
├── lib/domain/repositories/user_server_list_repository.dart      abstract
├── lib/domain/usecases/media_usecases.dart                       10 use cases

Data                                                              
├── lib/data/models/media/media_blob_model.dart                   manifest
├── lib/data/models/media/note_media_ref_model.dart               join table
├── lib/data/models/user_server_list_model.dart                   single-row
├── lib/data/datasources/blossom_client.dart                      HTTP client
├── lib/data/datasources/media_cache_data_source.dart             path_provider
├── lib/data/repositories/media_repository_impl.dart              orchestrator
├── lib/data/repositories/user_server_list_repository_impl.dart   K10063
├── lib/data/repositories/note_attachments_enricher.dart          bulk JOIN

Gateway                                                           
├── lib/gateway/inbound/imeta_parser.dart                         parse + persist
├── lib/gateway/inbound/handlers/kind10063_user_server_list_handler.dart
├── lib/gateway/cleanup/cleanup_manager.dart                      6h GC

Presentation                                                      
├── lib/common/widgets/note_card/media_attachment_view.dart       Twitter-sized
├── lib/features/media/cubit/media_gallery_cubit.dart
├── lib/features/media/cubit/media_detail_cubit.dart
├── lib/features/media/pages/media_gallery_page.dart
├── lib/features/media/pages/media_detail_page.dart
├── lib/features/media/widgets/media_tile.dart
├── lib/features/brahma/graph/widgets/compose_media_sheet.dart    pickers
├── lib/features/settings/widgets/media_row.dart                  Storage→Media
└── lib/common/snackbar.dart                                       AppSnackbar

Core                                                              
├── lib/core/constants/app_constants.dart                         kMaxUploadBytes
└── lib/core/utils/image_compressor.dart                          iterative JPEG
```

---

## 10. Verification checklist

End-to-end smoke, run in order. Most need two devices signed into the same identity.

1. **Schema migration** — `flutter pub run build_runner build --delete-conflicting-outputs` clean. App boots without Isar exceptions (collections `MediaBlob` + `NoteMediaRef` are gone; `MediaCache` is new; `NoteModel.attachments` is a new embedded list).
2. **Upload + publish** — attach a photo in Brahma, publish. Check:
   - composer shows spinner tile, then real thumbnail
   - send button blocked during upload, unlocked after
   - `EventQueueModel` row with `kind: 1`, `imeta` column populated, **no** rawPassthrough flag
   - Backend Azure container has `<sha256>.jpg`
   - Local `media/<sha256>.jpg` exists
   - Gallery shows the new blob with ✅ cached badge
3. **Render across surfaces** — same note in Vishnu (compact), in thread page (expanded), quoted by another note (compact in `EmbeddedNoteCard`), in Brahma's graph node panel.
4. **Inbound on second device** — relay streams the note. Check:
   - `NoteModel.attachments` populated from inbound `imeta`
   - No `MediaCacheModel` row yet (`localPath == null` semantics)
   - Note card renders blurhash placeholder + Download button (or mime icon if no blurhash)
5. **Tap Download** — bytes arrive; `MediaCacheModel` row appears; tile flips to image. A second note referencing the same SHA renders the cached file with no extra network call.
6. **Kind 10063 round-trip** — first upload publishes Kind 10063; relay accepts (no `bad sig`).
7. **Compression** — pick a 5 MB JPEG. Compressor walks the schedule, fits under 950 KB, uploads. No 413 from nginx.
8. **Hard-reject paths** — pick an oversized video → snackbar "File too large (… MB). Max … MB. Please compress it and try again."
9. **Manual removal** — gallery → long-press tiles → bulk delete. Files gone from disk, cache rows gone. Note cards revert to download button; no auto re-download.
10. **Sign-and-replay for every previously-rawPassthrough kind** — Kind 1 with imeta / Kind 42 with imeta / Kind 9023 (private channel send) / Kind 31234 (draft sync) / Kind 10063: relay accepts all. If any returns `["OK", id, false, "bad sig"]`, the canonical tag order is wrong somewhere.
11. **Static checks** — `flutter analyze lib/` clean. No hardcoded English (all via `AppLocalizations`).

---

## 10.5. Gotchas (production issues we've actually hit)

### Khatru's `descriptor.url` is a `wss://` URL

Khatru's blossom plugin is constructed as `blossom.New(relay, config.RelayURL)`. `RelayURL` is the relay's *WebSocket* URL (e.g. `wss://dev.uniun.in:8080`). The plugin uses that string verbatim when it returns blob descriptors, so `descriptor.url` ends up looking like:

```
wss://dev.uniun.in:8080/<sha256>.<ext>
```

If the publisher stored that and embedded it in the `imeta` tag, every other device would try to `http.get('wss://…')` and fail — silently before the snackbar fix below.

Both legs are now defended:

- **Outbound** (`MediaRepositoryImpl.uploadBytes`): the response's `url` field is discarded. We always build `publicUrl` from `kUniunBlossom` (the HTTPS base in `AppConstants`). The imeta tag carries `https://…` regardless of what the server returned.
- **Inbound / legacy rows** (`MediaRepositoryImpl._serverBase`): coerces `wss://` → `https://` and `ws://` → `http://` before any HTTP call, so notes received from older clients (or future relays with the same bug) still resolve to a fetchable origin.

If you ever change blob URL construction, keep both halves consistent.

### Silent download failure was invisible during testing

`MediaAttachmentView._download` used to do `res.fold((_) {}, …)` — the `Either<Failure, …>` Left was swallowed. Cross-device downloads could fail for any reason (the `wss://` bug, an expired auth token, a network blip) and the UI would simply… do nothing. No spinner change, no error.

Now it routes through `AppSnackbar.error(context, f.toMessage())` so the failure is visible to the user (and to whoever is QAing on a second device). If you're adding a new download trigger, keep this pattern: surface the Left, don't swallow it.

---

## 11. Open / deferred items

| Item | Why deferred |
|------|--------------|
| Blurhash encode on upload | `flutter_image_compress` doesn't ship an encoder. Adding `blurhash_dart` for encode + `compute()` for isolate-safe execution is straightforward when wanted. Until then, missing blurhash falls back to a mime-icon placeholder. |
| Inline video playback | Needs `video_player` or `chewie`. Same data flow; UI-only addition in `MediaAttachmentView`. |
| In-app file preview (PDF / doc) | `open_file` or a custom viewer per mime. Same data flow. |
| Background / chunked upload | For files >950 KB we'd need either (a) raise nginx cap and accept synchronous PUT, or (b) implement chunked PUT (Blossom spec extension). |
| Multi-server fan-out (BUD-03) | v1 publishes the single backend URL in Kind 10063. Fan-out to a list of servers + mirror fallback is a v2. |
| BUD-04 mirror | Cross-server replication so a deleted-from-one-server blob is still reachable. v2. |
| NIP-94 (Kind 1063) interop | Some clients publish file events separately from the carrier event. We don't emit or consume Kind 1063 in v1 — `imeta` on Kind 1 / 42 covers our use case. |

---

## 12. Five-minute mental model

If you forget everything else, remember this:

1. **Nostr carries text + references**. Bytes don't fit in events; they go elsewhere.
2. **Blossom is "elsewhere"** — an HTTP blob store keyed by sha256. Our backend runs one alongside the relay.
3. **`imeta` is the bridge** — a Nostr tag that says "this event references the blob at URL X with sha Y of type Z".
4. **Receivers see the metadata first, bytes only on demand.** Tap Download to fetch bytes. The blurhash or mime icon is the placeholder.
5. **Sha256 is identity.** The same blob in 10 notes = 1 upload + 1 cache entry on each receiver. The cache table dedups for free; the imeta metadata lives embedded on each note.
6. **No automatic media GC.** Files stay until the user removes them via the gallery. The cache table is the single record of what's on disk.
7. **Single serialization path.** Every kind (including imeta-bearing Kind 1 / 42, NIP-29 `h`-tag kinds, NIP-37 drafts, Kind 10063 server lists) flows through `EventQueueModel.toSerializedRelayMessage`. The canonical tag order lives there.
8. **Layers are strict.** UI reads `note.attachments` — the data layer (`NoteAttachmentsEnricher`) patched the cache state in. The gateway parses `imeta` on inbound. Nobody crosses lanes.


1. What is UserServerListRepository and why it exists

  Plain words: it stores the answer to "which Blossom servers does this user use
  for their media?"

  Why it was needed:

  - Nostr is decentralized. Your notes live on relays, but the bytes of your
  photos/videos live on Blossom servers (Azure-backed HTTP blob stores). These
  are two different machines.
  - When someone else sees your note imeta tag, they only see the SHA-256 hash.
  They need to know where to download the bytes from. That "where" is your
  server list.
  - The standard way to announce this is a Kind 10063 event (BUD-03 / NIP-B7).
  It's just a list of ["server", "https://..."] tags signed by you.

  Why a whole repository for one URL?

  1. Cache locally — we don't want to re-fetch the Kind 10063 event every time
  we upload a photo. The single-row UserServerListModel in Isar is that cache.
  2. Single source of truth — the uploader, the downloader, and the Brahma
  composer all ask the same place: "what's my Blossom server?"
  3. Future-proof — today we hardcode our own backend, but the moment we add a
  second server (BUD-03 fan-out), no code outside this repo needs to change.
  4. Sync across devices — log in on device B, the Gateway receives your Kind
  10063, Kind10063UserServerListHandler calls reconcileFromEvent(), and device B
  now knows the same servers without re-uploading anything.

  The Last-Write-Wins check on lastSyncedCreatedAt is so that an old event
  arriving late doesn't overwrite a newer one.

  ---
  2. Media system — end-to-end flow

  A. UPLOAD (Brahma composer → published note with image)

  User taps "Attach Image" in Brahma
          │
          ▼
  image_picker → File on disk
          │
          ▼
  compose_media_sheet.dart
     - checks size, compresses if needed (ImageCompressor / VideoCompressor)
     - Windows skips compression (no native backend)
          │
          ▼
  BrahmaCreateBloc.AttachImageEvent
          │
          ▼
  UploadMediaUseCase
          │
          ▼
  MediaRepositoryImpl.uploadFromFile()
     1. crypto.sha256 → compute hash of the bytes
     2. ask UserServerListRepository.getServers()  ◄── 1st use of Kind 10063
          → returns ["https://dev.uniun.in:8080"]
     3. BlossomClient.head(server, sha256)
          → if already there: skip upload (deduped)
     4. flutter_blurhash.encode (in compute() isolate)
     5. BlossomClient.upload(server, bytes, mime, keys)
          ├── signs Kind 24242 auth event  ◄── Blossom auth kind
          │     tags: [["t","upload"],["x",sha256],["expiration",now+5min]]
          ├── PUT  https://server/upload
          │     Header: Authorization: Nostr <base64(eventJson)>
          │     Body : raw bytes
          └── relay's Khatru + blossom plugin stores it in Azure
     6. MediaCacheDataSource.write(sha256, ext, bytes)
          → writes to <appSupport>/media/<sha256>.<ext>
     7. isar.writeTxn → upsert MediaCacheModel (sha → localPath, downloadedAt)
     8. First-ever upload → also publishes Kind 10063  ◄── 2nd use
          (so other devices learn your server)
          │
          ▼
  Brahma builds the Note event with an imeta tag:
     ["imeta",
       "url https://dev.uniun.in:8080/<sha256>.jpg",
       "m image/jpeg",
       "x <sha256>",
       "size 482133",
       "dim 1920x1080",
       "blurhash LKO2?U..."]
          │
          ▼
  EventQueueModel — imeta column carries the typed attachment list;
                  toSerializedRelayMessage rebuilds imeta in canonical order
          │
          ▼
  Gateway WebSocket → relay → other subscribers

  B. RECEIVE on another device (no download yet)

  Relay sends ["EVENT", {...kind:1, tags:[...,imeta...]}]
          │
          ▼
  kind1_note_handler.dart
     - parses the event into NoteModel
     - imeta_parser.dart walks imeta tags
          │
          ▼
  ImetaParser.parseAsAttachments → List<MediaAttachment>
     attached directly to NoteModel.attachments
     no MediaCacheModel row yet — bytes not pulled
          │
          ▼
  NoteCard renders
     - MediaAttachmentView sees attachment with no cache row
     - shows flutter_blurhash placeholder + "Download" button
     - Gallery does NOT show it (lists only files on disk)

  C. DOWNLOAD (user taps the download button)

  User taps Download
          │
          ▼
  DownloadMediaUseCase
          │
          ▼
  MediaRepositoryImpl.downloadBySha(sha, url, mime)
     1. caller passes url + mime from the note's imeta attachment
     2. BlossomClient.download(url)
          ├── signs Kind 24242 auth ["t","get"]  ◄── 3rd use of Blossom kind
          └── GET <url>
     3. MediaCacheDataSource.write → file on disk
     4. isar.writeTxn → upsert MediaCacheModel(sha, localPath, downloadedAt)
          │
          ▼
  NoteCard auto-rebuilds → shows real Image.file(...)
  Gallery now shows it (cache row exists)

  D. CROSS-DEVICE Kind 10063 sync

  Device A first upload → publishes Kind 10063 {["server", "..."]}
          │
          ▼ relay broadcasts
  Device B Gateway subscription picks it up
          │
          ▼
  kind10063_user_server_list_handler.dart
          │
          ▼
  UserServerListRepository.reconcileFromEvent()
     - LWW check on createdAt
     - writes server URLs to local UserServerListModel
          │
          ▼
  Device B can now upload to / download from the same servers

  ---
  Summary of the two special kinds

  Kind: 24242 (Blossom auth)
  Where signed: Inside BlossomClient per HTTP call
  Where used: Sent in Authorization: Nostr ... header for upload / get / delete
  /
    list
  Why: Proves to the Blossom server that you own this pubkey before it accepts
    the byte op. Expires in 5 min so a leaked header can't be reused.
  ────────────────────────────────────────
  Kind: 10063 (User server list)
  Where signed: UserServerListRepositoryImpl._publishServerList
  Where used: Published once on first upload + when server list changes;
  consumed
    by Kind10063UserServerListHandler on remote devices
  Why: So clients downloading your media know which Blossom server to hit.
    Without it, the imeta url is still there, but having the Kind 10063 makes a
    client robust to URL-mangling (it can fall back to <knownServer>/<sha256>).

