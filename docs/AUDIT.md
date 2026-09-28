# Engineering Audit Log

This is the **technical** companion to `CHANGELOG.md`. `CHANGELOG.md` stays terse and user-facing, following Keep a Changelog conventions — this file is where the actual engineering detail behind each release lives: what was found, what was verified against the real code (not guessed), what broke and why, and what's still open. Each entry maps to one or more `CHANGELOG.md` versions but goes deep where the changelog stays shallow.

Format: one dated section per audit pass, newest first. Each item states what was done, how it was verified, and — where relevant — what's still outstanding.

---

## 2026-09-28 — document RAG: PDF (#226, PR #229) and DOCX (#238) — work in progress toward v2.4.0 (unreleased)

Shiv now answers from PDFs and Word files attached to notes and cites where the answer came from — the **page** of a PDF, the **heading** of a DOCX section. Design and behaviour: `docs/SHIVA/rag.md` → "Documents (PDF, DOCX)"; specs in `docs/superpowers/specs/2026-09-19-pdf-rag-design.md` and `2026-09-26-docx-rag-design.md`.

### Dependency decisions

- **PDF via `pdfrx` (MIT, PDFium).** `syncfusion_flutter_pdf` was first proposed and rejected: it is proprietary, not permissively licensed as initially assumed. PDFium is a native asset that `flutter test` does not build, so `test/_helpers/pdfium_test_lib.dart` downloads the prebuilt the way `ensureIsarCore()` already does for Isar.
- **DOCX via `archive` + `xml`**, both already in the lockfile (promoted to direct dependencies) — no new package. The PDF spec had deferred DOCX as lacking "a strong pure-Dart reader"; for text extraction a `.docx` is a zip around `word/document.xml` and needs none.
- **`tostore` pinned to 3.1.2** — see the heap bug below. 3.1.1 and 3.1.3 are retracted; 3.5.x changes both the API (`precision`/`maxDegree` gone) and the on-disk format.

### ToStore 3.1.0 overflows the heap — found, root-caused, fixed

- Symptom: the document integration tests aborted in `malloc()`/`free()` 2 runs in 3, with a different glibc message each time (`unaligned tcache chunk`, `invalid pointer`, `invalid next size (fast)`) — real heap corruption.
- Bisected, not guessed: it survived removing PDFium, then removing the DOCX reader and its isolate, and finally reproduced in a test process containing **only ToStore**. The committed PDF-only flow test from #229 also crashed (1 run in 5), so it predates this work.
- Root cause: `SystemFfiHelper` declares `struct statvfs` as 11 × 8 = **88 bytes**; glibc — and 64-bit bionic, which shares the code path via `_isPosix => _isLinux || _isAndroid` — is **112**, ending in `__f_spare[6]`. Every periodic disk-space check `calloc`s 88 bytes and lets `statvfs()` write 112. Android is therefore on the same path in the shipped app.
- Fixed upstream in 3.1.2 (`fSpare0..5` added). Verified before pinning: 3.1.2 reads a store written by 3.1.0 unchanged (25/25 rows, every vector its own top hit); per-upsert-and-flush cost is the same (~70 ms on both — an earlier "twice as slow" reading was run-to-run noise); the full suite runs with zero native crashes.

### ToStore's vector index cannot reach every stored vector — measured, not fixed

- Querying each stored vector with itself, it is its own top hit for **100 % of 10, 80 % of 25 and 33 % of 60** — and only **55 % of 60 even with topK = every row**, so nodes are unreachable from the graph's entry point, not merely ranked low. Identical on 3.1.0 and 3.1.2. Our index config (`maxDegree: 32`, `efSearch: 64`) is not the cause: a search width above the row count should find nearly everything.
- This bounds retrieval for **notes and documents alike** as a library grows. It first surfaced as three DOCX flow tests returning no hit — initially misattributed to the one-hot test embedder, which was then shown to be only part of it. The DOCX search tests now index only the DOCX, so they test DOCX wiring rather than this limit.

### ToStore cannot delete a vector without destroying the index

- Measured on 3.1.0: deleting 1 of 3 rows makes `vectorSearch` return nothing, with no recovery across a close/reopen. The document store therefore never deletes vectors — Isar owns chunk existence, search skips hits that no longer resolve and over-fetches to absorb the orphans. A rebuild path is not implemented (#233).

### DOCX reader — rules the real files forced

Tested against two public-domain Microsoft Word templates (NIST CUI SSP, USPTO initial filing) and a LibreOffice export; provenance in `test/_helpers/fixtures/docx/PROVENANCE.md`.

- **Content controls.** The USPTO template wraps every section header in a block-level `w:sdt`; the planned reader walked only direct `w:body` children and would have silently dropped that text. It now descends into `w:sdt`/`w:sdtContent`/`w:customXml`.
- **Field codes.** The NIST template holds 330 `w:instrText` (`FORMCHECKBOX`); none reach the extracted text.
- **Heading detection by style name, not id.** LibreOffice writes `Heading 1` where Word writes `heading 1`, and German Word's id is `berschrift1`. Headings are matched case-insensitively by name or outline level, following `basedOn`.
- **Real forms often have no heading styles at all** — both federal templates mark sections with table rows or custom styles. Their chunks are cited with the file name and passage and no location line, by design.

### Code review of the DOCX diff — findings verified, then fixed

- **Out-of-memory crash loop.** The parsed XML DOM costs **~10×** the XML (measured: 20 MB → 205 MB RSS) in the app's own heap — `Isolate.run` shares the isolate group. The 50 MB cap allowed ~500 MB; an OOM before the index row is written would re-extract the same file on every launch. Capped `document.xml` at 10 MB and `styles.xml` (previously uncapped) at 2 MB.
- **Kind drift.** The document kind was re-derived from `MediaCacheModel.mime` at search time, but `_upsertCache` overwrites that mime on every download or upload of the same blob — a later sender's `application/pdf` would render a heading as "Page Annual Leave". Kind is now recorded on `DocumentIndexModel.kind` at index time and read through its unique index.
- **Received `.docx` files were not openable** (pre-existing). `downloadBySha` resolves the cache file's extension from the mime alone — downloads carry no filename — and the DOCX mime was missing from `_mimeToExt`, so other people's Word files cached as a bare `<sha256>`.
- **The prose gate was PDF-shaped.** `looksLikeProse` (≥200 chars, ≥15 % letters) catches scans and broken font encodings; a DOCX has neither failure mode, so a short memo or a table of figures was permanently `notSearchable`. The gate now applies to PDFs only.
- Also fixed: tracked moves (`w:moveFrom` is ordinary `w:t`) and text boxes inside table cells were indexed twice; a 100-char heading cap could split an emoji's surrogate pair.
- **Indexing scope was wrong, found in review with the product owner.** The indexer indexed every cached PDF/DOCX — so a DM or feed attachment the user merely *opened* became citable in Shiv, while a *saved* note's document the user never opened was never indexed (saving does not download attachments; files download only on tap). Now: only documents on the user's own feed notes (kind 1) and on saved notes are indexed, matching what Shiv's note search already covers; saving downloads the note's PDF/DOCX; unsaving purges them on the next pass. The indexer now also watches saved notes and notes, because an own note's row is written after its attachment was cached.
- **Not fixed, deliberately:** `DocumentIndexer`, a feature-folder class from #229, reads and writes Isar directly, which this repo's layer rules forbid for presentation code. Restructuring it behind a repository is a design change to the PDF PR, not a DOCX fix.

### Mistakes corrected along the way

- The 768-vs-1024 embedding dimension (#234) was first blamed for empty note retrieval. Tested on host: ToStore tolerates the mismatch. The real cause was notes never being re-embedded (#231).
- The device test's gate asserted `hasLength(1024)` against a model that emits 768, so it failed on every device before reaching its retrieval assertions. It now asserts the model loaded (`isNotEmpty`).
- The manual test kit said to wait "~10 seconds" after attaching a document. On device a 17-chunk DOCX took **~4 minutes** while Gemma 4 E2B held the phone; both questions asked in that window saw notes only and looked like a retrieval failure. Established from the device's own Isar (pulled with `run-as`) against the log timeline. `DocumentIndexer` now logs start, finish (chunk count, seconds) and not-searchable reasons for every document.

### Verification

- `flutter analyze lib/ test/ integration_test/`: no errors, no warnings. Full suite **3,342 tests** green with zero native crashes; the indexer (21) and document flow (19) suites re-run green after the logging change, and again after the scope change (indexer 31, flow 20, saved-note use cases 19).
- 12 deliberate sabotages — deleted text leaking, moved text doubled, content controls skipped, headings by id, no heading folding, emoji split, table text boxes doubled, a DOCX rendered as a page in the prompt, the tile ignoring kind, kind from mime, the prose gate on DOCX, the indexer dropping DOCX — each turned its tests red.
- On device (vivo 1933): the PDF answered with correct figures and correct page tiles; the DOCX indexed 17 chunks with the expected section labels (read from the device DB), and answers with section tiles were confirmed by manual testing.

### Still open

- **Not filed yet:** ToStore's recall limit above.
- No UI indication that a document is still indexing — only the log.
- `integration_test/document_rag_e2e_test.dart` (real Gecko, PDF + DOCX) was written but not run on a device this pass.
- iOS is unverified for both PDFium (`pdfrx` is FFI) and the DOCX isolate.
- `test/gateway/outbound/outbound_pump_test.dart` flaked again under full-suite load (a read racing an async Isar write); passes 3/3 alone. Untouched by this work.
- Follow-ups tracked under epic **#228**: #231 (notes never re-embedded), #232 (version-stamped store path), #233 (orphan rebuild), #234 (declared dimension), #235 (documents in the knowledge graph), #236 (documents in Manas-scoped chat), #237 (jump to the cited page), #238 (formats beyond PDF — DOCX now done; `.doc`, `.odt`, text and CSV remain).

---

## 2026-09-16 — work in progress toward v2.4.0 (unreleased)

### flutter_gemma 1.5.2 → 1.8.3 (issues #198, #202)

- Bumped with its engine packages: `flutter_gemma_litertlm` 1.3.1 → 1.6.3, `flutter_gemma_mediapipe` 1.0.4 → 1.0.6, `flutter_gemma_embeddings` 1.0.4 → 2.1.1, pulling `dart_sentencepiece_tokenizer` 1.3.1 → 1.4.1. `background_downloader` stays pinned at 9.5.6 — 1.8.3 requires `^9.5.6`, and 9.6.x needs Flutter ≥ 3.47 while CI runs 3.44.2.
- One breaking change, handled: embeddings 2.0.0 moved `LiteRtEmbeddingBackend` into `flutter_gemma_litertlm` with no re-export shim. Every importer already imported litertlm, so the class resolved unchanged and five now-dead `flutter_gemma_embeddings` imports were removed. No inference/session/chat API changed.
- #202 needed no code to receive: flutter_gemma no longer claims `FileDownloader().updates` (upstream PR 450), and the app never listened to that stream.

### Android GPU re-enabled — and the crash that had gated it

- The OpenCL per-turn native-heap leak (flutter_gemma #348 / #402) is fixed in `flutter_gemma_litertlm` 1.4.1 (LiteRT-LM v0.16.0). The other known Android GPU native-crash classes (#209 JNI path removed in 0.14.0, #379 cancel-vs-teardown use-after-free fixed in litertlm 1.0.4) are fixed in versions older than the ones we now ship. `lib/core/utils/llm_backend.dart` therefore prefers GPU on every platform.
- Verified on device, not assumed. Merged manifest carries `libvndksupport.so`, `libcdsprpc.so` and all three `libOpenCL*.so`; the engine reports `backend=gpu` and delegates the whole graph (`Replacing 1306 out of 1306 node(s) with delegate (LITERT_CL)`).
- Measured, Qwen3 0.6B, same device: prompt prefill **19.9 s (CPU) → ~7.9 s (GPU)** across six samples — roughly 2.5×. Decode barely moved (~2.3 → ~2.8 chunks/s) because the plugin deliberately halves the GPU kernel batch on Android (`hint_kernel_batch_size=2`, upstream #364, to keep the UI smooth). First engine create went the other way: **1.5 s → 11.5 s**, OpenCL kernel compilation; the plugin already passes a `cacheDir`, so whether a later launch reuses it is unconfirmed.
- **Known, unfixed, shipped deliberately:** on a vivo 1933 / Android 11 / Adreno device, `litert_lm_engine_create` with `backend=gpu` intermittently kills the process inside the phone's GPU driver — `SIGSEGV`, `fault addr 0x0`, thread `AdrenoOsLib`, `/vendor/lib64/libgsl.so (os_thread_launcher+48)` with `pc=0`. This is the previously uncharacterised SIGSEGV that kept Android on CPU; it now has a stack trace. It is **uncatchable** — the process dies before any Dart `catch` runs, so the call-site GPU→CPU retry cannot help — and it is intermittent: the same build completed two full generations before crashing on a later run. No matching upstream issue exists. Shipping GPU on anyway was an explicit product decision; the mitigation discussed and not built is a persisted "GPU attempt in progress" marker that pins a device to CPU after a crash.

### CPU fallback was half-broken (found while enabling GPU)

- `AIModelRunner._openActiveModel` retried with no `preferredBackend` at all. In litertlm 1.6.3 `ffiBackendFallbackOrder(null)` is `[gpu, cpu]` — the same ladder as `.gpu` — so the "CPU retry" re-attempted the GPU engine create that had just failed, and `_backend` was never set to CPU, so every later open paid for it again. Now retries with an explicit `PreferredBackend.cpu` and remembers it.
- Checked the other two fallbacks rather than assuming: MediaPipe (DeepSeek R1 `.task`) has **no** internal ladder — `setPreferredBackend` is only called when non-null, so ours is the only fallback there; `LiteRtEmbeddingBackend` has none either, so `EmbeddingService`'s own retry is the only one. Both already passed `.cpu` explicitly and were left alone.

### Foreground model downloads (Android)

- `fromNetwork(..., foreground: true)`, gated to Android via `Platform.isAndroid` — iOS gains only a notification-permission prompt, since the foreground service is an Android concept and background URLSession already keeps iOS downloads alive. Upstream keys the same decision off `Platform.isAndroid` rather than `defaultTargetPlatform`.
- Needed one manifest entry: neither flutter_gemma nor background_downloader declares WorkManager's `SystemForegroundService`, and Android 14+ requires a `dataSync` type on it. Verified in the merged manifest after a rebuild (`foregroundServiceType = dataSync`).

### Shiv echoed its own answer cue (issue #220)

- Symptom: replies like `Shiv: I am Shiv, the on-device AI assistant of UNIUN.` and, once, `Shiv: /no_think`.
- Root cause proven, not inferred. The chat path never adds `/no_think` — `PromptParts.noThink` is used only by the Nataraj, translation and Gana one-shot builders — so a chat reply containing that literal string could only come from flutter_gemma's Qwen3 append, which fires solely when `isUser == true` (`!isThinking && modelType == qwen3 && message.isUser`). Passing `isUser: true` had been added during this bump on the incorrect assumption that it was inert; it appended ` /no_think` **after** `PromptBuilder._answerCue()`'s trailing `Shiv:`, and the model copied the pattern.
- Second, older defect exposed by the first: the `Shiv:` cue (added 2026-06-22, `ac468d11`) could always be echoed, and nothing stripped it — `LlmTextSanitizer.clean` handled `<think>` blocks, tool envelopes and mojibake, but not a role label.
- Fixed model-agnostically: stop passing `isUser` at all three call sites (streaming chat, one-shot, background Gana), strip a leading echoed label in `LlmTextSanitizer.clean` so any model's echo is caught on both the streaming and final paths, and share one `AppConstants.kShivLabel` between the prompt builder and the sanitizer so they cannot drift. Deliberately conservative: leading occurrence only, first match only, and a word such as "Shivam" is untouched.
- `/no_think` was **not** added to the chat prompt to compensate. `PromptParts`' own header records that chat intentionally uses the model's native `isThinking` flag instead, and DeepSeek R1 ships `isThinking: true` — a shared always-on directive would fight it.

### Verification

- `flutter analyze lib/ test/ integration_test/` clean; full suite 3,073 tests.
- Every fix checked against its own revert: dropping the label strip fails five sanitizer tests; restoring `isUser: true` fails the one-shot test and, separately, the streaming test. The first revert check was wrong — it reverted the streaming call while the test exercised the one-shot path, which is how the missing streaming coverage was noticed.
- Android debug APK built twice (once to confirm Gradle and the manifest merge, once after the download change).

### Still open

- **Untracked by decision:** the Adreno GPU crash above.
- Issues filed for follow-ups this pass surfaced: **#217** (move DeepSeek R1 to LiteRT-LM and drop MediaPipe — Google calls the MediaPipe route "maintenance mode" and a `.litertlm` build now exists), **#218** (speculative decoding for Gemma 4; the flag is never passed today, so the model file's own default applies), **#219** (the `-gpu.litertlm` bundles exist but are undocumented and may be GPU-only, which would break the CPU fallback).
- `maxOutputTokens` is still unused anywhere, so no one-shot caps generated length; a runaway repetition runs until the KV cache fills.
- `InferenceScheduler`'s T2 soft budget can stall an extract-only queue: after one `extract` job the ratio is 100 %, the picker skips tier 2, and nothing re-pumps until another job arrives or the 5-minute window trims. Latent, predates this pass.
- `test/mesh/nip77_reconciler_test.dart` still uses the 5 s reconcile timeout that flaked in CI for `sync_integration_test.dart`. `test/gateway/outbound/outbound_pump_test.dart` flaked once under full-suite load and passes 3/3 alone.
- iOS is unverified — it cannot be built from the Linux dev machine. The bump changes iOS meaningfully: `.litertlm` there is now `raw` rather than hand-formatted, because LiteRT-LM applies the chat template itself.

---

## 2026-08-22 — work in progress toward v2.4.0 (unreleased)

### Bugs found and fixed

**The Brahma graph never refreshed after replying to a note from the node panel, issue #197**
- Root cause, confirmed by reading the widget and the BLoC rather than inferring from the report: `GraphNodePanel`'s `NoteCard.onTap` (`lib/features/brahma/graph/widgets/graph_node_panel.dart`) pushed the thread route fire-and-forget — no `await`, no reload on return. `GraphBloc` cannot self-correct either: it subscribes to exactly one collection, `deletedNoteModels` (`graph_bloc.dart:57`), so note *deletions* rebuild the graph but note *creations* never do. Replying therefore left the graph drawing its pre-navigation state: the new reply missing as a node, and the replied-to note still showing its stale `cachedReplyCount`.
- The same file already had the correct pattern for the adjacent case — the draft path (`graph_page.dart:260`) awaits its push and re-dispatches `LoadGraphEvent`. The note path simply never got it.
- Fix: `await` the push, then dispatch a **scope-preserving** `LoadGraphEvent(manasId:, manasName:)`, guarded by `bloc.isClosed` (the bloc can be closed while the thread page is up). The bloc reference is captured before the await rather than reaching through `context` afterwards.
- Deliberately **not** re-selecting the node afterwards: `_onSelect` toggles, so a `SelectGraphNodeEvent` for the already-selected node would have closed the open panel. `_onLoad` leaves `selectedNodeId` untouched, so the panel re-reads the refreshed node on its own.
- Verified the reply actually renders **with its graph edge**, end to end: `PostReplyUseCase:139` always emits `['e', parent, '', 'reply']` — even when the parent is the thread root (deliberate, per #76) — so `replyToEventId` is always populated; `replyEdgeParentIds` therefore puts the parent in the node's `refEdges`, and `buildAdjacency` draws the edge because both ends are in the node set (the parent was already a node — it is what the user tapped). `getOwnNotes` applies no top-level filter, so the reply itself loads as an own node.
- Known, correct-but-surprising interaction: while the graph is **scoped to a Manas**, a fresh reply will not appear — a new note belongs to no Manas, and scoping filters to membership (`graph_bloc.dart:169-180`). Not a defect; worth knowing before manually testing the fix.

### Test coverage added

- `test/features/brahma/graph/graph_node_panel_test.dart` (new, 7 widget tests) — mock `GraphBloc` + mock `NoteCardCubit` via `getIt`, real `GoRouter` with a stub thread route so the pop is a genuine navigation pop. Pins: thread navigation happens; no reload fires while the thread is still open; exactly one reload fires on return; the reload carries the active Manas scope; an unscoped graph stays unscoped; a bloc closed mid-navigation is never dispatched to; no `SelectGraphNodeEvent` is emitted.
- Confirmed non-vacuous: reverting the fix fails exactly the 3 reload-asserting tests and leaves the 4 guards green.
- `test/features/brahma/graph/graph_bloc_test.dart` gained 3 cases for gaps this audit surfaced — a bare `LoadGraphEvent()` **clears** an existing Manas scope (the untested mechanism behind #204); DMs (kinds 14/15) are never surfaced as graph nodes; an active search re-matches against the freshly-loaded node set.
- Full sweep green: 267 tests across `test/features/brahma/`, `test/common/widgets/note_card/`, `test/data/repositories/graph_repository_impl_test.dart`.

### Still open — filed, not fixed

Auditing the graph for siblings of #197 turned up two more reload-wiring defects, both distinct failure modes rather than repeats:

- **#204 — a reload that drops Manas scope.** `LoadGraphEvent` defaults `manasId` to null, and `_onLoad` treats null as an *explicit unscope* (`clearScope: event.manasId == null`, `graph_bloc.dart:214`). Two call sites reload with a bare event and so silently kick the user out of a scoped view: `graph_page.dart:266` (returning from the draft editor) and `graph_fab.dart:25` (creating a note from the FAB). The bare `LoadGraphEvent()` at `brahma_drawer.dart:119` is **correct** — it intentionally unscopes after the active Manas is deleted — so this must not be fixed by a blanket replace.
- **#205 — a graph-relevant write the graph is never told about.** `ManasMembershipSheet._toggle` writes the membership link and refreshes only its own list; `GraphBloc` does not watch `ManasNoteLinkModel`, so adding/removing a note from the Manas the graph is currently scoped to leaves the node set stale. Not a one-liner: the sheet is shared with the Vishnu feed via `note_card_menu.dart:95`, where no `GraphBloc` exists in the tree, so the fix is a design call (preferred option: watch the link collection in `GraphBloc`, gated on `scopedManasId != null`).

---

## How to keep this file useful

- Add an entry here for anything with real technical weight behind it: a root-caused bug, a dependency decision with a rejected alternative, a verification gap that's real and worth knowing about, a discovery that contradicts existing docs.
- Don't duplicate `CHANGELOG.md` — if there's nothing more to say than what the changelog already says, it doesn't need an entry here.
- Be honest about what wasn't verified, not just what was — a gap flagged here is more useful than a claim that turns out to be wrong later.
