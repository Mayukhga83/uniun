# DOCX support in Shiv's RAG — design

Builds on the PDF pipeline (`2026-09-19-pdf-rag-design.md`, branch `feat/pdf-rag`).
Tracks #238.

## Problem

A `.docx` attached to a note already uploads, caches (`MediaCacheModel.mime =
application/vnd.openxmlformats-officedocument.wordprocessingml.document`) and
opens externally — and is invisible to Shiv, exactly as PDFs were before #226.

The PDF spec deferred DOCX because "DOCX has no strong pure-Dart reader". For
*text extraction* that is too pessimistic: a `.docx` is a zip whose body is
`word/document.xml`, and `archive` + `xml` (both already in the lockfile,
MIT/BSD) read it without a new package.

## Decision: a DOCX citation points to a heading, not a page

A Word file has no fixed pages — pagination depends on fonts, paper size and the
rendering app. A PDF citation works because "Page 5" is true everywhere; a DOCX
page number would not be. So a DOCX chunk is labelled with the **nearest heading
above it** ("Section: Annual Leave"), and with nothing when the document has no
headings. A wrong page number is worse than none.

Rejected: Word's `lastRenderedPageBreak` hints (absent from Google Docs /
LibreOffice / generated files, and drift from other viewers); page-or-heading
hybrid (two label kinds, harder rules); no location at all.

## Design

### 1. Reading — `lib/data/datasources/docx/docx_text_source.dart`

Sibling of `pdf/pdf_text_source.dart`. `DocxTextSource.sectionsText(path)` →
`List<DocxSection>?`, where `DocxSection = ({String label, String text})`;
`null` means unreadable. Implementation `ArchiveDocxTextSource`:

- Unzip, read `word/document.xml` and (optionally) `word/styles.xml`.
- Walk `w:body` children in document order: `w:p` paragraphs and `w:tbl`
  tables, descending into block-level content controls (`w:sdt` /
  `w:sdtContent`) and `w:customXml`. Found by the USPTO fixture: Word templates
  wrap whole paragraphs — there, every section header — in content controls, so
  visiting only direct `w:body` children silently drops real text.
- Paragraph text: `w:t` runs; `w:tab` → tab; `w:br` / `w:cr` → newline.
  **Skipped:** `w:delText` (tracked-change deletions Word keeps in the file),
  `w:moveFrom` (the old copy of moved text, still ordinary `w:t`) and
  `w:instrText` (field codes such as `PAGE \* MERGEFORMAT`).
- Tables: each row's cell texts joined by ` | `, one row per line.
- A paragraph is a **heading** when its style resolves — via `styles.xml`, by
  style **name**, never id — to `heading 1..9` or `Title`, or when its own
  `w:pPr` or its style carries `w:outlineLvl` 0–8. Style ids are localised
  (German Word: `berschrift1`) and free-form in other editors; built-in names
  are stable.
- Each heading starts a new section, labelled with the heading's text
  (whitespace-collapsed, capped at 100 chars). The heading text also stays in the
  section's body so the embedding sees it. Content before the first heading is
  a section with label `''`. A heading with no body of its own folds into the
  next section (label = the later heading, text keeps both), so `Chapter 3`
  directly above `3.1 Scope` yields no title-only chunk.
- Not read in v1: headers, footers, footnotes, endnotes, comments, text boxes,
  embedded images.
- **Runs in `Isolate.run`** — XML parsing is synchronous Dart and would jank the
  UI for a large document (PDFium, by contrast, is async FFI).
- Refuses an uncompressed `document.xml` over 10 MB (returns `null`), and
  ignores a `styles.xml` over 2 MB. Files arrive from other users over relays,
  so a zip bomb is a real input, and the parsed DOM costs ~10x the XML
  (measured) in the app's own heap — `Isolate.run` shares the isolate group.
- Never throws; any failure → `null`.
- The only file in `lib/` importing `package:archive` or `package:xml`.
  Both move to direct `dependencies` (`archive: ^4.0.0`, `xml: ^6.6.1`).

### 2. `DocumentKind` — `lib/core/enum/document_kind.dart`

```dart
enum DocumentKind { pdf(mime), docx(mime) }
static DocumentKind? DocumentKind.fromMime(String mime)  // case-insensitive prefix
```

The single answer to "which mimes are documents". Read by the indexer's filter,
the citation resolver, the vector repository and the prompt. `.doc`, `.odt` and
everything else → `null` → never indexed, exactly like images.

### 3. Pipeline

- `chunk.dart` gains `chunkSections(List<DocxSection>-shaped records)`;
  `chunkPages` becomes a thin wrapper labelling page `i` as `'${i + 1}'`. One
  chunking algorithm; PDF output unchanged. `Chunk.label` doc: page for PDF,
  heading for DOCX, `''` when none.
- `PdfExtractionService` → **`DocumentExtractionService`**,
  `extract(path, DocumentKind kind)`; dispatches to `PdfTextSource` or
  `DocxTextSource`. Same never-throws contract. The prose gate (≥200 chars,
  ≥15% letters) applies to **PDF only** — it catches scans and broken font
  encodings, which a DOCX cannot have; a DOCX is refused only when empty. For DOCX, `pageCount` is 0 (the field has no readers).
- `PdfIndexer` → **`DocumentIndexer`**; the mime filter admits every
  `DocumentKind`. Files and tests renamed with `git mv`.
- `ScoredChunk` and `DocumentCitation` gain a **required** `kind`, recorded on
  `DocumentIndexModel.kind` when the document is indexed and read back through
  its unique index. Not derived from `MediaCacheModel.mime` at search time:
  every download or upload of the same blob overwrites that mime. The field
  defaults to `pdf` — correct for every row written before DOCX support.
- `PromptBuilder` (LLM-facing — stays English, not localised):
  PDF `• (p.5) …`, DOCX `• (Annual Leave) …`, empty label `• …`.

### 4. UI — `DocumentSourceTile`

| | PDF | DOCX |
|---|---|---|
| Icon | `picture_as_pdf_outlined` | `description_outlined` |
| Location line | "Page {label}" | "Section: {label}", hidden when `label` is empty |
| Fallback title | "PDF document" | "Word document" |
| Tooltip | "Open PDF" | "Open document" |

New keys in `app_en.arb` + `app_hi.arb`: `shivSourcesDocumentSection`,
`shivSourcesDocxUntitled`, `shivSourcesDocxOpen`.

## Error handling

| Input | Result |
|---|---|
| Not a zip, encrypted (OLE container), missing `document.xml`, malformed XML, `document.xml` > 10 MB | `NotSearchable(unreadable)` |
| Valid but no text at all | `NotSearchable(noTextLayer)` |
| Embedder not ready | no index row; retried (unchanged) |
| Missing, malformed or > 2 MB `styles.xml` | still indexed; only `outlineLvl` headings detected |

## Testing

- **Real fixtures** under `test/_helpers/fixtures/docx/` with `PROVENANCE.md`:
  two public-domain Microsoft Word templates (NIST CUI SSP — 116 tables, 330
  field codes, no heading styles; USPTO initial filing — content controls) and
  one LibreOffice export with real `Heading 1` sections. Public-domain Word
  files that *do* use heading styles could not be fetched (ed.gov serves a bot
  check), hence the LibreOffice file for the heading path.
- **Exact edge fixtures** built in-test by `minimalDocx()`
  (`test/_helpers/docx_fixtures.dart`): tracked changes, field codes, tables,
  localised style id, `outlineLvl`-only heading, no headings, no `styles.xml`,
  Devanagari, emoji, non-zip, missing `document.xml`, malformed XML, size cap.
- **Unit**: reader; `chunkSections` + `chunkPages` regression; `DocumentKind`;
  extraction dispatch; indexer (DOCX indexed, `.doc` ignored, mixed PDF+DOCX);
  resolver/vector `kind`; prompt prefixes; tile.
- **Integration** — added to `test/integration/document_rag_flow_test.dart`
  (renamed from `pdf_rag_flow_test.dart`, so the embedder stub and mocks are
  shared, not copied): real DOCX →
  real archive/xml → chunker → Isar → ToStore → retrieval → citation with a
  section label. Pure Dart, so it runs fully in CI.
- **Device** — a DOCX case in `integration_test/document_rag_e2e_test.dart`
  (renamed from `pdf_rag_e2e_test.dart`) with the real Gecko embedder.
- **Manual kit** — a `.docx` edition of the leave-policy test document.

## Out of scope

`.doc`, `.odt`, headers/footers/footnotes, text in images, page numbers for DOCX,
knowledge-graph extraction (#235), Manas-scoped documents (#236).

## Found while building

- **ToStore 3.1.0 overflows the heap.** Its `struct statvfs` is 88 bytes; glibc
  and 64-bit bionic use 112, so each disk-space check wrote 24 bytes past a heap
  block — the integration tests aborted in `malloc`/`free` 2 runs in 3, and the
  committed PDF test did too (1 in 5). Pinned to 3.1.2, which fixes the struct
  and reads 3.1.0 stores unchanged.
- **ToStore's vector index cannot reach every stored vector** (own-top-hit rate
  100% of 10, 80% of 25, 33% of 60; identical on 3.1.0 and 3.1.2). Not DOCX
  specific; the flow tests that assert on DOCX search index only the DOCX so
  they test DOCX wiring rather than this limit.
