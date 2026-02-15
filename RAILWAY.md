# Railway Configuration Quick Reference

This document provides Railway-specific configuration for deploying OpenClaw.

## Service 1: LinkedIn Scraper

### Service Configuration
- **Name**: `linkedin-scraper`
- **Root Directory**: `linkedin-scraper`
- **Build Method**: Dockerfile
- **Dockerfile Path**: `linkedin-scraper/Dockerfile`

### Environment Variables
```
PORT=3000
```

### Networking
- Enable public networking
- Generate domain (e.g., `linkedin-scraper-production.up.railway.app`)

### Resources
- **Memory**: 512MB - 1GB recommended
- **CPU**: Shared (default)

### Health Check (Optional)
- **Path**: `/health`
- **Interval**: 30s

---

## Service 2: OpenClaw

### Service Configuration
- **Name**: `openclaw`
- **Root Directory**: `.` (project root)
- **Build Method**: Dockerfile
- **Dockerfile Path**: `Dockerfile`

### Environment Variables
```
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
OPENCLAW_GATEWAY_TOKEN=<generate-random-token>
TAVILY_API_KEY=tvly-xxxxx
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
SLACK_BOT_TOKEN=xoxb-xxxxx
SLACK_APP_TOKEN=xapp-xxxxx
SLACK_ALLOWED_CHANNEL=C1234567890
LINKEDIN_SCRAPER_URL=https://<your-linkedin-scraper>.up.railway.app
```

### Networking
- Enable public networking (optional, for web UI)
- Generate domain if you want web access
- Port: 18789

### Resources
- **Memory**: 256MB - 512MB recommended
- **CPU**: Shared (default)

---

## Deployment Workflow

### Using Railway CLI

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Link to project
railway link

# Deploy LinkedIn Scraper
railway up -s linkedin-scraper

# Deploy OpenClaw
railway up -s openclaw

# View logs
railway logs -s openclaw
railway logs -s linkedin-scraper
```

### Using GitHub Integration

1. **Connect Repository**
   - Go to Railway dashboard
   - New Project → Deploy from GitHub
   - Select `swapnil-agrim/openclaw`

2. **Configure Services**
   - Railway will detect Dockerfile
   - Create two services with different root directories

3. **Set Environment Variables**
   - Navigate to each service
   - Variables tab → Add variables
   - Paste from `.env.example`

4. **Deploy**
   - Push to main branch
   - Railway auto-deploys on git push

---

## Railway Tips

### Cost Optimization

1. **Use Shared CPU**: Sufficient for most workloads
2. **Right-size Memory**: Start with 512MB, scale if needed
3. **Monitor Usage**: Check Railway dashboard for metrics
4. **Hobby Plan**: $5/month includes $5 credit

### Debugging

**View Logs in Real-time:**
```bash
railway logs -s openclaw --follow
```

**SSH into Container:**
```bash
railway shell -s openclaw
```

**Check Build Logs:**
- Dashboard → Service → Deployments → Build Logs

**Common Build Issues:**
- npm install failures: Check Node.js version compatibility
- Dockerfile errors: Verify COPY paths are correct
- Port binding: Ensure PORT env var matches EXPOSE

### Environment Variables Best Practices

1. **Never commit secrets**: Use `.gitignore` for `.env`
2. **Use Railway's UI**: More secure than CLI for secrets
3. **Reference other services**: Use Railway's internal URLs
4. **Update variables**: Redeploy after changing env vars

### Networking

**Internal Communication (Service-to-Service):**
```
http://<service-name>.railway.internal:PORT
```

**External Access:**
```
https://<generated-domain>.up.railway.app
```

**Custom Domains:**
- Settings → Networking → Custom Domain
- Add CNAME record: `<your-subdomain>` → `<railway-domain>`

---

## Volumes (Optional)

For persistent LinkedIn session across deployments:

### LinkedIn Scraper with Volume

1. **Create Volume**:
   - Service → Settings → Volumes
   - Add Volume
   - Mount Path: `/data`

2. **Update Code**:
   ```javascript
   // In linkedin-scraper/index.js
   const SESSION_FILE = '/data/linkedin-session.json';
   ```

3. **Redeploy**:
   - Railway will persist `/data` across deployments

---

## Monitoring

### Railway Dashboard Metrics

- **CPU Usage**: Target < 80% average
- **Memory Usage**: Target < 80% of allocated
- **Network**: Inbound/outbound traffic
- **Deployments**: Success/failure rate

### Custom Monitoring

**Uptime Monitoring:**
- Use UptimeRobot or similar
- Monitor: `https://<service>.railway.app/health`

**Log Aggregation:**
- Railway logs are searchable in dashboard
- Export logs via CLI: `railway logs > logs.txt`

---

## Scaling

### Vertical Scaling (Single Instance)

1. Settings → Resources
2. Increase Memory/CPU
3. Redeploy

### Horizontal Scaling (Multiple Instances)

Railway supports horizontal scaling on Pro plans:
- Settings → Replicas
- Increase replica count
- Load balancing handled automatically

---

## Backup and Recovery

### Export Configuration

```bash
# Export environment variables
railway variables -s openclaw > openclaw-vars.txt
railway variables -s linkedin-scraper > scraper-vars.txt
```

### Disaster Recovery

1. **Repository**: Code is in GitHub (version controlled)
2. **Environment Variables**: Export via CLI (see above)
3. **LinkedIn Session**: Use volumes for persistence
4. **Database**: Not applicable (stateless services)

### Restore Procedure

1. Create new Railway project
2. Deploy from GitHub
3. Import environment variables
4. Re-authenticate LinkedIn scraper

---

## Railway.json (Optional)

Create `railway.json` in project root for advanced configuration:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "/entrypoint.sh",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 300,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

---

## Support

**Railway Documentation**: https://docs.railway.app
**Railway Discord**: https://discord.gg/railway
**Railway Status**: https://status.railway.app

---

## Checklist

### Pre-Deployment
- [ ] GitHub repository connected
- [ ] Dockerfile tested locally
- [ ] Environment variables prepared
- [ ] API keys obtained (Anthropic, Tavily, Telegram, Slack)

### LinkedIn Scraper Deployment
- [ ] Service created with correct root directory
- [ ] PORT environment variable set
- [ ] Domain generated
- [ ] Health check passing
- [ ] Authenticated with LinkedIn

### OpenClaw Deployment
- [ ] Service created with correct root directory
- [ ] All environment variables set
- [ ] LINKEDIN_SCRAPER_URL points to scraper service
- [ ] Domain generated (if needed)
- [ ] Telegram bot responding
- [ ] Slack bot responding

### Post-Deployment
- [ ] Test all integrations
- [ ] Monitor logs for errors
- [ ] Set up uptime monitoring
- [ ] Document service URLs
- [ ] Bookmark Railway dashboard

---

**Railway Configuration Complete! 🚂**
