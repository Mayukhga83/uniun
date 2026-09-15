# Engineering Audit Log

This is the **technical** companion to `CHANGELOG.md`. `CHANGELOG.md` stays terse and user-facing, following Keep a Changelog conventions — this file is where the actual engineering detail behind each release lives: what was found, what was verified against the real code (not guessed), what broke and why, and what's still open. Each entry maps to one or more `CHANGELOG.md` versions but goes deep where the changelog stays shallow.

Format: one dated section per audit pass, newest first. Each item states what was done, how it was verified, and — where relevant — what's still outstanding.

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
