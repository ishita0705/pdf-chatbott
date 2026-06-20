## Quick Start Guide

Get up and running with PDF Chatbot in under 10 minutes.

### Option 1: Docker (Recommended - Easiest)

**Time: 5 minutes**

#### Prerequisites
- Docker & Docker Compose installed
- OpenAI API key (free via https://platform.openai.com)

#### Steps

1. **Clone the repository**
```bash
git clone <repo-url>
cd pdf-chatbot
```

2. **Setup environment variables**
```bash
cp backend/.env.example backend/.env
```

3. **Edit `backend/.env`**
```bash
# Edit with your favorite editor (vim, nano, VSCode, etc.)
nano backend/.env

# Change this line:
# OPENAI_API_KEY=your_openai_api_key_here
```

4. **Start all services**
```bash
docker-compose up -d
```

   This will start:
   - Qdrant vector database (port 6333)
   - Backend API (port 8000)
   - Frontend UI (port 3000)

5. **Verify everything is running**
```bash
docker-compose ps

# Should show all 3 containers as "Up"
```

6. **Access the application**
   - Open http://localhost:3000 in your browser
   - You should see the PDF Chatbot interface

---

### Option 2: Local Development

**Time: 15 minutes**

#### Prerequisites
- Python 3.10+ and pip
- Node.js 18+ and npm
- Docker (for Qdrant vector DB)

#### Step 1: Start Vector Database

```bash
# Terminal 1: Start Qdrant
docker run -p 6333:6333 qdrant/qdrant
```

#### Step 2: Setup Backend

```bash
# Terminal 2: Backend
cd backend

# Create virtual environment
python -m venv venv

# Activate (Mac/Linux)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy and edit env
cp .env.example .env
nano .env  # Add your OPENAI_API_KEY

# Run backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend API is now at http://localhost:8000/docs (interactive docs)

#### Step 3: Setup Frontend

```bash
# Terminal 3: Frontend
cd frontend

# Install dependencies
npm install

# Copy env
cp .env.example .env

# Start dev server
npm run dev
```

Frontend is now at http://localhost:5173

---

## First Steps After Starting

### 1. Ingest a Document

After starting the services, you need to add documents before you can ask questions.

**Option A: Using API (Advanced)**

```bash
# Ingest a PDF from file
curl -X POST http://localhost:8000/api/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "source_type": "pdf",
    "path_or_url": "/path/to/document.pdf",
    "collection_name": "pdf_documents"
  }'
```

**Option B: Using UI (Recommended)**

Note: UI file upload coming soon. For now, use the API or provide a URL.

```bash
# Ingest from a website
curl -X POST http://localhost:8000/api/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "source_type": "website",
    "path_or_url": "https://example.com",
    "collection_name": "pdf_documents"
  }'
```

### 2. Ask a Question

Go to http://localhost:3000 and type your question!

```
Example:
User: "What are the main points in the document?"
Bot: "[Answer with citations]"
```

---

## Useful Commands

### Check Status
```bash
# View logs
docker-compose logs -f

# Check specific service
docker-compose logs backend
docker-compose logs frontend

# View all running containers
docker-compose ps
```

### Stop Services
```bash
# Stop all
docker-compose down

# Stop specific service
docker-compose stop backend

# Remove all containers and volumes
docker-compose down -v
```

### Restart Services
```bash
# Restart one service
docker-compose restart backend

# Rebuild and restart
docker-compose up -d --build backend
```

### Access API Documentation
```
http://localhost:8000/docs
```

Interactive Swagger UI to test all endpoints.

---

## Sample Documents for Testing

### Option 1: Use a Public Website

```bash
curl -X POST http://localhost:8000/api/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "source_type": "website",
    "path_or_url": "https://en.wikipedia.org/wiki/Machine_learning",
    "collection_name": "pdf_documents"
  }'

# Then ask: "What is machine learning?"
```

### Option 2: Create a Test Document

```bash
# Create a simple text file
echo "
The Python programming language is a high-level, interpreted language known for its simplicity.
Python was created by Guido van Rossum and first released in 1991.
It emphasizes code readability and supports multiple programming paradigms.
Common uses include web development, data analysis, artificial intelligence, and automation.
Popular frameworks include Django, Flask, NumPy, and TensorFlow.
" > test_document.txt

# Ingest it
curl -X POST http://localhost:8000/api/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "source_type": "text",
    "path_or_url": "test_document.txt",
    "collection_name": "pdf_documents"
  }'

# Ask: "When was Python created?"
```

---

## Common Issues & Fixes

### "Connection refused" on localhost:3000

**Problem**: Frontend can't reach backend
**Solution**:
```bash
# Check if backend is running
docker-compose logs backend

# Check environment
cat backend/.env | grep OPENAI_API_KEY

# If not set, update and restart
docker-compose restart backend
```

### "Collection not found" Error

**Problem**: No documents ingested yet
**Solution**:
```bash
# Ingest a document first
curl -X POST http://localhost:8000/api/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "source_type": "text",
    "path_or_url": "sample.txt",
    "collection_name": "pdf_documents"
  }'

# Verify ingestion worked
curl http://localhost:8000/api/collections
```

### "OPENAI_API_KEY not set"

**Problem**: Missing OpenAI API key
**Solution**:
```bash
# 1. Get key from https://platform.openai.com/api-keys
# 2. Edit backend/.env
nano backend/.env
# 3. Add: OPENAI_API_KEY=sk-...
# 4. Restart
docker-compose restart backend
```

### Out of Memory / Slow Response

**Problem**: Processing large documents
**Solution**:
```bash
# Edit backend/.env
nano backend/.env

# Reduce batch sizes
EMBEDDING_BATCH_SIZE=8  # Was 32
CHUNK_SIZE=500          # Was 1000
```

---

## Next Steps

1. **Customize**: Edit prompts in `backend/app/chains.py`
2. **Add Documents**: Ingest your own PDFs, websites, or text files
3. **Deploy**: Follow [DEPLOYMENT.md](./DEPLOYMENT.md) for production
4. **Integrate**: Use the API for custom applications
5. **Monitor**: Add logging and metrics (see DEPLOYMENT.md)

---

## Getting Help

- **API Documentation**: http://localhost:8000/docs
- **GitHub Issues**: [repo issues page]
- **Discord**: [community link]
- **Email**: support@example.com

See also: [Full README.md](./README.md) | [Deployment Guide](./DEPLOYMENT.md)
