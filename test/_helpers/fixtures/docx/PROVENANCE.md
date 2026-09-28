# DOCX test fixtures — provenance

Real `.docx` files committed for testing `ArchiveDocxTextSource`. The in-test
`minimalDocx()` builder pins each rule exactly; these prove the reader handles
what real producers actually write — content controls, field codes, table-heavy
layouts, and a second producer's style naming.

**Do not re-save these files in any editor.** Opening and saving rewrites the
XML, and a fixture that has been through a different producer stops being
evidence about the original one.

Test-only: not in `pubspec.yaml` `assets:`, not in Git LFS (same reasons as
`../pdf/PROVENANCE.md`).

---

## `nist-cui-ssp-template.docx`

| | |
|---|---|
| Title | CUI System Security Plan template (for SP 800-171 Rev. 1) |
| Publisher | National Institute of Standards and Technology, U.S. Department of Commerce |
| Source | https://csrc.nist.gov/CSRC/media/Publications/sp/800-171/rev-1/final/documents/CUI-SSP-Template-final.docx |
| Retrieved | 2026-09-26 |
| Producer | Microsoft Office Word (`docProps/app.xml`) |
| Size | 72,016 bytes |
| sha256 | `4efe089c416ecb7bf000151ad3c790574735494302ae2bd9c901aee39e208f85` |
| Licence | Work of the U.S. federal government — public domain in the U.S. (17 U.S.C. §105) |

What it exercises: 116 tables, 330 `w:instrText` field codes that must not leak
into extracted text, and **no heading-styled paragraphs** — its sections are
table rows. It is the real-world case for "no heading ⇒ empty label".

## `uspto-initial-filing-template.docx`

| | |
|---|---|
| Title | DOCX Initial Filing Template (August 2025) |
| Publisher | United States Patent and Trademark Office |
| Source | https://www.uspto.gov/sites/default/files/documents/Initial-Filing-Template-August-2025.docx |
| Retrieved | 2026-09-26 |
| Producer | Microsoft Office Word 16.0 |
| Size | 87,219 bytes |
| sha256 | `bdf539a29502be4893b85991ae1868dd8b68d470cf63c1e3df6f4990cfee3fae` |
| Licence | Work of the U.S. federal government — public domain in the U.S. (17 U.S.C. §105) |

What it exercises: 9 block-level content controls (`w:sdt`) wrapping the
section-header paragraphs — text a reader walking only direct `w:body`
children would silently drop. Its custom header styles (`Specification`,
`Claim`, …) are neither named `heading N` nor carry an outline level, so they
are correctly *not* headings.

## `leave-policy-libreoffice.docx`

| | |
|---|---|
| Source | Generated from `leave-policy-libreoffice.source.html` (committed alongside) |
| Command | `soffice --headless --convert-to 'docx:MS Word 2007 XML' leave-policy-libreoffice.source.html` |
| Producer | LibreOffice 24.2.7.2 |
| Created | 2026-09-26 |
| Size | 6,477 bytes |
| sha256 | `69feb07b0707c8fc0278061544c84ad7acbfd5494b2587ca665e8e5e5e745daa` |
| Licence | Written for this repository |

What it exercises: real `Heading 1` sections from a producer other than Word —
LibreOffice names the style `Heading 1` (capital H) where Word writes
`heading 1`, and bases it on its own `Heading` style. One text paragraph
precedes the first heading, and one table sits in the last section.

The two federal templates above carry no heading styles; public-domain Word
documents that do could not be fetched (ed.gov serves a bot check), hence a
generated third fixture for the heading path.
