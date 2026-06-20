## Development Guide

Complete guide for contributing to and extending the PDF Chatbot.

---

## Project Structure Explained

### Backend (`/backend`)

```
app/
├── main.py              # FastAPI application entry point
├── config.py            # Environment configuration & settings validation
├── ingestion.py         # Document loading, chunking, preprocessing
├── chains.py            # LangChain RAG orchestration
├── vectordb.py          # Vector database (Qdrant) operations
├── models/
│   └── schemas.py       # Pydantic request/response models
├── api/
│   └── routes.py        # API endpoints (/chat, /ingest, etc.)
└── utils/
    └── logger.py        # Logging setup

tests/                   # Unit & integration tests
requirements.txt         # Python dependencies
Dockerfile             # Container image
.env.example           # Environment template
```

### Frontend (`/frontend`)

```
src/
├── App.jsx                    # Root component
├── index.jsx                  # React entry point
├── index.css                  # Global styles
├── components/
│   ├── Header.jsx            # Top navigation bar
│   ├── ChatBox.jsx           # Main chat interface
│   ├── Message.jsx           # Individual message display
│   └── Citation.jsx          # Source citation component
├── services/
│   └── api.js                # Backend API client
└── constants.js              # App constants

public/
├── index.html                # HTML template
Dockerfile                    # Container image
tailwind.config.js            # Tailwind CSS config
vite.config.js                # Vite bundler config
package.json                  # Node dependencies
```

---

## Development Workflow

### 1. Setup Development Environment

```bash
# Clone repo
git clone <repo>
cd pdf-chatbot

# Backend setup
cd backend
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your API keys

# Frontend setup
cd ../frontend
npm install
cp .env.example .env
```

### 2. Run Services for Development

```bash
# Terminal 1: Vector DB
docker run -p 6333:6333 qdrant/qdrant

# Terminal 2: Backend with auto-reload
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 3: Frontend with Vite dev server
cd frontend
npm run dev

# Terminal 4: Optional - Test in another shell
```

### 3. Code & Test

Make changes and tests will auto-reload in dev mode.

### 4. Run Tests

```bash
# Backend tests
cd backend
pytest tests/ -v --cov=app

# Frontend tests (when added)
cd frontend
npm test
```

### 5. Commit & Push

```bash
git add .
git commit -m "feat: add new feature"
git push origin feature-branch
```

---

## Adding Features

### Example 1: Add a New API Endpoint

**Goal**: Add `/api/summarize` endpoint to summarize documents

**Steps**:

1. **Add schema** (`backend/app/models/schemas.py`):
```python
class SummarizeRequest(BaseModel):
    document: str = Field(..., description="Document text to summarize")
    max_length: int = Field(default=200, description="Max summary length")

class SummarizeResponse(BaseModel):
    summary: str
    original_length: int
    summary_length: int
```

2. **Add logic** (new file `backend/app/summarizer.py`):
```python
from app.chains import rag_chain
from app.utils.logger import logger

def summarize_text(text: str, max_length: int = 200) -> str:
    """Summarize text using LLM."""
    prompt = f"Summarize this text in {max_length} words:\n\n{text}"
    summary = rag_chain.llm.predict(prompt)
    return summary.strip()
```

3. **Add endpoint** (`backend/app/api/routes.py`):
```python
from app.summarizer import summarize_text
from app.models.schemas import SummarizeRequest, SummarizeResponse

@router.post("/summarize", response_model=SummarizeResponse)
async def summarize(request: SummarizeRequest) -> SummarizeResponse:
    """Summarize document text."""
    try:
        summary = summarize_text(request.document, request.max_length)
        return SummarizeResponse(
            summary=summary,
            original_length=len(request.document),
            summary_length=len(summary)
        )
    except Exception as e:
        logger.error(f"Summarization error: {e}")
        raise HTTPException(status_code=500, detail="Summarization failed")
```

4. **Test** (new test `backend/tests/test_summarizer.py`):
```python
def test_summarize_endpoint(client):
    response = client.post("/api/summarize", json={
        "document": "Long text here...",
        "max_length": 100
    })
    assert response.status_code == 200
    assert "summary" in response.json()
```

### Example 2: Add Frontend Component

**Goal**: Add a document upload widget

**Steps**:

1. **Create component** (`frontend/src/components/DocumentUpload.jsx`):
```jsx
import React, { useState } from 'react'
import { Upload } from 'lucide-react'
import { ingestDocument } from '../services/api'

export const DocumentUpload = ({ onSuccess }) => {
  const [loading, setLoading] = useState(false)

  const handleUpload = async (e) => {
    const file = e.target.files[0]
    if (!file) return

    setLoading(true)
    try {
      const result = await ingestDocument('pdf', file.name, 'pdf_documents')
      onSuccess(result)
    } catch (error) {
      console.error('Upload failed:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-4 border-2 border-dashed border-blue-300 rounded">
      <label className="flex items-center gap-2 cursor-pointer">
        <Upload size={20} />
        <span>Upload PDF</span>
        <input
          type="file"
          onChange={handleUpload}
          disabled={loading}
          accept=".pdf"
          hidden
        />
      </label>
    </div>
  )
}
```

2. **Use in App** (update `frontend/src/App.jsx`):
```jsx
import DocumentUpload from './components/DocumentUpload'

export default function App() {
  const handleUploadSuccess = (result) => {
    console.log(`Uploaded ${result.chunks_created} chunks`)
  }

  return (
    <div>
      <Header />
      <DocumentUpload onSuccess={handleUploadSuccess} />
      <ChatBox />
    </div>
  )
}
```

---

## Debugging

### Backend Debugging

```bash
# Add logging to debug
from app.utils.logger import logger
logger.info(f"Debug: {variable}")

# Run with debug mode
python -m uvicorn app.main:app --reload --log-level debug

# Use Python debugger
import pdb; pdb.set_trace()

# Check API docs
http://localhost:8000/docs
```

### Frontend Debugging

```bash
# Browser DevTools
F12 or Cmd+Option+I

# Console logging
console.log('Debug:', variable)

# React DevTools (Chrome extension)
# Install: https://chrome.google.com/webstore

# Debug network requests
// In browser DevTools → Network tab
```

### Common Issues

#### Backend not responding

```bash
# Check if running
curl http://localhost:8000/api/health

# Check logs
docker-compose logs backend

# Check port conflict
lsof -i :8000
```

#### Frontend build errors

```bash
# Clear cache
rm -rf node_modules package-lock.json
npm install

# Check for syntax errors
npm run lint
```

---

## Testing

### Backend Testing

```bash
# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/test_ingestion.py -v

# Run with coverage
pytest tests/ --cov=app

# Run only failing tests
pytest --lf

# Watch mode
ptw
```

### Writing Tests

```python
# backend/tests/test_feature.py
import pytest
from app.chains import rag_chain

def test_embed_text():
    """Test embedding generation."""
    text = "Hello world"
    embedding = rag_chain.embed_text(text)
    
    assert isinstance(embedding, list)
    assert len(embedding) == 1536  # OpenAI embedding size
    assert all(isinstance(x, float) for x in embedding)
```

### Frontend Testing (Setup)

```bash
# Install testing deps
npm install --save-dev vitest @testing-library/react

# Create test
# frontend/src/components/ChatBox.test.jsx
import { render, screen } from '@testing-library/react'
import ChatBox from './ChatBox'

test('renders chat input', () => {
  render(<ChatBox />)
  const input = screen.getByPlaceholderText(/ask a question/i)
  expect(input).toBeInTheDocument()
})

# Run tests
npm test
```

---

## Performance Optimization

### Backend

```python
# 1. Cache embeddings
# Set in config: CACHE_EMBEDDINGS=true

# 2. Batch operations
EMBEDDING_BATCH_SIZE=32

# 3. Use async endpoints
@app.post("/api/chat")
async def chat(request: ChatRequest):
    # Use await for I/O operations
    result = await asyncio.to_thread(rag_chain.answer_question, ...)

# 4. Add response caching
from functools import lru_cache
@lru_cache(maxsize=1000)
def get_embeddings(text):
    return rag_chain.embed_text(text)
```

### Frontend

```jsx
// 1. Use React.memo for components
export const ChatBox = React.memo(function ChatBox() {
  // Component code
})

// 2. Lazy load components
const DocumentUpload = lazy(() => import('./DocumentUpload'))

// 3. Optimize re-renders
const [messages, setMessages] = useState([])
const memoizedMessages = useMemo(() => messages, [messages])

// 4. Debounce input
const [query, setQuery] = useState('')
const debouncedQuery = useDebounce(query, 300)
```

---

## Code Style & Standards

### Backend (Python)

```bash
# Format code
black app/

# Lint
flake8 app/ tests/

# Type checking
mypy app/ --ignore-missing-imports

# All in one
pre-commit run --all-files
```

### Frontend (JavaScript)

```bash
# Format
npm run format

# Lint
npm run lint

# Prettier config
npx prettier --write src/
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Keep branch updated
git rebase main

# Push to remote
git push origin feature/new-feature

# Create pull request on GitHub
# Get review, make changes if needed
# Merge when approved
```

---

## Documentation

### Documenting Functions

**Backend (Python)**:
```python
def answer_question(
    query: str,
    collection_name: str,
    top_k: int = 4
) -> Dict[str, Any]:
    """
    Answer a question using RAG.
    
    Performs vector search followed by LLM generation.
    
    Args:
        query: User's question
        collection_name: Document collection to search
        top_k: Number of top documents to retrieve
    
    Returns:
        Dict with 'answer', 'sources', 'metadata' keys
    
    Raises:
        ValueError: If collection doesn't exist
        
    Example:
        >>> result = answer_question("What is RAG?", "my_docs")
        >>> print(result['answer'])
    """
```

**Frontend (JavaScript)**:
```jsx
/**
 * Display a chat message with optional citations.
 *
 * @param {Object} message - Message object
 * @param {string} message.role - 'user' or 'assistant'
 * @param {string} message.content - Message text
 * @param {Array} message.sources - Citation sources
 *
 * @returns {JSX.Element} Rendered message component
 */
export function Message({ message }) {
  // Component code
}
```

---

## Deployment for Development

### Docker Compose Development

```bash
# Build all services
docker-compose build

# Run with live code reloading
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# View real-time logs
docker-compose logs -f backend frontend
```

### Testing Production Build Locally

```bash
# Build production images
docker-compose -f docker-compose.prod.yml build

# Run locally
docker-compose -f docker-compose.prod.yml up

# Simulate production
ENVIRONMENT=production docker-compose up
```

---

## Contributing Guidelines

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Update documentation
6. Submit a pull request

See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

---

## Useful Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [LangChain Documentation](https://python.langchain.com)
- [Qdrant Vector DB](https://qdrant.tech)
- [React Documentation](https://react.dev)
- [OpenAI API Reference](https://platform.openai.com/docs)

---

Still have questions? Open a GitHub issue or reach out on Discord!
