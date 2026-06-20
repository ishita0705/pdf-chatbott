# How to run PDF Chatbot (upload + ask questions)

## What it does

1. **Upload** a PDF or TXT file
2. The app **reads and indexes** the text (saved on disk in `backend/data/qdrant`)
3. **Ask any question** in the chat — answers use your document + show sources

## One-time setup

1. Install **Python 3.10+** and **Node 18+**
2. Backend:
   ```powershell
   cd backend
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```
3. Copy config (if `backend\.env` is missing):
   ```powershell
   copy .env.backup .env
   ```
4. Edit `backend\.env` — set your **OPENAI_API_KEY** (required for answers)
5. Frontend:
   ```powershell
   cd ..\frontend
   npm install
   ```

## Start the app

**Easiest:** double-click `start-all.bat` in the project folder.

**Or manually** — two terminals:

Terminal 1 (backend):
```powershell
cd backend
.\venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Terminal 2 (frontend):
```powershell
cd frontend
npm run dev
```

Open in browser: **http://localhost:3000** or **http://localhost:3001**

## How to use

1. Expand **Upload document**
2. Drop your PDF or TXT file — wait for green success message
3. Type a question (e.g. "Summarize this document") and press Enter
4. Read the answer and expand **Sources** for citations

## Troubleshooting

| Problem | Fix |
|--------|-----|
| "No documents indexed" | Upload a file first; wait for success message |
| OpenAI error | Check `OPENAI_API_KEY` in `backend\.env` |
| Connection refused | Start backend (port 8000) and frontend (3000/3001) |
| Upload works, chat fails | Restart backend after changing `.env` |

Embeddings run **locally** (free). Only **chat answers** use OpenAI (small cost per question).
