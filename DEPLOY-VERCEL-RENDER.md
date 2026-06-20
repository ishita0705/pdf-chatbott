# Deploy: Vercel (UI) + Render (API + Qdrant)

No Linux on your PC. No Azure subscription needed.

| Part | Platform | URL example |
|------|----------|-------------|
| React UI | **Vercel** | `https://pdf-chatbot.vercel.app` |
| FastAPI API | **Render** | `https://pdf-chatbot-api.onrender.com` |
| Vector DB | **Render** (private) | internal only |

---

## Before you start

1. **GitHub account** — push this project to a repo
2. **Vercel account** — [vercel.com](https://vercel.com) (free, sign in with GitHub)
3. **Render account** — [render.com](https://render.com) (free tier available; **Starter ~$7/mo recommended** for API RAM)

> The API loads an embedding model (~500MB+ RAM). Render **free (512MB) may fail**. Use **Starter** plan for `pdf-chatbot-api`.

---

## Part 1 — Deploy backend on Render (~10 min)

### Step 1: Push code to GitHub

If not already:

```powershell
cd C:\Users\itl\Desktop\Projects\pdf-chatbot
git init
git add .
git commit -m "PDF chatbot with Vercel + Render deploy config"
git remote add origin https://github.com/YOUR_USERNAME/pdf-chatbot.git
git push -u origin main
```

(Do **not** commit `backend/.env` — it should stay in `.gitignore`.)

### Step 2: Create Render services from Blueprint

1. Go to [dashboard.render.com](https://dashboard.render.com)
2. **New** → **Blueprint**
3. Connect your **GitHub** repo `pdf-chatbot`
4. Render reads `render.yaml` and creates:
   - `pdf-chatbot-qdrant` (private)
   - `pdf-chatbot-api` (public web)
5. Click **Apply** — wait **15–25 min** (first Docker build is slow)

### Step 3: Copy your API URL

When deploy finishes, open service **pdf-chatbot-api** → copy URL, e.g.:

```
https://pdf-chatbot-api.onrender.com
```

Test in browser: `https://YOUR-API.onrender.com/api/health`  
Should return `{"status":"healthy",...}`

### Step 4: Set CORS (after Vercel — step 2 below)

You will update `CORS_ORIGINS` on Render after you know your Vercel URL.

---

## Part 2 — Deploy frontend on Vercel (~5 min)

### Step 1: Import project

1. Go to [vercel.com/new](https://vercel.com/new)
2. Import your **GitHub** repo
3. Configure:

| Setting | Value |
|---------|--------|
| **Root Directory** | `frontend` |
| **Framework Preset** | Vite |
| **Build Command** | `npm run build` |
| **Output Directory** | `dist` |

### Step 2: Environment variable (required)

Add **before** first deploy:

| Name | Value |
|------|--------|
| `VITE_API_URL` | `https://pdf-chatbot-api.onrender.com` |

Use your **actual Render API URL** (no trailing slash).

### Step 3: Deploy

Click **Deploy**. When done, copy your Vercel URL, e.g.:

```
https://pdf-chatbot-xyz.vercel.app
```

---

## Part 3 — Connect frontend ↔ backend

### On Render (API service)

1. Open **pdf-chatbot-api** → **Environment**
2. Edit `CORS_ORIGINS`:

```json
["https://pdf-chatbot-xyz.vercel.app"]
```

Replace with your real Vercel URL.

3. **Save Changes** — Render redeploys automatically.

### Test

1. Open your **Vercel URL**
2. Upload a PDF
3. Ask a question (first reply may take **1–2 min** on cold start)

---

## Resume bullet

> Deployed full-stack RAG PDF chatbot with **React on Vercel** and **FastAPI + Qdrant on Render**; configured CORS, Dockerized API, and environment-based production settings.

Add both URLs to your GitHub README.

---

## Costs

| Service | Plan | Approx |
|---------|------|--------|
| Vercel | Hobby (free) | $0 |
| Render API | Starter | ~$7/mo |
| Render Qdrant | Starter | ~$7/mo |
| **Total** | | **~$14/mo** (or try free API — may OOM) |

Render free tier **spins down** after idle — first visit wakes slowly (~30–60s).

---

## Update after code changes

| What changed | Action |
|--------------|--------|
| Backend code | Push to GitHub → Render auto-redeploys |
| Frontend code | Push to GitHub → Vercel auto-redeploys |
| New Vercel URL | Update `CORS_ORIGINS` on Render |
| New Render API URL | Update `VITE_API_URL` on Vercel → Redeploy |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| UI loads, chat fails / CORS error | Set `CORS_ORIGINS` on Render to exact Vercel URL (`https://...`) |
| Upload fails | Check API URL in Vercel env; API must be awake |
| API crash / OOM | Upgrade `pdf-chatbot-api` to **Starter 2GB** on Render |
| Slow first request | Render cold start + model load — normal on free/starter |
| `502` on Render | Check logs; first build can take 20+ min |

---

## Optional: Railway instead of Render

Same idea: deploy `backend/Dockerfile` + Qdrant on Railway, set `VITE_API_URL` on Vercel to Railway URL.

---

## Local dev (unchanged)

```powershell
# Windows — still use
.\start-all.bat
```

Production uses Vercel + Render; local stays on `localhost`.
