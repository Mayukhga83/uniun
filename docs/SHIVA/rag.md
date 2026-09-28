 > ⚠️ **Historical "basics" primer.** This explains the core RAG idea in the simplest possible terms and predates the actual build — some details below (embeddings stored directly on `NoteModel`, "future: migrate to sqlite-vec") don't match what shipped. For the real, current implementation (ToStore vector DB, GraphRAG expansion, per-model prompt budgets), read `docs/SHIVA/graphrag.md` and `docs/SHIVA/SHIV_AI.md`'s RAG Pipeline section instead. Keep reading below only for the plain-English mental model.

 What is RAG?
                                                                                
  RAG = Retrieval Augmented Generation                      
                                                                                
  Without RAG, Shiv only knows what the LLM was trained on. It has no idea what 
  YOU wrote in your notes.
                                                                                
  With RAG, Shiv can answer questions like:                                     
  - "What did I write about machine learning?"
  - "Summarize my notes on project X"                                           
  - "Find everything I saved about Nostr"                   
                                                                                
  ---                                                                           
  The Core Idea
                                                                                
  Normal LLM:                                               
    User asks → LLM answers from training data only                             
                                                                                
  RAG:                                                                          
    User asks → Find relevant notes → Give notes + question to LLM → Better     
  answer                                                                        
  
  The LLM's context window becomes a temporary "working memory" that you fill   
  with the user's own notes before asking the question.     
                                                                                
  ---                                                       
  How It Works — Step by Step
                             
  Step 1: When a note is SAVED → generate embedding
                                                                                
  User saves a note
          ↓                                                                     
  Note content → Embedding Model → [0.12, -0.45, 0.89, ...] (384 numbers)       
          ↓                                                                     
  Store: NoteModel.embedding = [0.12, -0.45, 0.89, ...] in Isar                 
                                                                                
  An embedding is just a list of numbers that captures the semantic meaning of  
  the text. Notes about similar topics produce similar number patterns.         
                                                                                
  ---                                                       
  Step 2: When user asks Shiv a question → find relevant notes

  User types: "what did I write about relays?"
          ↓                                                                     
  Same Embedding Model → [0.08, -0.41, 0.92, ...] (question as numbers)
          ↓                                                                     
  Compare against ALL saved note embeddings in Isar         
          ↓                                                                     
  Cosine Similarity:                                                            
    Note A (about relays) → similarity: 0.91  ✅ very relevant
    Note B (about Python)  → similarity: 0.23  ❌ not relevant                  
    Note C (about Nostr)   → similarity: 0.78  ✅ relevant                      
          ↓                                                                     
  Pick top 3-5 most similar notes                                               
                                                                                
  Cosine similarity = a formula that measures how "close" two vectors are.      
  Result is 0 (unrelated) to 1 (identical meaning).                             
                                                                                
  ---                                                       
  Step 3: Build the LLM prompt with context
                                           
  final prompt = """
  You are Shiv, a personal AI assistant.                                        
  Use the following notes from the user to answer their question.
                                                                                
  --- USER NOTES ---                                        
  Note 1: ${relevantNotes[0].content}                                           
  Note 2: ${relevantNotes[1].content}                                           
  Note 3: ${relevantNotes[2].content}
  --- END NOTES ---                                                             
                                                            
  User question: what did I write about relays?                                 
                                                            
  Answer based on the notes above:                                              
  """;                                                      

  ---
  Step 4: LLM streams back the answer
                                     
  The LLM reads the injected notes + the question and generates a grounded
  answer. It's not guessing from training data — it's reading the user's own    
  notes.
                                                                                
  ---                                                       
  The Two Models Needed
                                                                                
  ┌────────────────┬─────────────────┬──────────────────────────────────────────┐
  │     Model      │       Job       │                Size                      │
  ├────────────────┼─────────────────┼──────────────────────────────────────────┤
  │ Embedding      │ Converts text   │ ~80MB (all-MiniLM-L6-v2) — bundled       │
  │ model          │ to vector       │ always available, no download needed      │
  ├────────────────┼─────────────────┼──────────────────────────────────────────┤
  │ LLM (user-     │ Generates the   │ 586MB–4.3GB depending on model chosen     │
  │ selected, via  │ answer          │ flutter_gemma ^1.5.1                      │
  │ flutter_gemma) │                 │ GPU-accelerated on Android + iOS          │
  │                │                 │ Downloaded once on first Shiv open        │
  └────────────────┴─────────────────┴──────────────────────────────────────────┘

  These run separately. The embedding model runs fast, synchronously. The LLM
  (flutter_gemma) runs slower, streams tokens via getResponseStream().

  For available LLM options see docs/SHIV_AI.md — Model Selection section.
                                                                                
  ---                                                       
  The Challenge: Vector Search in Isar
                                                                                
  Isar has no native vector search. So how do you find similar notes?
                                                                                
  For small corpus (<5,000 saved notes):                                        
  Load all embeddings from Isar into memory                                     
  For each → compute cosine similarity with query vector                        
  Sort by score → pick top K                                                    
  This is fast enough in Dart for small collections.
                                                                                
  For large corpus (future):                                                    
  - Migrate to sqlite-vec (SQLite vector extension) or usearch                  
  - Or maintain a separate HNSW index on device                                 
                                                            
  For UNIUN's use case (personal notes app), most users will have <1,000 saved  
  notes. In-memory Dart computation is totally fine.                            
   
  ---                                                                           
  Full Flow Diagram                                         

  SAVE TIME:
  Note saved → Embedding model → vector → stored in Isar (NoteModel.embedding)
                                                                                
  QUERY TIME:
  User question                                                                 
        ↓                                                                       
  Embedding model → query vector
        ↓                                                                       
  Load all saved note embeddings from Isar                  
        ↓
  Cosine similarity → rank notes
        ↓                                                                       
  Top 3-5 notes retrieved
        ↓                                                                       
  Build prompt: [system prompt + notes + question]          
        ↓                                                                       
  LLM → streams answer token by token
        ↓                                                                       
  ShivStreamingText widget shows it live                                        
   
  ---                                                                           
  Why Only Saved Notes?                                     
                                                                                
  Because:
  1. Regular notes get cleaned up after 7 days (CleanupManager)                 
  2. The user explicitly chose to save these — they're the "important" ones
  3. Generating embeddings for every note ever seen would be wasteful      
  4. Saved notes = the user's personal knowledge base                           
                                                                                
  ---                                                                           
  What Shiv Can Do With This                                                    
                                                                                
  - "Summarize everything I saved this week"                
  - "What are my notes about <topic>?"                                          
  - "Do I have anything related to <question>?"
  - "Find contradictions in my notes about <topic>"                             
  - Future: RAG over referenced notes graph (follow e tags to pull thread
  context)                                                                      
                                                            
  ---                                                                           
  Build Sequence for Shiv                                   

  1. Embedding model integration  (runs offline, no relay needed)
  2. Save note → generate + store embedding                                     
  3. Query pipeline: embed → cosine sim → top-K                                 
  4. Prompt builder (inject notes into LLM context)                             
  5. ShivAIBloc: handle streaming response                                      
  6. Chat UI: ShivStreamingText (token-by-token render)                         
  7. Model selection page (AIModelSelectionPage — see docs/SHIV_AI.md)                 
                                                                                
  This is why Shiv is built last — it needs:
  - Vishnu (so notes exist)
  - Brahma (so user can create notes)
  - Saved notes (so embeddings exist)

  ---
  Next Level: GraphRAG

  Standard vector RAG only finds notes that are semantically similar to the query.
  GraphRAG also traverses the knowledge graph — following note references (e tags),
  topic links (t tags), and reply chains to find connected context that vector
  similarity would miss.

  UNIUN's knowledge graph (already built via Nostr tags) can be used directly as
  a GraphRAG graph — no extra entity extraction needed.

  See docs/graphrag.md for full details.                       
                                                            
---

## PDF documents

A PDF attached to a note has its text extracted, chunked and embedded, so Shiv
can answer from it and cite the page it came from. Design:
`docs/superpowers/specs/2026-09-19-pdf-rag-design.md`.

### How a PDF becomes searchable

```
 You attach a PDF to a note and publish
                │
                ▼
   MediaCacheModel row written      (sha256 → /path/file.pdf, application/pdf)
                │
                │   PdfIndexer watches this table
                ▼
 ┌──────────────────────────────────────────────────────────┐
 │ 1. READ    PdfrxTextSource → PDFium                      │
 │            walks pages 1..N                              │
 │            → ["page 1 text", "page 2 text", …]           │
 ├──────────────────────────────────────────────────────────┤
 │ 2. GATE    looksLikeProse()                              │
 │            ≥200 chars AND ≥15% Unicode letters?          │
 │            NO  → status notSearchable, stop  (a scan)    │
 │            YES ↓                                         │
 ├──────────────────────────────────────────────────────────┤
 │ 3. CHUNK   chunkPages()  —  ≤700 chars, never across     │
 │            a page boundary                               │
 │            ★ every chunk KEEPS its page number ★         │
 ├──────────────────────────────────────────────────────────┤
 │ 4. EMBED   EmbedAndStoreChunkUseCase, per chunk          │
 │            Gecko embedder → vector                       │
 │            (embedding only — no LLM call)                │
 ├──────────────────────────────────────────────────────────┤
 │ 5. STORE   text   → Isar    DocumentChunkModel           │
 │            vector → ToStore document store               │
 │            both keyed  "<sha256>:<ordinal>"              │
 ├──────────────────────────────────────────────────────────┤
 │ 6. MARK    DocumentIndexModel = indexed   ← written LAST │
 │            so a crash retries rather than lying          │
 └──────────────────────────────────────────────────────────┘
```

### How a citation knows its page

The page number is **carried, never recomputed**. The chunk id is the thread that
ties the vector store to the text, and the text to the page:

```
 CHUNK ID  =  "<sha256 of the pdf>:<chunk number>"      e.g.  "a3f9…:12"
                       │                    │
                       │                    └── which chunk
                       └── which document

 ┌── the same id addresses BOTH stores ──────────────────────────┐
 │  ToStore (vectors)            Isar DocumentChunkModel         │
 │  ───────────────────          ──────────────────────          │
 │  id  : "a3f9…:12"             sha256  : "a3f9…"               │
 │  vec : [0.02, -0.11, …]       ordinal : 12                    │
 │                               label   : "5"   ← THE PAGE      │
 │                               text    : "Expense Reimburse…"  │
 └───────────────────────────────────────────────────────────────┘

 "what is the deadline for expense claims?"
            │
            ▼
   embed the question → query vector
            │
            ▼
   ToStore nearest-neighbour  →  id "a3f9…:12"
            │
            ▼
   parseChunkId()  →  (sha256 "a3f9…", ordinal 12)
            │
            ▼
   Isar lookup on the (sha256, ordinal) composite index
            │            →  label "5",  text "Expense Reimbursement…"
            │
            ├──────────► into the PROMPT:  "(p.5) Expense Reimbursement…"
            │                               the model sees the page too
            │
            └──────────► id carried in RagMessage.sourceChunkIds
                                  │
                          user taps "Sources"
                                  │
                                  ▼
                    DocumentSourceRepository.resolve(id)
                        title : filename of the attaching note
                        label : "5"          ──►  tile shows "Page 5"
                        path  : cached file  ──►  tap opens the PDF
```

The vector store never needs to know what a page is — it only returns an id, and
every later step carries the label that `chunkPages()` stamped on at split time.

**Pipeline** — `PdfIndexer` (`lib/features/shiv/rag/indexing/`, main isolate,
started in `main.dart`) watches `MediaCacheModel` and reconciles it against
`DocumentIndexModel` by SHA-256:

```
PDF cache row, no index row   -> index it
index row, no PDF cache row   -> purge its chunks and index row
```

Reconciling state rather than reacting to a "blob arrived" event is what makes
this correct: `MediaRepositoryImpl._upsertCache` has **four** call sites (upload,
download cache-hit, fresh download, staged draft) and runs inside a write
transaction where embedding cannot be awaited; deletion happens in two more
places, one of them `CleanupManager` in the Gateway isolate, which deletes cache
rows directly. A crash mid-index is retried because the index row is written
**last**.

Vectors live in a **separate** ToStore at `tostore_docs_1024d`, never the note
store. Embedding goes through `EmbeddingQueue`, bounding concurrency at 2.

**Retrieval** — unscoped chat only. `RagPipeline` searches notes and chunks
independently (chunk top-K = `max(1, topK ~/ 2)`); chunks skip memory and graph
expansion, since they are not graph nodes. `PromptBuilder` renders them under
`## Relevant Documents`, and `RagMessage.sourceChunkIds` carries them to the
Sources sheet, which resolves them on open via `DocumentSourceRepository`.

A Manas-scoped chat never searches documents: it scopes by note membership, and
a PDF blob has none.

**Scans are kept, not indexed.** No text layer, or text that fails the quality
gate, is recorded `notSearchable`: the document still attaches and opens, it is
simply never cited. An embedder that is not ready is different — it leaves the
document *unindexed* so a later reconcile retries it.

### Two constraints worth knowing before changing this

**Chunks are capped at 700 characters** because `PromptBudget` gives the
smallest local model 1024 tokens total and `buildUserMessage` drops any section
that would overshoot. A page-sized chunk would make the document silently vanish
from the prompt.

**Vectors are never deleted.** ToStore 3.1.0 destroys a table's *entire* vector
index on any row delete — measured: delete 1 of 3 rows and `vectorSearch`
returns nothing, and it does not recover across a close/reopen. So Isar owns
chunk existence: purging deletes the Isar rows, search skips hits it cannot
resolve, and `search` over-fetches to absorb the orphans. Enough
equally-similar orphans can still crowd out a real chunk; the fix is a rebuild
(wipe the store, re-embed from the surviving rows), which is not implemented.
tostore 3.5.1 fixes the delete bug but silently reads back an empty index from a
store written by 3.1.0 — upgrading needs a version-bumped store path so the data
re-embeds instead of disappearing.

### Testing

| Tier | Where | Real | Faked |
|---|---|---|---|
| Unit | `test/features/shiv/rag/extraction/`, `test/domain/entities/shiv/` | chunker, gate, extraction service, chunk ids | PDF source |
| Component | `test/features/shiv/rag/indexing/`, `test/data/...` | real PDFium + the committed PDF, real Isar, real ToStore | embedder |
| Pipeline | `test/integration/pdf_rag_flow_test.dart` | everything above, assembled | embedder |
| Device | `integration_test/pdf_rag_e2e_test.dart` | **everything, incl. the real Gecko embedder** | nothing |

The device tier exists because the embedder loads a 145 MB Git-LFS asset that
CI does not check out, and `EmbeddingService.embed` returns `[]` instead of
throwing when the model is missing — so a CI run would go green while embedding
nothing. Run it by hand:

```
flutter test integration_test/pdf_rag_e2e_test.dart -d <device-id>
```

`flutter test` does not run native-asset build hooks, so PDFium is absent under
a plain `flutter test`. `test/_helpers/pdfium_test_lib.dart` downloads it once
and points pdfrx at it, mirroring what `ensureIsarCore()` already does for
Isar's native binary.

**Not built:** in-app page-jump viewer, documents in Manas-scoped chat, a
`notSearchable` badge, OCR for scans, DOCX.
