## 🚀 YOUR SETUP IS COMPLETE!

Everything has been installed and configured. Here's how to start your PDF Chatbot:

---

## ⚡ QUICK START (3 Steps)

### **IMPORTANT: Set Your OpenAI API Key First!**

1. Open: `backend\.env`
2. Find this line: `OPENAI_API_KEY=sk-proj-your-key-here-replace-this`
3. Replace it with your actual key from: https://platform.openai.com/api-keys
4. Save the file

---

## 🎯 Method 1: Easy (ONE CLICK - Windows Only)

**Just double-click this file:**
```
start-all.bat
```

This will:
- ✅ Start backend on http://localhost:8000
- ✅ Start frontend on http://localhost:5173
- ✅ Open browser automatically

**Done!** Your chatbot is running!

---

## 🔧 Method 2: Manual (Two Terminals)

### Terminal 1 - Backend

Double-click: `start-backend.bat`

Or manually run:
```powershell
cd backend
.\venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Wait for this message:**
```
INFO:     Application startup complete
```

### Terminal 2 - Frontend

Double-click: `start-frontend.bat`

Or manually run:
```powershell
cd frontend
npm run dev
```

**Wait for this message:**
```
➜  Local:   http://localhost:5173/
```

---

## 🌐 Access Your Chatbot

Once both are running:

| Service | URL |
|---------|-----|
| **Chat UI** | http://localhost:5173 |
| **Backend API** | http://localhost:8000 |
| **API Docs** | http://localhost:8000/docs |

---

## 📚 First Time Setup

### 1. **Add Your OpenAI API Key**
```
backend/.env → OPENAI_API_KEY=sk-...
```

### 2. **Start Services**
```
Double-click: start-all.bat
```

### 3. **Wait for Services to Start**
- Backend should show: "Application startup complete"
- Frontend should show: "Local: http://localhost:5173"

### 4. **Open Browser**
Go to: http://localhost:5173

You should see the chat interface! 🎉

---

## 🧪 Test It

### Ingest a Document

Open PowerShell and run:

```powershell
$body = @{
    source_type = "website"
    path_or_url = "https://en.wikipedia.org/wiki/Artificial_intelligence"
    collection_name = "pdf_documents"
} | ConvertTo-Json

curl -X POST http://localhost:8000/api/ingest `
  -H "Content-Type: application/json" `
  -d $body
```

Wait 30-60 seconds for it to process.

### Ask Questions

1. Go to http://localhost:5173
2. Type: "What is artificial intelligence?"
3. Hit Enter
4. See the answer with sources! 💬

---

## 🛑 Stop Services

Press `Ctrl+C` in either terminal window.

---

## ❌ Troubleshooting

### "Address already in use" Error?

```powershell
# Find what's using the port
netstat -ano | findstr :8000   # For backend
netstat -ano | findstr :5173   # For frontend

# Kill the process
taskkill /PID <number> /F
```

### "OpenAI API Key" Error?

Make sure you edited `backend/.env` and added your key:
```
OPENAI_API_KEY=sk-proj-...
```

Then restart the backend.

### "Cannot find module" Error in Frontend?

```powershell
cd frontend
npm install
npm run dev
```

### Backend won't start?

```powershell
cd backend
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

---

## 📁 What's Running?

| Component | Technology | Port | Status |
|-----------|-----------|------|--------|
| **Frontend** | React + Vite | 5173 | ✅ Dev Server |
| **Backend** | FastAPI + Uvicorn | 8000 | ✅ API Server |
| **Vector DB** | In-Memory (will use Qdrant later) | - | ✅ Ready |

---

## 🎓 Next Steps

1. ✅ Start services (double-click `start-all.bat`)
2. ✅ Ingest a document (see test section above)
3. ✅ Ask questions in the UI
4. ✅ Explore the code in `backend/app/` and `frontend/src/`
5. ✅ Customize prompts, add features, deploy!

---

## 📖 Documentation

- **README.md** - Full project overview
- **QUICKSTART.md** - Detailed setup guide
- **ARCHITECTURE.md** - How everything works
- **DEVELOPMENT.md** - Contributing & adding features
- **DEPLOYMENT.md** - Deploy to cloud

---

## 🎯 Common Commands

```powershell
# Start everything
.\start-all.bat

# Start just backend
.\start-backend.bat

# Start just frontend  
.\start-frontend.bat

# Check if services are running
curl http://localhost:8000/api/health  # Backend
curl http://localhost:5173             # Frontend

# Run tests
cd backend
pytest tests/ -v

# Build for production
cd frontend
npm run build
```

---

## ✨ YOU'RE ALL SET!

Everything is installed and configured. Just:

1. **Add your OpenAI key** to `backend/.env`
2. **Double-click** `start-all.bat`
3. **Visit** http://localhost:5173

Enjoy your PDF Chatbot! 🚀

---

**Need help?** Check QUICKSTART.md or DEVELOPMENT.md for more details.
