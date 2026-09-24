# PDF test fixtures — provenance

Real-world PDFs committed for testing `PdfrxTextSource`. A generated PDF only
proves we can read back our own text operator; these prove pdfrx reads documents
produced by a real publishing pipeline — subset-embedded fonts, letter-spaced
headings, headers/footers, multi-page layout.

**Do not re-save, re-compress, or optimise these files.** A mutated fixture stops
being evidence about real-world PDFs. Page selection with `qpdf --pages` is the
only acceptable edit, and must be recorded here.

These are **test-only**. They are deliberately not in `pubspec.yaml`'s `assets:`
(they must never ship to users) and deliberately not in Git LFS (a CI checkout
without `lfs: true` would hand the test a pointer file, which `PdfDocument.openFile`
rejects as a confusing `null` rather than a clear error).

---

## `nist_sp800-145.pdf`

| | |
|---|---|
| Title | *The NIST Definition of Cloud Computing* (Special Publication 800-145) |
| Publisher | National Institute of Standards and Technology, U.S. Department of Commerce |
| Source | https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-145.pdf |
| Retrieved | 2026-09-23 |
| Size | 85,781 bytes |
| PDF version | 1.5 |
| Pages | **7** (confirmed with `pdfinfo` and PDFium; note `file` reports 5 for this document and is wrong) |
| sha256 | `7b0c1a9fdfc67218b8ba2098f448c100c27070db91736b3c87fed63bfa21d418` |
| Licence | Public domain. A work of the U.S. federal government, not subject to copyright in the United States under **17 U.S.C. § 105**. |

### Why this document

Chosen because it is genuinely public domain, small, and structurally close to
the government circulars this feature targets: cover page, letterhead, numbered
sections, headers and footers, multi-page prose.

Indian government sources (India Code, RBI, e-Gazette) were preferred for
subject-matter realism but were unreachable from the development sandbox
(bot/CAPTCHA challenges and timeouts). **Swapping in an Indian circular later is
supported**: drop the file in this directory, add a row here, and update the
phrase constants at the top of
`test/features/shiv/rag/extraction/pdf_text_source_test.dart`.

### Page-unique phrases used by tests

Each of these appears on exactly one page (verified with `pdftotext -f N -l N`).
They are what make the page-ordering assertion meaningful — an implementation
that concatenated every page into `pages[0]` would fail on them.

| Page (1-based) | Phrase |
|---|---|
| 1 | `Recommendations of the National Institute` |
| 3 | `Reports on Computer Systems Technology` |
| 4 | `Acknowledgements` |
| 5 | `Federal Information Security Management Act` |
| 6 | `Cloud computing is a model for enabling ubiquitous` |

Page 6 carries the document's actual definition of cloud computing. That makes it
the natural target for the retrieval tests: a query like *"what is cloud
computing?"* must come back with the page-6 chunk, which is what proves the
embeddings are doing semantic work rather than the plumbing merely running.

**Avoid asserting on** `C O M P U T E R` / `S E C U R I T Y` (page 2) — the source
sets them letter-spaced, so the extracted text contains single characters
separated by spaces. Assertions must also survive curly quotes (page 5), which is
what `normalizePdfText()` in `test/_helpers/pdf_fixtures.dart` is for.
