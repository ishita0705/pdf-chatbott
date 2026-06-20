# Deploy PDF Chatbot Online (not localhost)

Yes — you can deploy this app on the internet. Below are practical options from easiest to more control.

## What gets deployed

| Piece | Role |
|-------|------|
| **Frontend** | React chat UI |
| **Backend** | FastAPI + LangChain + embeddings |
| **Qdrant** | Vector database (your uploaded PDFs) |
| **nginx** (prod compose) | One public URL for UI + API |

**Recommended mode:** `LLM_PROVIDER=extractive` (free, no OpenAI billing).

---

## Option 1: VPS + Docker (recommended)

Best for a **single link** like `http://YOUR_SERVER_IP` or your own domain.

### Requirements

- A Linux server (Ubuntu 22.04) with **2 GB+ RAM** (embeddings need memory)
- Docker + Docker Compose installed
- Ports **80** (and **443** if you add HTTPS) open in firewall

### Providers (examples)

- [DigitalOcean](https://www.digitalocean.com/) — Droplet from ~$6/mo  
- [Oracle Cloud](https://www.oracle.com/cloud/free/) — free tier VM  
- [Hetzner](https://www.hetzner.com/) — cheap VPS  

### Steps

1. Copy the project to the server (git clone or upload).
2. On the server:

```bash
cd pdf-chatbot
docker compose -f docker-compose.prod.yml up -d --build
```

3. Open in browser: `http://YOUR_SERVER_IP`
4. First start may take **3–5 minutes** (downloads embedding model).

### Custom domain + HTTPS (optional)

Point your domain A-record to the server IP, then use [Caddy](https://caddyserver.com/) or [Certbot](https://certbot.eff.org/) in front of nginx for free SSL.

---

## Option 2: Render (no server management)

Split into two services on [Render](https://render.com):

### A) Backend (Web Service)

- **Build:** Docker, context `backend`, Dockerfile `backend/Dockerfile`
- **Env vars:**
  - `LLM_PROVIDER=extractive`
  - `EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2`
  - `QDRANT_URL=<your-qdrant-cloud-url>` or run Qdrant on another Render service
  - `CORS_ORIGINS=["https://YOUR-FRONTEND.onrender.com"]`
- **Plan:** at least **512 MB–1 GB RAM** (2 GB safer for embeddings)

### B) Frontend (Static Site)

- **Build command:** `cd frontend && npm install && npm run build`
- **Publish directory:** `frontend/dist`
- **Env (build time):**
  - `VITE_API_URL=https://YOUR-BACKEND.onrender.com`

### Qdrant on Render

Use [Qdrant Cloud](https://cloud.qdrant.io/) free tier, or add a Qdrant Docker service on the same platform with a persistent disk.

---

## Option 3: Railway

1. Push code to GitHub.
2. [Railway](https://railway.app/) → New Project → Deploy from repo.
3. Deploy **backend** from `backend/Dockerfile`.
4. Deploy **frontend** with build args `VITE_API_URL` = your Railway backend URL.
5. Add **Qdrant** plugin or Qdrant Cloud URL in `QDRANT_URL`.

---

## Environment variables (production)

| Variable | Example | Notes |
|----------|---------|--------|
| `LLM_PROVIDER` | `extractive` | Free; no API key |
| `EMBEDDING_MODEL` | `sentence-transformers/all-MiniLM-L6-v2` | Local embeddings |
| `QDRANT_URL` | `http://qdrant:6333` (Docker) | Vector DB |
| `VITE_API_URL` | `` empty or backend URL | Set at **frontend build** |
| `CORS_ORIGINS` | `["https://your-site.com"]` | Only if UI and API are on different domains |

---

## Local vs production

| | Local (`start-all.bat`) | Production (`docker-compose.prod.yml`) |
|--|-------------------------|----------------------------------------|
| URL | `localhost:3000` | `http://your-server` |
| API | `localhost:8000` | Same host `/api/` via nginx |
| Data | On your PC | Server volumes (Qdrant + uploads) |

---

## Before you go public

1. **Do not commit** `backend/.env` (API keys).
2. Add **HTTPS** for anything beyond personal testing.
3. Expect **cold starts** on free hosting (slow first request).
4. Uploaded PDFs stay on the server — add auth if you share the link widely.

---

## Quick test production build locally

```bash
docker compose -f docker-compose.prod.yml up --build
```

Then open **http://localhost** (port 80, not 3000).

---

## Need help choosing?

| Goal | Pick |
|------|------|
| Cheapest long-term, one URL | VPS + `docker-compose.prod.yml` |
| Easiest, no Linux | Render or Railway |
| Stay 100% free | Oracle free VM + Docker, or Render free tier (may sleep) |

If you tell me which platform you prefer (Render, Railway, DigitalOcean, etc.), we can add a platform-specific config file next.
