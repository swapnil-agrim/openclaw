# OpenClaw Railway Deployment Guide

Complete deployment guide for OpenClaw with Tavily search, SearXNG fallback, and LinkedIn scraper integration.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Railway Platform                        │
│                                                             │
│  ┌──────────────────────┐      ┌────────────────────────┐  │
│  │  OpenClaw Service    │      │ LinkedIn Scraper       │  │
│  │                      │◄────►│ Service                │  │
│  │ - Telegram Bot       │      │                        │  │
│  │ - Slack Bot          │      │ - Playwright Browser   │  │
│  │ - Tavily Search      │      │ - Session Persistence  │  │
│  │ - SearXNG Fallback   │      │ - Rate Limiting        │  │
│  │ - LinkedIn Research  │      │                        │  │
│  └──────────────────────┘      └────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Part 1: Deploy LinkedIn Scraper Service

### Step 1: Create New Service on Railway

1. Go to [Railway.app](https://railway.app)
2. Click **New Project** → **Deploy from GitHub repo**
3. Select your repository: `swapnil-agrim/openclaw`
4. Configure service:
   - **Name**: `linkedin-scraper`
   - **Root Directory**: `linkedin-scraper`
   - **Dockerfile Path**: `linkedin-scraper/Dockerfile`

### Step 2: Configure LinkedIn Scraper Environment Variables

In Railway dashboard for `linkedin-scraper` service:

```bash
PORT=3000
```

### Step 3: Get LinkedIn Scraper URL

After deployment:
1. Go to **Settings** tab
2. Click **Generate Domain** under **Networking**
3. Copy the generated URL (e.g., `https://linkedin-scraper-production-xxxx.up.railway.app`)
4. Save this URL - you'll need it for OpenClaw configuration

### Step 4: Authenticate LinkedIn Scraper

Once deployed, authenticate with your LinkedIn account:

```bash
curl -X POST https://YOUR-LINKEDIN-SCRAPER-URL.up.railway.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-linkedin-email@example.com",
    "password": "your-linkedin-password"
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "Successfully authenticated with LinkedIn"
}
```

**IMPORTANT**:
- Use a dedicated LinkedIn account or be aware of LinkedIn's terms of service
- Session persists across container restarts via `/tmp/linkedin-session.json`
- Rate limited to 30 requests/hour to protect your account

### Step 5: Test LinkedIn Scraper

Test people search:
```bash
curl -X POST https://YOUR-LINKEDIN-SCRAPER-URL.up.railway.app/api/search/people \
  -H "Content-Type: application/json" \
  -d '{"query": "Software Engineer at Google"}'
```

Test company search:
```bash
curl -X POST https://YOUR-LINKEDIN-SCRAPER-URL.up.railway.app/api/search/companies \
  -H "Content-Type: application/json" \
  -d '{"query": "AI startups"}'
```

Check health:
```bash
curl https://YOUR-LINKEDIN-SCRAPER-URL.up.railway.app/health
```

---

## Part 2: Deploy OpenClaw Service

### Step 1: Create OpenClaw Service on Railway

1. In the same Railway project, click **New Service**
2. Select **Deploy from GitHub repo**
3. Select your repository: `swapnil-agrim/openclaw`
4. Configure service:
   - **Name**: `openclaw`
   - **Root Directory**: `.` (project root)
   - **Dockerfile Path**: `Dockerfile`

### Step 2: Configure OpenClaw Environment Variables

In Railway dashboard for `openclaw` service, add these environment variables:

#### Required Variables

```bash
# Anthropic API Key
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx

# OpenClaw Gateway Token (create a strong random token)
OPENCLAW_GATEWAY_TOKEN=your-strong-random-token-here

# Tavily Search API Key
TAVILY_API_KEY=tvly-xxxxx

# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz

# Slack Bot Configuration
SLACK_BOT_TOKEN=xoxb-xxxxx
SLACK_APP_TOKEN=xapp-xxxxx
SLACK_ALLOWED_CHANNEL=C1234567890

# LinkedIn Scraper URL (from Part 1, Step 3)
LINKEDIN_SCRAPER_URL=https://linkedin-scraper-production-xxxx.up.railway.app
```

#### How to Get API Keys

**Anthropic API Key:**
1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Navigate to **API Keys**
3. Click **Create Key**
4. Copy the key starting with `sk-ant-api03-`

**Tavily API Key:**
1. Go to [tavily.com](https://tavily.com)
2. Sign up for a free account
3. Get your API key from the dashboard
4. Free tier: 1000 searches/month

**Telegram Bot Token:**
1. Open Telegram and message [@BotFather](https://t.me/botfather)
2. Send `/newbot`
3. Follow prompts to name your bot
4. Copy the token (format: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

**Slack Bot Tokens:**
1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **Create New App** → **From scratch**
3. Name your app and select workspace
4. Under **OAuth & Permissions**:
   - Add these Bot Token Scopes:
     - `chat:write`
     - `channels:history`
     - `groups:history`
     - `im:history`
     - `mpim:history`
     - `app_mentions:read`
   - Click **Install to Workspace**
   - Copy **Bot User OAuth Token** (starts with `xoxb-`)
5. Under **Socket Mode**:
   - Enable Socket Mode
   - Generate App-Level Token with `connections:write` scope
   - Copy token (starts with `xapp-`)
6. Under **Event Subscriptions**:
   - Enable Events
   - Subscribe to bot events:
     - `message.channels`
     - `message.groups`
     - `message.im`
     - `message.mpim`
     - `app_mention`
7. Get Channel ID:
   - Right-click channel in Slack → **View channel details**
   - Copy Channel ID (starts with `C`)

**OpenClaw Gateway Token:**
Generate a strong random token:
```bash
openssl rand -hex 32
```

### Step 3: Generate Domain for OpenClaw

1. Go to **Settings** tab in OpenClaw service
2. Click **Generate Domain** under **Networking**
3. Copy the URL (e.g., `https://openclaw-production-xxxx.up.railway.app`)

### Step 4: Deploy

Railway will automatically deploy when you push to your repository. Monitor logs in the Railway dashboard.

---

## Part 3: Testing Your Deployment

### Test 1: Telegram Integration

1. Find your bot on Telegram (search for the name you gave it)
2. Send: `/start`
3. Bot should respond with pairing instructions
4. Try: `What's the weather in San Francisco?` (uses Tavily search)
5. Try: `Search for AI news` (uses SearXNG fallback if Tavily fails)

### Test 2: Slack Integration

1. Invite bot to your allowed channel: `/invite @YourBotName`
2. Mention bot: `@YourBotName What are the latest trends in machine learning?`
3. Bot should respond using Tavily search

### Test 3: LinkedIn Research (via Telegram/Slack)

Ask bot:
```
Find LinkedIn profiles for "Machine Learning Engineer at OpenAI"
```

Or:
```
Search LinkedIn companies for "AI startups in San Francisco"
```

### Test 4: SearXNG Fallback

The SearXNG fallback activates automatically when:
- Tavily API key is missing
- Tavily rate limit is hit
- Tavily service is down

To test manually, you can temporarily remove `TAVILY_API_KEY` and redeploy.

---

## Part 4: Monitoring and Troubleshooting

### View OpenClaw Logs

```bash
# In Railway dashboard
1. Select openclaw service
2. Click "Deployments" tab
3. Click latest deployment
4. View logs in real-time
```

### View LinkedIn Scraper Logs

```bash
# In Railway dashboard
1. Select linkedin-scraper service
2. Click "Deployments" tab
3. Click latest deployment
4. View logs for authentication and search requests
```

### Check Health Status

OpenClaw:
```bash
curl https://YOUR-OPENCLAW-URL.up.railway.app/health
```

LinkedIn Scraper:
```bash
curl https://YOUR-LINKEDIN-SCRAPER-URL.up.railway.app/health
```

### Common Issues

#### Issue: Telegram bot not responding
**Solution:**
- Check `TELEGRAM_BOT_TOKEN` is correct
- Verify bot is not already running elsewhere
- Check logs for webhook errors

#### Issue: Slack bot not responding
**Solution:**
- Verify all three Slack tokens are set correctly
- Check bot is invited to the channel
- Confirm channel ID matches `SLACK_ALLOWED_CHANNEL`
- Enable Socket Mode in Slack app settings

#### Issue: LinkedIn scraper returns 401
**Solution:**
- Re-authenticate using `/api/auth/login` endpoint
- Session may have expired
- Check if LinkedIn requires CAPTCHA (handle manually in browser)

#### Issue: Skills not found
**Solution:**
- Check entrypoint.sh logs during startup
- Verify npm install succeeded for skills
- Skills are installed at: `/home/node/.openclaw/skills/`

#### Issue: Tavily search not working
**Solution:**
- Verify `TAVILY_API_KEY` is set correctly
- Check Tavily API quota at [tavily.com](https://tavily.com)
- SearXNG fallback should activate automatically

---

## Part 5: Advanced Configuration

### Custom SearXNG Instances

Edit `entrypoint.sh` and modify the `SEARXNG_INSTANCES` array:

```javascript
const SEARXNG_INSTANCES = [
  'https://searx.be',
  'https://search.bus-hit.me',
  'https://searx.work',
  'https://your-custom-instance.com'  // Add your instance
];
```

### Adjust Rate Limits

Edit `linkedin-scraper/index.js`:

```javascript
const MAX_REQUESTS_PER_HOUR = 30;  // Change to desired limit
```

### Add More Slack Channels

In `openclaw.json`, add additional channels:

```json
"channels": {
  "C1234567890": {
    "allow": true,
    "requireMention": true
  },
  "C0987654321": {
    "allow": true,
    "requireMention": false
  }
}
```

Update environment variable:
```bash
SLACK_ALLOWED_CHANNEL=C1234567890,C0987654321
```

### Change Model

Edit `openclaw.json`:

```json
"agents": {
  "defaults": {
    "model": {
      "primary": "anthropic/claude-opus-4-6-20250929"  // or claude-haiku-4-5-20251001
    }
  }
}
```

---

## Part 6: Cost Estimation

### Railway Costs

**LinkedIn Scraper Service:**
- Memory: ~512MB - 1GB
- Estimated: $5-10/month (Hobby Plan)

**OpenClaw Service:**
- Memory: ~256MB - 512MB
- Estimated: $5/month (Hobby Plan)

**Total Railway**: ~$10-15/month

### API Costs

**Anthropic API:**
- Claude Sonnet 4.5: $3 per million input tokens, $15 per million output tokens
- Estimated: $20-50/month (moderate usage)

**Tavily API:**
- Free tier: 1000 searches/month
- Pro: $100/month for 10,000 searches

**Total Estimated**: $30-100/month depending on usage

### Free Alternatives

- SearXNG: Completely free, unlimited searches
- Use Haiku model for lower costs: $0.25/$1.25 per million tokens

---

## Part 7: Security Best Practices

1. **Rotate Tokens Regularly**
   - Change `OPENCLAW_GATEWAY_TOKEN` monthly
   - Regenerate Slack/Telegram tokens if compromised

2. **Use Separate LinkedIn Account**
   - Don't use your personal LinkedIn account
   - Create a dedicated account for scraping

3. **Monitor Rate Limits**
   - Check LinkedIn scraper health endpoint
   - Adjust `MAX_REQUESTS_PER_HOUR` if needed

4. **Environment Variables**
   - Never commit secrets to git
   - Use Railway's encrypted environment variables

5. **Network Security**
   - Use Railway's private networking for internal services
   - Enable Cloudflare proxy if needed

---

## Part 8: Updating and Maintenance

### Update OpenClaw

```bash
# Railway automatically rebuilds on git push
git add .
git commit -m "Update OpenClaw configuration"
git push origin main
```

### Update Skills

Skills are auto-installed on container startup. To update:

1. Edit skill files in `entrypoint.sh`
2. Delete the skill directory condition to force reinstall:
   ```bash
   # Change from:
   if [ ! -d "$SEARXNG_SKILL_DIR" ]; then

   # To (temporary):
   if true; then
   ```
3. Push changes
4. Revert condition after deployment

### Backup Session Data

LinkedIn sessions are stored in `/tmp/linkedin-session.json`. To persist:

1. Add volume in Railway:
   - Settings → Volumes → Add Volume
   - Mount path: `/data`
2. Update `SESSION_FILE` in `index.js`:
   ```javascript
   const SESSION_FILE = '/data/linkedin-session.json';
   ```

---

## Support and Resources

- **OpenClaw Documentation**: [GitHub](https://github.com/swapnil-agrim/openclaw)
- **Railway Documentation**: [docs.railway.app](https://docs.railway.app)
- **Anthropic API**: [docs.anthropic.com](https://docs.anthropic.com)
- **Tavily API**: [docs.tavily.com](https://docs.tavily.com)
- **Playwright**: [playwright.dev](https://playwright.dev)

---

## Quick Reference Commands

```bash
# Test Telegram
# Just message your bot on Telegram

# Test Slack
@YourBotName help

# Test LinkedIn People Search
curl -X POST https://YOUR-SCRAPER-URL/api/search/people \
  -H "Content-Type: application/json" \
  -d '{"query": "CEO at tech companies"}'

# Test LinkedIn Company Search
curl -X POST https://YOUR-SCRAPER-URL/api/search/companies \
  -H "Content-Type: application/json" \
  -d '{"query": "AI companies"}'

# Check LinkedIn Scraper Health
curl https://YOUR-SCRAPER-URL/health

# Re-authenticate LinkedIn
curl -X POST https://YOUR-SCRAPER-URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "your-email", "password": "your-password"}'

# View OpenClaw Logs (in Railway dashboard)
# Services → openclaw → Deployments → Latest → Logs

# Generate Strong Token
openssl rand -hex 32
```

---

## Success Checklist

- [ ] LinkedIn scraper deployed and authenticated
- [ ] OpenClaw service deployed
- [ ] All environment variables set
- [ ] Telegram bot responding
- [ ] Slack bot responding
- [ ] Tavily search working
- [ ] SearXNG fallback tested
- [ ] LinkedIn people search working
- [ ] LinkedIn company search working
- [ ] Logs showing no errors

---

**Deployment Complete! 🚀**

Your OpenClaw instance is now running with:
- ✅ Telegram integration
- ✅ Slack integration
- ✅ Tavily search (primary)
- ✅ SearXNG fallback (unlimited free search)
- ✅ LinkedIn research capabilities
