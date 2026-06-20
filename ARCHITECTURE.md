## System Architecture & Code Explanation

Complete breakdown of the PDF Chatbot architecture, components, and how they work together.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     USER BROWSER                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  React Frontend (port 3000)                          │  │
│  │  - ChatBox: Input/output for messages              │  │
│  │  - Message: Display messages with sources          │  │
│  │  - Citation: Show document references              │  │
│  └──────────────────────────────────┬───────────────────┘  │
└─────────────────────────────────────┼──────────────────────┘
                                      │ HTTP/JSON
                                      ▼
┌─────────────────────────────────────────────────────────────┐
│                   BACKEND SERVER                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  FastAPI (port 8000)                                 │  │
│  │  - /chat: Process queries, return answers           │  │
│  │  - /ingest: Load documents, embed, store            │  │
│  │  - /health: Readiness checks                        │  │
│  └─────────┬──────────────────────────────┬─────────────┘  │
│            │                              │                 │
│   ┌────────▼──────────┐         ┌────────▼──────────┐      │
│   │ LangChain Chain   │         │ Document          │      │
│   │ (chains.py)       │         │ Ingestion         │      │
│   │                   │         │ (ingestion.py)    │      │
│   │ - Embedding       │         │                   │      │
│   │ - Retrieval       │         │ - Load PDF/URL    │      │
│   │ - LLM generation  │         │ - Parse text      │      │
│   │ - Citation format │         │ - Chunk & split   │      │
│   └────────┬──────────┘         │ - Attach metadata │      │
│            │                    └────────┬──────────┘      │
│            └─────────────┬───────────────┘                 │
│                          │                                 │
│                  ┌───────▼────────┐                        │
│                  │ Vector DB Ops  │                        │
│                  │ (vectordb.py)  │                        │
│                  │                │                        │
│                  │ - Create index │                        │
│                  │ - Upsert docs  │                        │
│                  │ - Similarity   │                        │
│                  │   search       │                        │
│                  └───────┬────────┘                        │
└─────────────────────────┼─────────────────────────────────┘
                          │ gRPC
                          ▼
┌─────────────────────────────────────────────────────────────┐
│     QDRANT VECTOR DATABASE (port 6333)                      │
│  - Stores embeddings of document chunks                     │
│  - Enables semantic similarity search                       │
│  - Returns top-k similar documents with scores              │
└─────────────────────────────────────────────────────────────┘

            │
            │ Calls
            ▼
┌─────────────────────────────────────────────────────────────┐
│  External APIs (OpenAI, Anthropic)                          │
│  - Embedding generation                                     │
│  - LLM-based answer generation                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow: Complete Workflow

### Flow 1: Document Ingestion

```
User uploads document
         │
         ▼
/api/ingest endpoint
         │
         ├─ Load document (PDF, text, website)
         │      └─ PDF: Use pypdf to extract text
         │      └─ Text: Read from file
         │      └─ Website: Scrape with BeautifulSoup
         │
         ├─ Clean text (normalize whitespace)
         │
         ├─ Split into chunks (1000 tokens + 200 overlap)
         │      └─ Each chunk is independently retrievable
         │      └─ Metadata: source, page, chunk index
         │
         ├─ Embed chunks (30 API calls for 1000 chunks)
         │      └─ OpenAI: 1536-dim vectors
         │      └─ Or local: 384-dim vectors
         │
         ├─ Create Qdrant collection (if needed)
         │
         ├─ Upsert to vector DB
         │      └─ Each chunk + embedding stored
         │      └─ Metadata indexed for filtering
         │
         ▼
Chunks searchable via similarity
```

### Flow 2: Question Answering

```
User types question
         │
         ▼
/api/chat endpoint
         │
         ├─ Embed question (same model as documents)
         │      └─ Results in 1536-dim vector
         │
         ├─ Search vector DB (Qdrant)
         │      └─ Cosine similarity to stored embeddings
         │      └─ Return top-4 most similar chunks
         │      └─ Each includes text, source, relevance score
         │
         ├─ Build context from retrieved chunks
         │      └─ Concatenate text + metadata
         │      └─ Keep under token limit (~2000 tokens)
         │
         ├─ Call LLM with prompt:
         │      ┌─────────────────────────────────────┐
         │      │ "You are a helpful assistant.      │
         │      │  Answer using only these documents:│
         │      │  [document 1]                      │
         │      │  [document 2]                      │
         │      │  Question: {user_query}            │
         │      │  Include which document you used." │
         │      └─────────────────────────────────────┘
         │
         ├─ LLM generates answer
         │      └─ Temperature 0.2 (mostly deterministic)
         │      └─ Max 500 tokens output
         │
         ├─ Format response
         │      ├─ Answer text
         │      ├─ Sources list (document, page, snippet)
         │      └─ Metadata (timing, scores)
         │
         ▼
Return JSON response to frontend
         │
         ▼
Frontend displays:
  - Answer in message bubble
  - Sources with expand/collapse
  - Timing metrics
```

---

## File-by-File Code Breakdown

### Backend Core Files

#### `backend/app/config.py`

**Purpose**: Configuration management

**Key Concepts**:
- Loads from `.env` file
- Type-safe with Pydantic
- Settings object accessed globally via `from app.config import settings`

```
Settings categories:
├─ LLM: Which model, API key, temperature
├─ Embeddings: Model selection (OpenAI vs local)
├─ Vector DB: Qdrant URL, API key
├─ API: Port, CORS origins, environment
├─ RAG: Chunk size, retrieval count, memory length
└─ Logging: Log level, format
```

**Usage**:
```python
from app.config import settings
api_key = settings.openai_api_key
port = settings.api_port
```

#### `backend/app/main.py`

**Purpose**: FastAPI app setup and startup

**Key Concepts**:
- Entry point for the server
- Registers middleware (CORS, logging)
- Includes API routes
- Handles errors globally

**Flow**:
1. Create FastAPI instance with lifespan events
2. Add CORS middleware (allows frontend to reach backend)
3. Add request logging middleware (logs every request)
4. Include routes from `api/routes.py`
5. Add global exception handler
6. When `uvicorn app.main:app` runs, FastAPI starts listening

#### `backend/app/ingestion.py`

**Purpose**: Load documents and prepare them for indexing

**Key Classes**: `DocumentProcessor`

**Key Methods**:
- `load_pdf(path)`: Extract text + metadata from PDF
- `load_text_file(path)`: Read text file
- `scrape_website(url)`: Download and parse HTML
- `clean_text(text)`: Remove extra whitespace
- `chunk_text(text, metadata)`: Split into overlapping chunks
  - Each chunk: `{id, text, metadata}`
  - Metadata: source, page, chunk_index
- `process_document(source)`: Main entry point

**Example**:
```python
chunks = processor.process_document("/path/to/file.pdf", "pdf")
# Returns: [
#   {"id": "file.pdf_0", "text": "...", "metadata": {...}},
#   {"id": "file.pdf_1", "text": "...", "metadata": {...}}
# ]
```

#### `backend/app/vectordb.py`

**Purpose**: Manage vector database operations with Qdrant

**Key Class**: `VectorDB`

**Key Methods**:
- `create_collection(name)`: Create indexed collection for embeddings
- `upsert_documents(collection, documents, embeddings)`: Store docs + vectors
- `search(collection, query_vector, top_k)`: Semantic similarity search
- `delete_collection(name)`: Remove collection

**How Search Works**:
1. Query vector comes in (1536 dims)
2. Qdrant compares to all stored vectors using cosine similarity
3. Returns top-k with highest similarity scores
4. Scores range 0-1 (1 = perfect match)

#### `backend/app/chains.py`

**Purpose**: RAG orchestration using LangChain

**Key Class**: `RAGChain`

**Key Components**:
1. **Embeddings**: Converts text to vectors
   - `embed_text(text)`: Single query embedding
   - `embed_documents(texts)`: Batch embedding
   - Option 1: OpenAI (1536-dim, costs money)
   - Option 2: Local sentence-transformers (384-dim, free)

2. **LLM**: Generates answers
   - OpenAI: GPT-4 or GPT-3.5-turbo
   - Temperature: 0.2 (deterministic for facts)

3. **Answer Generation**:
```python
def answer_question(query, collection_name, top_k=4):
    1. query_embedding = embed_text(query)
    2. retrieved_docs = vector_db.search(query_embedding, top_k)
    3. context = format_docs(retrieved_docs)
    4. answer = llm.generate(prompt=f"{context}\n{query}")
    5. return formatted_response
```

#### `backend/app/models/schemas.py`

**Purpose**: Define request/response types

**Key Schemas**:
- `ChatRequest`: User query + options
- `ChatResponse`: Answer + sources + metadata
- `IngestRequest`: Document to load
- `IngestResponse`: Status + chunk count
- `SourceCitation`: Single source reference
- `HealthResponse`: Service status

**Why Pydantic?**
- Auto validation: Rejects bad requests
- Type safety: Catches errors early
- Auto documentation: Swagger UI
- Serialization: JSON ↔ Python objects

#### `backend/app/api/routes.py`

**Purpose**: Define HTTP endpoints

**Key Endpoints**:

1. **POST /api/chat**
   - Input: ChatRequest (query, collection)
   - Output: ChatResponse (answer, sources)
   - Uses: rag_chain.answer_question()

2. **POST /api/ingest**
   - Input: IngestRequest (source, collection)
   - Output: IngestResponse (status, count)
   - Uses: processor.process_document(), rag_chain.embed_documents()

3. **GET /api/health**
   - Output: HealthResponse (status, version)
   - Used by: Load balancers, monitoring

4. **GET /api/collections**
   - Lists all available collections

5. **DELETE /api/collections/{name}**
   - Removes collection (dangerous!)

---

### Backend Utilities

#### `backend/app/utils/logger.py`

**Purpose**: Structured logging

**Key Features**:
- JSON logging in production (for log aggregation)
- Human-readable in development
- Includes timestamps, levels, error tracebacks

**Usage**:
```python
from app.utils.logger import logger
logger.info("Document ingested")
logger.error("Failed to embed:", exc_info=True)
```

---

### Frontend Files

#### `frontend/src/services/api.js`

**Purpose**: Centralized API client

**Key Functions**:
- `sendQuery(query, collection, conversationId)`: Chat API call
- `ingestDocument(type, path, collection)`: Ingest API call
- `checkHealth()`: Health check
- `listCollections()`: Get available collections

**Pattern**: Wraps axios with error handling

#### `frontend/src/constants.js`

**Purpose**: App-wide constants

Contains:
- API URL
- App title
- Default collection name
- Message role constants
- UI messages

**Usage**:
```javascript
import { API_URL, DEFAULT_COLLECTION } from '../constants'
```

#### `frontend/src/components/ChatBox.jsx`

**Purpose**: Main chat interface

**State**:
- `messages`: Array of {role, content, sources}
- `input`: User's typed query
- `loading`: Show spinner while waiting for response
- `conversationId`: Unique ID for this conversation

**Flow**:
1. User types and hits Enter
2. Add to messages, clear input
3. Call `/api/chat` with query
4. Get response with answer + sources
5. Add bot message to messages
6. Auto-scroll to bottom

**Key Features**:
- Collection name selector
- Error display
- Disabled state when loading
- Auto-scroll to latest message

#### `frontend/src/components/Message.jsx`

**Purpose**: Display single message

**Features**:
- Different styling for user vs bot
- Shows sources for bot messages
- Displays timing metadata

#### `frontend/src/components/Citation.jsx`

**Purpose**: Show source document reference

**Features**:
- Expandable/collapsible
- Shows document name, page, relevance score
- Expandable to show snippet text

#### `frontend/src/components/Header.jsx`

**Purpose**: Top bar with title and status

**Features**:
- Health check every 30 seconds
- Shows connected/offline status
- Green/red indicator

#### `frontend/src/App.jsx`

**Purpose**: Root component

Renders:
- Header
- ChatBox
- Wraps in layout

#### `frontend/src/index.jsx`

**Purpose**: React entry point

Mounts App to `#root` element in HTML

---

## How Everything Connects

### Ingestion Example

```
1. User uploads "document.pdf"
   └─ HTTP POST /api/ingest

2. Backend receives request
   └─ Calls processor.process_document()
      └─ Loads PDF with pypdf
      └─ Extracts text "Lorem ipsum..."
      └─ Chunks into ~10 pieces
      └─ Adds metadata: {source, page, chunk_index}
      └─ Returns [{id, text, metadata}, ...]

3. Embed chunks
   └─ Calls rag_chain.embed_documents(texts)
      └─ For each chunk, calls OpenAI API
      └─ Returns [[1536-dim vector], ...]
      └─ Caches locally if CACHE_EMBEDDINGS=true

4. Upsert to Qdrant
   └─ Calls vector_db.upsert_documents()
      └─ Creates point for each chunk
      └─ Sets vector = embedding
      └─ Stores metadata as payload
      └─ Qdrant builds internal indices
      └─ Returns count

5. Response sent to frontend
   └─ {"status": "success", "chunks_created": 10}

6. Frontend shows success message
   └─ User can now ask questions
```

### Question-Answering Example

```
1. User types "What is AI?" and hits Enter
   └─ Frontend calls sendQuery()
   └─ HTTP POST /api/chat

2. Backend receives request
   └─ query = "What is AI?"
   └─ collection = "pdf_documents"

3. Embed question
   └─ rag_chain.embed_text("What is AI?")
   └─ Calls OpenAI API
   └─ Returns [1536-dim vector]

4. Search vector DB
   └─ vector_db.search(query_vector, top_k=4)
   └─ Qdrant compares to all stored vectors
   └─ Returns top 4 with text, metadata, score
   └─ Example: [
   │    {
   │      "text": "AI is artificial intelligence...",
   │      "document": "intro.pdf",
   │      "page": 1,
   │      "score": 0.92
   │    },
   │    ...
   │  ]

5. Build context
   └─ Concatenates all retrieved text
   └─ Formats for LLM

6. Generate answer
   └─ rag_chain.llm.predict(prompt)
   └─ Calls OpenAI API with prompt:
   │  "You are a helpful assistant.
   │   Use only these documents:
   │   [retrieved text]
   │   Question: What is AI?"
   └─ LLM returns answer

7. Format response
   └─ ChatResponse {
   │    answer: "AI is...",
   │    sources: [
   │      {document: "intro.pdf", page: 1, text: "...", score: 0.92}
   │    ],
   │    metadata: {total_time_ms: 450, ...}
   │  }

8. Frontend displays
   └─ Message bubble with answer
   └─ Sources section with citations
   └─ User can expand sources to read snippets
```

---

## Key Design Patterns

### 1. Dependency Injection via Globals

```python
# Each module creates singleton instances
# app/vectordb.py:
vector_db = VectorDB()

# app/chains.py:
rag_chain = RAGChain()

# app/ingestion.py:
processor = DocumentProcessor()

# Imported where needed:
from app.vectordb import vector_db
from app.chains import rag_chain
```

**Pro**: Easy to use, single instance
**Con**: Not easily testable (use mocks in tests)

### 2. Pydantic Schemas for Validation

```python
# Request automatically validated
class ChatRequest(BaseModel):
    query: str  # Required
    top_k: int = Field(default=4, ge=1, le=10)  # Optional with constraints

# FastAPI auto-rejects invalid requests
POST /api/chat with {"query": "test"} ✓
POST /api/chat with {"query": 123} ✗ (not a string)
POST /api/chat with {} ✗ (missing query)
```

### 3. Error Handling Pyramid

```python
# Specific exceptions caught first
try:
    retrieval_result = vector_db.search(...)
except ValueError:  # Specific
    # Handle missing collection
except Exception:     # General catch-all
    logger.error("Unexpected error")
```

### 4. Async/Await for I/O

```python
# FastAPI routes are async for better concurrency
@app.post("/api/chat")
async def chat(request: ChatRequest):
    # I/O operations (API calls, DB queries)
    result = await asyncio.to_thread(
        rag_chain.answer_question, query
    )
    return result
```

---

## Technology Stack Rationale

| Component | Technology | Why |
|-----------|-----------|-----|
| Web Framework | FastAPI | Async, auto-docs, fast |
| LLM Orchestration | LangChain | Abstracts different LLMs, built-in chains |
| Embeddings | OpenAI or local | Accuracy vs cost trade-off |
| Vector DB | Qdrant | Fast, scalable, good Python support |
| Frontend | React | Reactive UI, large ecosystem |
| Styling | Tailwind CSS | Utility-first, fast to build |
| Build Tool | Vite | Fast, modern, minimal config |
| Container | Docker | Reproducible, easy deployment |
| Testing | Pytest | Simple, powerful Python testing |

---

## Performance Considerations

### Backend

- **Embedding bottleneck**: API calls are slowest
  - Solution: Batch embeddings, cache results
  
- **Vector search**: Qdrant is optimized (sub-100ms for 1M vectors)
  - Solution: Use indices, pre-filter metadata
  
- **LLM latency**: 1-3 seconds typical
  - Solution: Stream responses, use faster models

### Frontend

- **Component re-renders**: Can be slow with many messages
  - Solution: Use React.memo, virtualization for huge lists
  
- **API calls**: Blocking on response
  - Solution: Show loading states, debounce input

---

## Security Considerations

1. **API Keys**
   - Never commit `.env` files
   - Use environment variables
   - Rotate keys regularly

2. **Input Validation**
   - Pydantic schemas validate all inputs
   - SQL injection not applicable (no SQL)
   - Prompt injection: LLM can still hallucinate

3. **CORS**
   - Restrict to known frontend URLs
   - Prevent CSRF attacks

4. **Authentication** (Future)
   - Add OAuth2 / JWT
   - Per-user collections
   - ACLs on documents

---

## Next Steps for Enhancement

1. **User Authentication**: JWT tokens, OAuth
2. **Document Versioning**: Track changes over time
3. **Hybrid Search**: BM25 + vector for better recall
4. **Streaming Responses**: Stream LLM output to frontend
5. **Batch Ingestion**: Upload multiple files at once
6. **Analytics**: Track popular questions, errors
7. **Admin Dashboard**: Monitor usage, manage documents
8. **Multi-model Support**: Compare different LLMs
9. **Caching Layer**: Redis for query caching
10. **Rate Limiting**: Prevent abuse

---

For more details on specific components, see:
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Development workflow
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Production deployment
- [QUICKSTART.md](./QUICKSTART.md) - Getting started
