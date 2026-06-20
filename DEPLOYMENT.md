## Deployment Guide

This guide covers deploying the PDF Chatbot to production on various platforms.

### Prerequisites

- Docker & Docker Compose
- Cloud provider account (GCP, AWS, Azure, or DigitalOcean)
- OpenAI API key (or alternative LLM API key)
- Domain name (optional but recommended)

---

## Option 1: Docker Host (Self-Hosted)

Suitable for: Small teams, on-premises, testing environments

### Setup

```bash
# 1. Clone repo
git clone <repo>
cd pdf-chatbot

# 2. Copy and configure env
cp backend/.env.example backend/.env
# Edit backend/.env with your OpenAI API key
# OPENAI_API_KEY=sk-...

# 3. Build and run
docker-compose up -d

# 4. Check status
docker-compose logs -f
```

### Monitoring

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs backend
docker-compose logs frontend

# Restart a service
docker-compose restart backend
```

### Backup

```bash
# Backup Qdrant vector DB
docker run --volumes-from pdf-chatbot-qdrant \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/qdrant-$(date +%Y%m%d).tar.gz -C /qdrant/storage .

# Restore from backup
docker run --volumes-from pdf-chatbot-qdrant \
  -v $(pwd)/backups:/backup \
  alpine tar xzf /backup/qdrant-20240101.tar.gz -C /qdrant/storage
```

---

## Option 2: Google Cloud Run (Serverless)

Suitable for: Startups, variable traffic, cost-conscious deployments

### Setup Backend

```bash
# 1. Build image
gcloud builds submit --tag gcr.io/PROJECT_ID/pdf-chatbot-backend ./backend

# 2. Deploy to Cloud Run
gcloud run deploy pdf-chatbot-backend \
  --image gcr.io/PROJECT_ID/pdf-chatbot-backend \
  --platform managed \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --set-env-vars OPENAI_API_KEY=sk-... \
  --set-env-vars QDRANT_URL=https://your-qdrant-instance.com \
  --allow-unauthenticated

# 3. Note the service URL
# You'll use this in frontend config
```

### Setup Vector DB (Qdrant Cloud)

```bash
# 1. Create Qdrant account at https://cloud.qdrant.io
# 2. Create a cluster (free tier available)
# 3. Get the API URL and key
# 4. Update backend env vars with QDRANT_URL and QDRANT_API_KEY
```

### Setup Frontend

```bash
# 1. Deploy to Firebase Hosting (free tier available)
cd frontend
npm run build
firebase deploy

# OR deploy to Cloud Run
gcloud builds submit --tag gcr.io/PROJECT_ID/pdf-chatbot-frontend ./frontend
gcloud run deploy pdf-chatbot-frontend \
  --image gcr.io/PROJECT_ID/pdf-chatbot-frontend \
  --platform managed \
  --region us-central1 \
  --set-env-vars VITE_API_URL=https://pdf-chatbot-backend-xxx.a.run.app \
  --allow-unauthenticated
```

### Cost Estimation (Google Cloud)

- Cloud Run (backend): ~$0.25/month (1M requests free tier)
- Cloud Run (frontend): ~$0.50/month (mostly free tier)
- Qdrant Cloud: Free tier + ~$10/month for prod
- **Total**: ~$10-15/month

---

## Option 3: AWS EC2 (IaaS)

Suitable for: Enterprise, complex requirements, existing AWS customers

### Setup

```bash
# 1. Launch EC2 instance (Ubuntu 22.04 LTS)
# - Type: t3.medium (2vCPU, 4GB RAM)
# - Storage: 50GB
# - Security group: Allow 80, 443, 22

# 2. SSH into instance
ssh -i your-key.pem ubuntu@your-instance-ip

# 3. Install Docker
sudo apt update && sudo apt install -y docker.io docker-compose

# 4. Clone repo and setup
git clone <repo>
cd pdf-chatbot
cp backend/.env.example backend/.env
# Edit .env

# 5. Run
docker-compose up -d

# 6. Setup reverse proxy (Nginx)
sudo apt install -y nginx

# Configure /etc/nginx/sites-available/default
# See Nginx config section below

# 7. Setup SSL with Let's Encrypt
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### Nginx Reverse Proxy Config

```nginx
upstream backend {
    server localhost:8000;
}

upstream frontend {
    server localhost:3000;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # Frontend
    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # API
    location /api {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

### Cost Estimation (AWS)

- EC2 t3.medium: ~$35/month
- EBS storage (50GB): ~$5/month
- Data transfer: Minimal for normal usage
- **Total**: ~$40-50/month

---

## Option 4: DigitalOcean App Platform

Suitable for: Developers, simple deployments, good documentation

### Setup

```bash
# 1. Install doctl
brew install doctl
doctl auth init

# 2. Create app config
cat > app.yaml << EOF
name: pdf-chatbot
services:
- name: backend
  github:
    repo: YOUR_REPO
    branch: main
  build_command: cd backend && pip install -r requirements.txt
  run_command: uvicorn app.main:app --host 0.0.0.0 --port 8000
  envs:
  - key: OPENAI_API_KEY
    value: ${OPENAI_API_KEY}
  http_port: 8000

- name: frontend
  github:
    repo: YOUR_REPO
    branch: main
  build_command: cd frontend && npm install && npm run build
  run_command: npm run build && serve -s dist
  http_port: 3000

- name: qdrant
  image:
    registry: docker.io
    repository: qdrant/qdrant
  http_port: 6333
EOF

# 3. Deploy
doctl apps create --spec app.yaml
```

### Cost Estimation (DigitalOcean)

- App Platform: $5-12/month (per service)
- Database: ~$15/month (if needed)
- **Total**: ~$35-50/month

---

## Monitoring & Observability

### Logs

```bash
# Tail logs in real-time
docker-compose logs -f backend

# Export logs to file
docker-compose logs backend > backend.log

# With timestamps
docker-compose logs backend --timestamps
```

### Metrics & Alerts

```bash
# Setup Prometheus (optional)
docker pull prom/prometheus
# Create prometheus.yml config
# Add scrape target: http://localhost:8000/metrics

# Setup Grafana for dashboards
docker run -d \
  -p 3001:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana
```

### Error Tracking

```bash
# Add Sentry integration (optional)
pip install sentry-sdk

# In backend/app/main.py:
import sentry_sdk
sentry_sdk.init("your-sentry-dsn")
```

---

## Scaling

### Horizontal Scaling (Multiple Backend Instances)

```yaml
# docker-compose with multiple backend instances
backend-1:
  build: ./backend
  environment:
    - ...

backend-2:
  build: ./backend
  environment:
    - ...

load-balancer:
  image: haproxy
  ports:
    - "8000:8000"
```

### Caching Layer

```bash
# Add Redis for caching
docker run -d -p 6379:6379 redis:alpine

# Configure backend to use Redis:
# CACHE_URL=redis://localhost:6379
```

### Database Optimization

- Index frequently searched metadata fields in Qdrant
- Enable pagination for large result sets
- Archive old conversations to cold storage

---

## Maintenance

### Regular Tasks

```bash
# Weekly: Check logs for errors
docker-compose logs --since 7d | grep ERROR

# Monthly: Update dependencies
pip list --outdated
npm outdated

# Quarterly: Full backup
./scripts/backup.sh
```

### Disaster Recovery

```bash
# 1. Backup all data
docker-compose exec qdrant tar czf /backup/qdrant.tar.gz /qdrant/storage

# 2. Export database metadata
docker-compose exec backend python -c "
from app.vectordb import vector_db
collections = vector_db.client.get_collections()
print(collections)
"

# 3. Store in secure location (S3, GCS, etc.)
aws s3 cp backup.tar.gz s3://my-backup-bucket/
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs pdf-chatbot-backend

# Verify environment
docker inspect pdf-chatbot-backend | grep -A 20 Env

# Rebuild image
docker-compose build --no-cache backend
```

### High Memory Usage

```bash
# Monitor real-time
docker stats

# Reduce model size or batch size in config
EMBEDDING_BATCH_SIZE=8  # Lower from 32
```

### API Timeout

```bash
# Increase timeout in nginx
proxy_connect_timeout 30s;
proxy_send_timeout 30s;
proxy_read_timeout 30s;

# Or increase in FastAPI
# Add timeout parameter to requests
```

---

## Security Checklist

- [ ] Set strong database passwords
- [ ] Enable HTTPS/SSL
- [ ] Setup firewall rules (restrict to known IPs if possible)
- [ ] Enable authentication (OAuth, JWT)
- [ ] Rotate API keys regularly
- [ ] Enable audit logging
- [ ] Backup sensitive data encrypted
- [ ] Monitor for intrusions
- [ ] Keep dependencies updated
- [ ] Use environment variables for secrets (not in code)

---

## Support & Troubleshooting

For detailed support:
- GitHub Issues: [Link to repo]
- Discord Community: [Link]
- Email: support@example.com

See also: [Main README.md](../README.md)
