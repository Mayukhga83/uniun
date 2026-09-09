/// The kinds of LLM work the app submits to [InferenceScheduler].
///
/// See `docs/SHIVA/scheduling.md` for the full tier table. In short:
/// - [chat]    — user-typed prompts in Shiv chat / composer-chat. T0.
/// - [extract] — knowledge extraction (summary + entity/relation building).
///                T1 when the user just opened the note (`foregroundHint`),
///                otherwise T2.
/// - [nataraj] — Nataraj deck card generation. T1 while NatarajDeckPage is
///                foreground, otherwise T4 fair-pool with [gana].
/// - [gana]    — Gana autonomous agent runs. T1 while GanaFormPage preview
///                is open, T3 when a cron tick is past its deadline,
///                otherwise T4 fair-pool with [nataraj].
/// - [modelSwitch] — activating/deactivating the local model itself
///                (switching or deleting). Always tier -1, above chat.
///                Never re-queued (nothing preempts it).
///
/// Embedding is intentionally NOT a member — it runs on a separate model
/// and chip path via `EmbeddingQueue`, not via the LLM scheduler.
enum LlmTaskKind {
  chat,

  /// User tapped Translate on a note — foreground and blocking a visible
  /// card, so it outranks every background producer but yields to live chat.
  translate,
  extract,
  nataraj,
  gana,
  modelSwitch,
}
