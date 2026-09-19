# PDF support in Shiv's RAG pipeline

## Problem

Shiv's RAG pipeline embeds and retrieves whole Notes — one Gecko vector per
note, cosine top-K over that. A PDF can already be *attached* to a note
today (Blossom upload, `imeta` tag, file-type-styled tile, opens via
`open_filex`), but its content is invisible to Shiv: the text inside it is
never extracted, never embedded, never retrievable, never cited. A note that
says "see the attached document" carries no more RAG signal than a note
with no attachment at all.

This spec adds PDF text extraction, chunking, and embedding, and wires the
result into retrieval and the existing Sources UI, so a PDF's *content*
becomes something Shiv can actually answer from and point back to.

## Scope

**v1 is PDF only.** DOCX has no strong pure-Dart reader — supporting it
would mean hand-parsing a zip of XML, real extra surface area for a format
that is out of scope for now. Revisit only if a real need for DOCX shows up.

**No OCR in v1.** A PDF with no text layer (a scan or a photograph) is not
sent through OCR. It stays attached and openable exactly as it is today,
but is marked not searchable and never embedded. Silently guessing at a
scanned document's content is worse than admitting it isn't searchable —
the same principle a comparable document-RAG system elsewhere applies: OCR
is a different problem, and pretending otherwise would put an empty
document in the index and call it read. On-device OCR (e.g.
`google_mlkit_text_recognition`) is a real option for later, deliberately
deferred, not ruled out.

**No in-app page-jump PDF viewer in v1.** A chunk citation names the page
it came from, but tapping it opens the PDF the same way any attachment
opens today — the OS's own viewer via `open_filex`, which has no way to be
told to jump to a page. The citation still shows the page number so a
reader knows where to look and can verify the claim; it just doesn't
auto-scroll there. See "Future work" below.

## Architecture

```
Attach (existing, unchanged)
  PDF -> Blossom upload -> imeta tag on the note -> MediaCacheModel row (sha256 -> local path)

New: extraction pipeline (triggered right after the blob lands on-device,
same moment MediaCacheModel already records the file exists locally --
same timing as the image-caching path, so a query never waits on it)
  MediaCacheModel row created for a PDF mime
       |
       v
  PdfExtractionService: syncfusion_flutter_pdf's PdfTextExtractor, page by page
       |
       v
  alpha-ratio quality gate (>= 15% alphabetic characters = real prose;
  below that = mojibake / an empty scan -- same measured threshold a
  comparable system in this workspace uses)
    fails -> doc stays attached, marked "not searchable", stop here
    passes v
       |
       v
  chunk on page boundaries, each chunk keeps its page number as `label`
       |
       v
  embed each chunk (same Gecko/EmbeddingService embedder Notes already use)
       |
       v
  DocumentChunkModel rows (new Isar collection): sha256, ordinal, label, text, embedding

Query time
  embed query -> VectorSearchService searches (note vectors union chunk vectors)
              -> 1-hop graph expand (unchanged, notes only -- chunks are not graph nodes)
              -> EnrichedContext carries both note citations and chunk citations
              -> PromptBuilder -> answer

  ShivSourcesSheet: one sheet, mixed list
    note citation  -> existing EmbeddedNoteCard, unchanged
    chunk citation -> new tile: doc title . page label . snippet . tap -> open_filex (page 1, as today)
```

## Components

- **`PdfExtractionService`** (new, `lib/features/shiv/rag/extraction/`) —
  wraps `syncfusion_flutter_pdf`. Pure function of PDF bytes in, either a
  `List<Chunk>` or nothing (gate failure) out. No Isar dependency, so it is
  testable in isolation against real PDF fixtures.
- **`Chunk`** (new, same file or a small shared one) — `text`, `ordinal`,
  `label` (the page number). A citation to "page 2" cannot be verified if
  the page number was discarded during chunking, so it has to survive as a
  first-class field, not be re-derived after the fact.
- **`DocumentChunkModel`** (new Isar `@Collection`, parallel to
  `MemoryNodeModel` — RAG infrastructure, not a Note, so it does not touch
  the one-Note-collection rule) — `sha256`, `ordinal`, `label`, `text`,
  `embedding`. Joined to `MediaCacheModel` by `sha256`, same join pattern
  `MediaCacheModel` already uses today.
- **Extraction trigger** — hooked at the same inbound point
  `MediaCacheModel` rows are written today, when a PDF-mime blob finishes
  downloading. Runs off the chat path entirely.
- **`VectorSearchService`** — extended to also search chunk vectors
  alongside note vectors, returning a merged, kind-tagged result list so
  downstream code can tell a note hit from a chunk hit.
- **`EnrichedContext` / `PromptBuilder`** — carry chunk citations
  (`docId`, page `label`, snippet) alongside the existing note citations.
- **`ShivSourcesSheet`** — grows a second tile type for chunk citations.
  Note rendering (`EmbeddedNoteCard`) is unchanged. One sheet, one list, so
  "what did this answer rest on" always has one place to check regardless
  of what kind of source it was.

## Error handling

- No text layer, or the alpha-ratio gate rejects the extracted text: the
  document is still attached and still opens exactly as it does today. It
  is simply never embedded or cited. This never surfaces as an error to the
  user — it is a normal, expected outcome for a scanned document, not a
  failure.
- Extraction runs eagerly but off the chat path, so a slow or failing
  extraction never blocks or delays a Shiv answer. Worst case, that one
  document is not yet retrievable.

## Testing

- `PdfExtractionService`: real PDF fixtures — one clean text-layer PDF, one
  scanned/no-text-layer PDF, one with deliberately garbled encoding —
  asserting accept/reject against the alpha-ratio gate.
- Chunking: page boundaries are preserved and each chunk's `label` matches
  its source page number.
- `VectorSearchService`: a merged note+chunk result set is correctly
  kind-tagged, and top-K/minScore behave the same as they do for notes today.
- `ShivSourcesSheet`: a mixed list renders both tile kinds correctly; a
  chunk tile opens the right file (via its `sha256`/local path) through the
  existing `open_filex` path.

## Future work (explicitly out of scope for this spec)

- **In-app PDF viewer that jumps to the cited page** — e.g. via
  `syncfusion_flutter_pdfviewer`. The page label is already user-visible in
  v1, so the value is already there; this would remove the one remaining
  manual step (finding the page yourself once the OS viewer opens).
- **On-device OCR for scanned PDFs** (e.g. `google_mlkit_text_recognition`)
  — would need its own quality gate, since OCR misreads look different from
  the mojibake the alpha-ratio gate today is calibrated against.
- **DOCX support** — deferred until there's a real need for it.
