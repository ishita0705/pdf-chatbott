# PDF + Website Q&A Chatbot (RAG with LangChain)

A simple-to-intermediate LangChain RAG chatbot that ingests PDFs and websites, builds a vector index, and answers user questions with source citations.

## Features

- **PDF & Website Ingestion**: Load PDFs and scrape websites automatically
- **Vector Search**: Embed documents and retrieve relevant context using OpenAI embeddings or local sentence-transformers
- **LLM Integration**: Answer questions using GPT-4/Claude with retrieved context (retrieval-augmented generation)
- **Source Citations**: Every answer includes links to source documents and page numbers
- **Conversation Memory**: Optional short-term memory for multi-turn conversations
- **Web Chat UI**: React + Tailwind for a modern, responsive chat interface
- **Docker Setup**: One-command local development with docker-compose
- **Production-Ready**: FastAPI, Qdrant vector DB, environment-based configuration

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Backend** | Python 3.10+, FastAPI, LangChain |
| **LLM** | OpenAI (gpt-4-turbo) or Anthropic Claude |
| **Embeddings** | OpenAI Embeddings or sentence-transformers |
| **Vector DB** | Qdrant (managed or local) |
| **Frontend** | React 18, TypeScript, Tailwind CSS |
| **API Framework** | FastAPI with CORS support |
| **Deployment** | Docker, docker-compose, Cloud Run/EC2 |

## Quick Start

### Prerequisites

- Docker & Docker Compose (recommended)
- Python 3.10+ (if running locally)
- Node 18+ (if running frontend locally)
- OpenAI API key (or Anthropic key)

### Option 1: Docker (Recommended)

```bash
# Clone the repo
git clone <repo>
cd pdf-chatbot

# Copy env file and set your API keys
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Edit backend/.env with your OpenAI API key
# OPENAI_API_KEY=sk-...

# Start all services (backend API, Qdrant vector DB, React frontend)
docker-compose up --build

# Access:
# - Chat UI: http://localhost:3000
# - API docs: http://localhost:8000/docs
# - Qdrant console: http://localhost:6333/dashboard
```

### Option 2: Local Development

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
cp .env.example .env  # edit .env with your keys
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Frontend:**
```bash
cd frontend
npm install
cp .env.example .env
npm start
```

**Qdrant (Vector DB):**
```bash
docker run -p 6333:6333 qdrant/qdrant
```

## Project Structure

```
backend/
├── app/
│   ├── main.py           → FastAPI app, CORS, startup logic
│   ├── config.py         → Environment variables & settings
│   ├── ingestion/        → PDF loader, web scraper, chunking
│   ├── chains/           → LangChain RetrievalQA chain
│   ├── models/           → Pydantic schemas (Request, Response)
│   ├── utils/            → Logger, decorators
│   └── api/
│       └── routes.py     → /chat, /ingest, /health endpoints
├── tests/                → Unit & integration tests
├── requirements.txt
├── Dockerfile
└── .env.example

frontend/
├── src/
│   ├── components/       → ChatBox, Message, Citation components
│   ├── pages/            → ChatPage, AdminPage
│   ├── services/         → API client
│   ├── App.tsx
│   └── index.tsx
├── package.json
├── Dockerfile
└── tailwind.config.js
```

## Workflow: Step-by-Step

### 1. Ingest Documents
- Upload PDFs or provide a website URL
- Backend loads documents, extracts text, chunks them (1000 tokens + 200 overlap)
- Embed chunks using OpenAI or local embeddings
- Store embeddings + metadata in Qdrant vector DB

### 2. User Asks a Question
- Frontend sends query + conversation ID to `/chat` endpoint
- Backend retrieves top-k chunks from Qdrant (semantic similarity)
- Combines retrieved context with LLM prompt
- LLM generates answer + citations

### 3. Display Answer + Citations
- Frontend renders answer text
- Shows source metadata: document name, page number, chunk text snippet
- User can expand citations or download PDFs

### 4. Optional: Conversation Memory
- Store messages in conversation history
- Retrieve and condense past messages for context
- Better multi-turn UX

## Usage Examples

### Ingesting Documents

```bash
curl -X POST http://localhost:8000/api/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "source_type": "pdf",
    "path": "/path/to/document.pdf",
    "collection_name": "my_docs"
  }'
```

### Asking a Question

```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the main benefits?",
    "collection_name": "my_docs",
    "conversation_id": "user_123",
    "top_k": 4
  }'
```

Response:
```json
{
  "answer": "The main benefits include...",
  "sources": [
    {
      "document": "doc1.pdf",
      "page": 3,
      "text": "Benefits include..."
    }
  ],
  "metadata": {
    "retrieval_time_ms": 145,
    "llm_tokens": 256
  }
}
```

## Configuration

Create `backend/.env`:
```
# LLM
OPENAI_API_KEY=sk-...
LLM_MODEL=gpt-4-turbo
LLM_TEMPERATURE=0.2

# Embeddings
EMBEDDING_MODEL=text-embedding-3-small

# Vector DB
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=

# API
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=["http://localhost:3000"]

# Logging
LOG_LEVEL=INFO
```

## Testing

Run tests:
```bash
cd backend
pytest tests/ -v --cov=app
```

## Deployment

### Cloud Run (Google Cloud)

```bash
cd backend
gcloud builds submit --tag gcr.io/PROJECT_ID/pdf-chatbot-backend
gcloud run deploy pdf-chatbot \
  --image gcr.io/PROJECT_ID/pdf-chatbot-backend \
  --platform managed \
  --region us-central1 \
  --set-env-vars OPENAI_API_KEY=sk-...
```

### AWS EC2 / Docker Host

```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Monitoring & Observability

- **Logs**: ELK stack or CloudWatch
- **Metrics**: Prometheus scrape metrics from `/metrics`
- **Tracing**: OpenTelemetry integration (optional)
- **Errors**: Sentry integration (optional)

## Next Steps / Future Enhancements

1. **Authentication**: Add OAuth2 / JWT for multi-user support
2. **Access Control**: Per-document ACLs and user roles
3. **Hybrid Search**: BM25 + vector search for better recall
4. **Conversational Memory**: Long-term user context & summarization
5. **Local LLMs**: Ollama / Llama2 for privacy-critical deployments
6. **Multi-modal**: Support images, tables, and charts in PDFs
7. **Admin Panel**: Manage documents, view analytics, monitor usage
8. **Cost Optimization**: Cache embeddings, batch inference, quantization

## Troubleshooting

### Vector DB Connection Error
```
Make sure Qdrant is running: docker run -p 6333:6333 qdrant/qdrant
Or check QDRANT_URL in .env
```

### OpenAI API Rate Limited
```
Reduce batch_size in ingestion or add exponential backoff in config
```

### Frontend Cannot Reach Backend
```
Check CORS_ORIGINS in backend/.env includes frontend URL
Check API_URL in frontend/.env matches backend port
```

## Contributing

1. Fork the repo
2. Create feature branch: `git checkout -b feature/my-feature`
3. Run tests: `pytest tests/`
4. Commit: `git commit -m "feat: my feature"`
5. Push and open PR

## License

MIT License — see LICENSE file for details

## Support

For issues and questions, open a GitHub issue or email support@example.com
