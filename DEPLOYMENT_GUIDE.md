# Deployment Guide - Supabase Integration

## Pre-Deployment Checklist

### Local Testing
- [ ] Server starts: `npm run dev`
- [ ] Health check works: `curl http://localhost:3000/health/detailed`
- [ ] PostgreSQL connected: health shows `"postgresql": "connected"`
- [ ] Supabase connected: health shows `"supabase": "connected"`
- [ ] Can create poll in UI
- [ ] Can submit vote in UI
- [ ] Can view poll results
- [ ] Chat functionality works
- [ ] Student can be kicked

### Database Verification
- [ ] Supabase tables created:
  - [ ] `polls` table exists
  - [ ] `options` table exists
  - [ ] `votes` table exists
- [ ] Indexes created for performance
- [ ] RLS policies configured
- [ ] No data corruption in dev DB

### Code Review
- [ ] No hardcoded credentials
- [ ] Environment variables properly set
- [ ] Error handling in place
- [ ] Logging configured
- [ ] TypeScript compiles without errors

---

## Deployment Environments

### 1. Development (Local)
```env
DATABASE_URL=file:./dev.db
SUPABASE_URL=https://buhmyduesbhylnmlbigp.supabase.co
SUPABASE_KEY=sb_publishable_7FeoBYaEwKXJK5d33t8gpw_ToMjWLQ
PORT=3000
NODE_ENV=development
```

### 2. Staging
```env
DATABASE_URL=postgresql://user:password@host:5432/polling_stage
SUPABASE_URL=https://[staging-project].supabase.co
SUPABASE_KEY=sb_publishable_[staging-key]
PORT=3000
NODE_ENV=staging
```

### 3. Production
```env
DATABASE_URL=postgresql://user:password@host:5432/polling_prod
SUPABASE_URL=https://[prod-project].supabase.co
SUPABASE_KEY=sb_publishable_[prod-key]
PORT=3000
NODE_ENV=production
```

---

## Step-by-Step Deployment

### Step 1: Prepare Supabase Project

```bash
# 1. Log in to https://supabase.com
# 2. Create new project or use existing
# 3. Wait for project to be ready
# 4. Get credentials from:
#    - Settings → API
#    - Copy: Project URL (SUPABASE_URL)
#    - Copy: anon/public key (SUPABASE_KEY)
```

### Step 2: Set Up Database Schema

**Via Supabase SQL Editor:**
```sql
-- Copy from setup-supabase.ps1 or setup-supabase.sh
-- Execute the full SQL in Supabase dashboard
```

**Verify tables:**
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
-- Should return: polls, options, votes
```

### Step 3: Configure Environment Variables

**On your deployment server:**

```bash
# Create .env in server directory
cat > .env << EOF
DATABASE_URL="postgresql://user:password@host:5432/polling"
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=sb_publishable_your_key_here
PORT=3000
NODE_ENV=production
EOF
```

### Step 4: Build Application

```bash
# Navigate to server directory
cd server

# Install dependencies
npm install --production

# Build TypeScript
npm run build

# Verify build succeeded
ls -la dist/
```

### Step 5: Run Database Migrations

```bash
# Update PostgreSQL schema
npx prisma db push --accept-data-loss

# Verify Prisma schema matches
npx prisma generate
```

### Step 6: Start Server

```bash
# Start application
npm start

# Or use PM2 for production
pm2 start dist/index.js --name "polling-server"
pm2 save
```

### Step 7: Verify Deployment

```bash
# Check health
curl http://your-server/health/detailed

# Expected response
{
  "status": "ok",
  "postgresql": "connected",
  "supabase": "connected",
  "timestamp": "2026-01-09T10:30:45.123Z"
}

# Check server logs
pm2 logs polling-server
```

---

## Deployment Platform Guides

### Render.com (Recommended)

**1. Create PostgreSQL Database:**
```bash
# In Render dashboard:
# 1. Click "New +" → PostgreSQL
# 2. Set name: "polling-db"
# 3. Save connection string
```

**2. Deploy Backend:**
```bash
# 1. Click "New +" → Web Service
# 2. Connect GitHub repository
# 3. Set Build Command: npm install && npm run build
# 4. Set Start Command: npm start
# 5. Add Environment Variables:
#    - DATABASE_URL: [from PostgreSQL]
#    - SUPABASE_URL: [from Supabase]
#    - SUPABASE_KEY: [from Supabase]
# 6. Deploy
```

**3. Deploy Frontend:**
```bash
# 1. Click "New +" → Static Site
# 2. Connect GitHub repository (client folder)
# 3. Set Build Command: npm run build
# 4. Set Publish Directory: dist
# 5. Add Environment Variable:
#    - VITE_API_URL: [from Backend Web Service]
# 6. Deploy
```

### AWS EC2

**1. SSH into instance:**
```bash
ssh -i key.pem ec2-user@your-instance.amazonaws.com
```

**2. Install Node.js:**
```bash
sudo yum update -y
sudo yum install -y nodejs npm
```

**3. Clone repository:**
```bash
git clone https://github.com/your-repo/polling-system.git
cd polling-system/server
```

**4. Set up environment:**
```bash
# Create .env file
sudo nano .env
# Paste environment variables
```

**5. Install and run:**
```bash
npm install
npm run build
npm start
```

**6. Set up reverse proxy (nginx):**
```bash
sudo yum install -y nginx
sudo nano /etc/nginx/conf.d/polling.conf
```

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }
}
```

**7. Start services:**
```bash
sudo systemctl restart nginx
pm2 start npm -- start
pm2 save
```

### Docker Deployment

**1. Create Dockerfile:**
```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
```

**2. Create docker-compose.yml:**
```yaml
version: '3.8'
services:
  server:
    build: ./server
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: ${DATABASE_URL}
      SUPABASE_URL: ${SUPABASE_URL}
      SUPABASE_KEY: ${SUPABASE_KEY}
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: polling
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

**3. Deploy:**
```bash
docker-compose up -d
```

---

## Post-Deployment Verification

### Health Checks

```bash
# 1. Basic health
curl https://your-server/health

# 2. Detailed health with database status
curl https://your-server/health/detailed

# 3. Check both databases connected
# Response should show:
# "postgresql": "connected"
# "supabase": "connected"
```

### Functional Tests

```bash
# 1. Test API endpoint
curl https://your-server/api/polls/current

# 2. Test poll creation (via UI or API)
# Check both PostgreSQL and Supabase have data

# 3. Monitor logs for sync
# Should see: "[Sync] Poll synced to Supabase: ..."
```

### Load Testing

```bash
# Basic load test with Apache Bench
ab -n 100 -c 10 https://your-server/health/detailed

# More advanced: Artillery
npm install -g artillery
artillery run load-test.yml
```

---

## Monitoring & Alerts

### Set Up Monitoring

```bash
# 1. Monitor health endpoint every 5 minutes
# 2. Alert if supabase: "disconnected" for > 10 minutes
# 3. Alert if postgresql: "disconnected" immediately
# 4. Track response times for /api/polls
# 5. Monitor disk usage on PostgreSQL
```

### Log Aggregation

**CloudWatch (AWS):**
```bash
# Install CloudWatch agent
# Send logs to: /var/log/polling-server.log
```

**ELK Stack:**
```bash
# Send logs to Elasticsearch
# Query with Kibana dashboard
```

---

## Rollback Procedure

### If Something Goes Wrong

```bash
# 1. Check health endpoint first
curl https://your-server/health/detailed

# 2. Check server logs
pm2 logs polling-server

# 3. If Supabase is down:
#    - Continue serving from PostgreSQL
#    - Supabase will sync when recovered
#    - No user-facing impact

# 4. If PostgreSQL is down:
#    - Immediate rollback required
#    - Restore from backup

# 5. Rollback steps:
git log --oneline
git revert <commit-hash>
npm run build
npm start
pm2 restart polling-server
```

---

## Backup & Recovery

### Automated Backups

**PostgreSQL:**
```bash
# Daily backup
0 2 * * * pg_dump $DATABASE_URL > /backups/polling_$(date +\%Y\%m\%d).sql
```

**Supabase:**
```bash
# Automatic daily backups via Supabase dashboard
# Settings → Database → Backups
# Retention: 14 days (default)
```

### Recovery Procedure

```bash
# 1. Restore PostgreSQL
psql $DATABASE_URL < /backups/polling_20260109.sql

# 2. Restore Supabase
# Via dashboard: Settings → Database → Backups
# Select restore point and confirm

# 3. Restart servers
pm2 restart all
```

---

## Security Checklist

- [ ] Environment variables NOT in git (use .env)
- [ ] `SUPABASE_KEY` is publishable key (not secret)
- [ ] HTTPS enabled on all endpoints
- [ ] CORS properly configured
- [ ] Rate limiting implemented
- [ ] SQL injection prevention (using ORM)
- [ ] XSS protection enabled
- [ ] Database backups encrypted
- [ ] Access logs monitored
- [ ] Secrets rotated quarterly

---

## Performance Optimization

### Database Indexes
Already included in Supabase setup:
```sql
CREATE INDEX idx_polls_status ON public.polls(status);
CREATE INDEX idx_options_poll_id ON public.options(poll_id);
CREATE INDEX idx_votes_poll_id ON public.votes(poll_id);
CREATE INDEX idx_votes_option_id ON public.votes(option_id);
```

### Caching Strategy
```typescript
// Future: Add Redis caching
// Cache active poll: 30 seconds
// Cache poll history: 5 minutes
```

### Database Connection Pooling
```bash
# Render automatically provides connection pooling
# AWS: Use AWS RDS Proxy
# Manual: pgBouncer
```

---

## Maintenance Schedule

### Daily
- [ ] Check health endpoint
- [ ] Monitor error logs
- [ ] Verify both databases connected

### Weekly
- [ ] Review performance metrics
- [ ] Check disk usage
- [ ] Verify backup completion

### Monthly
- [ ] Review and rotate secrets
- [ ] Update dependencies
- [ ] Database maintenance (VACUUM, ANALYZE)

### Quarterly
- [ ] Security audit
- [ ] Performance review
- [ ] Disaster recovery test

---

## Support & Troubleshooting

### Common Issues

**Issue: Supabase shows disconnected**
- [ ] Verify credentials in .env
- [ ] Check Supabase project status
- [ ] Restart server

**Issue: Polls not syncing to Supabase**
- [ ] Check Supabase tables exist
- [ ] Verify RLS policies allow writes
- [ ] Check server logs for errors

**Issue: High latency**
- [ ] Check database connection pooling
- [ ] Monitor sync service performance
- [ ] Review query performance

---

## Contacts & Resources

| Topic | Resource |
|-------|----------|
| Supabase Support | https://supabase.com/support |
| PostgreSQL Docs | https://www.postgresql.org/docs |
| Render.com Docs | https://render.com/docs |
| AWS Support | https://aws.amazon.com/support |

---

**Document Version:** 1.0  
**Last Updated:** January 9, 2026  
**Status:** Production Ready ✅
