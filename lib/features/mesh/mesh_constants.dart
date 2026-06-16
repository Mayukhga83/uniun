/// Central home for the mesh feature's tuning knobs.
///
/// These were previously scattered as inline magic numbers and private statics
/// across the engine, router, transports, and surrounding exchange. Collecting
/// them here makes the system tunable from one place and keeps coupled values
/// (e.g. the send pacing and the receiver's rate limit) visible side by side.
///
/// Pure constants — no behavior lives here. The matching *native* caps (the 8 MB
/// reassembly guard in the Android `BleFragmenter` and the shared Swift
/// `UniunBleMesh`) cannot import Dart, so they are mirrored there by value; keep
/// [kMeshMaxMessageBytes] in sync with them if it ever changes.
library;

// ── Multi-hop gossip ────────────────────────────────────────────────────────

/// Initial hop budget for a gossiped public event (bitchat-style TTL). The origin
/// broadcast starts here; each relay forwards with `ttl - 1`; a receiver at ttl 0
/// stores it but does not forward further. Bounds multi-hop flooding.
const int kMeshMaxTtl = 7;

/// Bounded FIFO cap on the router's processed-event seen-set. An evicted-then-
/// reseen id is at worst re-stored (idempotent) and re-relayed with the same TTL
/// budget, which still terminates — so the cap trades a little redundant traffic
/// for bounded memory, never a loop.
const int kMeshRouterSeenCap = 8192;

// ── Wire limits ─────────────────────────────────────────────────────────────

/// Hard cap on a single framed app message (guards against a bogus/huge length on
/// the wire). Mirrored by the native BLE reassembly caps; keep them aligned.
const int kMeshMaxMessageBytes = 8 * 1024 * 1024; // 8 MB

// ── Handshake / sync timeouts ───────────────────────────────────────────────

/// How long the signed-nonce identity handshake may take before the peer is
/// dropped (used by both `IdentityProof` and `MeshPeerManager`).
const Duration kMeshHandshakeTimeout = Duration(seconds: 10);

/// How long one trusted-sync reconciliation round may run before it gives up and
/// logs the unreconciled scopes.
const Duration kTrustedSyncTimeout = Duration(seconds: 30);

// ── Surrounding feed (stranger broadcast) ───────────────────────────────────

/// Anti-abuse caps on how much we push to a single stranger per delta: at most
/// this many of our own newest notes and this many of our newest saved notes.
/// Keeps a fresh peer from being flooded with our whole DB on connect.
const int kMaxOwnBroadcastNotes = 10;
const int kMaxSavedBroadcastNotes = 10;

/// Receiver-side flood guard: max surrounding notes accepted from one peer per
/// rolling second. Paired with [kSurroundingSendInterval] — a well-behaved sender
/// paces below this so a genuine note is never dropped as a flood.
const int kSurroundingMaxNotesPerSecond = 2;

/// Minimum gap between paced outbound sends. Spacing sends >500 ms apart
/// guarantees at most [kSurroundingMaxNotesPerSecond] land in any one-second
/// window; 600 ms leaves margin for jitter.
const Duration kSurroundingSendInterval = Duration(milliseconds: 600);

/// Notes loaded per older-page pagination step in the Surrounding feed UI.
const int kSurroundingPageSize = 10;

// ── Surrounding cache eviction ──────────────────────────────────────────────

/// How often the engine sweeps the ephemeral surrounding cache (also runs once at
/// startup).
const Duration kSurroundingCleanupInterval = Duration(hours: 1);

/// How long a received surrounding note is retained before daily eviction.
const Duration kSurroundingRetention = Duration(days: 1);
