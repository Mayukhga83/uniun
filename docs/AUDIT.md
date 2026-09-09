# Engineering Audit Log

This is the **technical** companion to `CHANGELOG.md`. `CHANGELOG.md` stays terse and user-facing, following Keep a Changelog conventions — this file is where the actual engineering detail behind each release lives: what was found, what was verified against the real code (not guessed), what broke and why, and what's still open. Each entry maps to one or more `CHANGELOG.md` versions but goes deep where the changelog stays shallow.

Format: one dated section per audit pass, newest first. Each item states what was done, how it was verified, and — where relevant — what's still outstanding.

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
