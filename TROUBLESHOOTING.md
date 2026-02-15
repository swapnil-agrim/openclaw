# OpenClaw Troubleshooting Guide

Common issues and solutions for OpenClaw deployment on Railway.

## Table of Contents
- [Deployment Issues](#deployment-issues)
- [Configuration Issues](#configuration-issues)
- [Integration Issues](#integration-issues)
- [LinkedIn Scraper Issues](#linkedin-scraper-issues)
- [Skill Issues](#skill-issues)

---

## Deployment Issues

### Error: `unknown option '--config'`

**Symptom:**
```
Config created and environment variables replaced.
Starting OpenClaw gateway...
error: unknown option '--config'
```

**Cause:**
OpenClaw CLI doesn't accept `--config` flag. It uses environment variables instead.

**Solution:**
✅ Fixed in latest version. The entrypoint.sh now uses:
```bash
export OPENCLAW_STATE_DIR=/home/node/.openclaw
export OPENCLAW_CONFIG_PATH=/home/node/.openclaw/openclaw.json
exec openclaw gateway
```

If you still see this error, pull the latest changes:
```bash
git pull origin main
```

---

### Error: Config file not found

**Symptom:**
```
Error: Config file not found at /home/node/.openclaw/openclaw.json
```

**Solution:**
1. Check that `openclaw.json` is copied in Dockerfile:
   ```dockerfile
   COPY openclaw.json /app/openclaw.json
   ```

2. Verify entrypoint.sh copies it:
   ```bash
   cp /app/openclaw.json /home/node/.openclaw/openclaw.json
   ```

3. Check logs for copy errors:
   ```bash
   railway logs -s openclaw | grep -i "copy\|config"
   ```

---

### Error: Permission denied

**Symptom:**
```
mkdir: cannot create directory '/home/node/.openclaw': Permission denied
```

**Solution:**
The container may be running as a restricted user. Update Dockerfile to ensure proper permissions:

```dockerfile
RUN mkdir -p /home/node/.openclaw && \
    chown -R node:node /home/node/.openclaw
USER node
```

Or run as root (less secure but works on Railway):
```dockerfile
# Remove USER node if present
```

---

## Configuration Issues

### Environment variables not replaced

**Symptom:**
Config contains `${ANTHROPIC_API_KEY}` instead of actual values.

**Solution:**
1. Check Railway environment variables are set
2. Verify sed commands in entrypoint.sh:
   ```bash
   sed -i "s|\${ANTHROPIC_API_KEY}|${ANTHROPIC_API_KEY}|g" /home/node/.openclaw/openclaw.json
   ```

3. Test locally:
   ```bash
   export ANTHROPIC_API_KEY=sk-test-123
   sed "s|\${ANTHROPIC_API_KEY}|${ANTHROPIC_API_KEY}|g" openclaw.json
   ```

4. Check for special characters in environment variables that might break sed:
   - Avoid `|`, `/`, `$` in tokens
   - Use alphanumeric characters and hyphens

---

### Invalid JSON in openclaw.json

**Symptom:**
```
SyntaxError: Unexpected token } in JSON at position 234
```

**Solution:**
1. Validate JSON locally:
   ```bash
   cat openclaw.json | jq '.'
   ```

2. Check for:
   - Trailing commas in arrays/objects
   - Unescaped quotes in strings
   - Missing closing brackets

3. Use JSONLint: https://jsonlint.com

---

## Integration Issues

### Telegram bot not responding

**Checklist:**
- [ ] `TELEGRAM_BOT_TOKEN` is set correctly
- [ ] Token format: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`
- [ ] Bot is not running elsewhere (only one instance allowed)
- [ ] Sent `/start` to bot first
- [ ] Check Railway logs for Telegram connection errors

**Test:**
```bash
# Check if bot token is valid
curl https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getMe
```

**Common Issues:**
- **Multiple instances**: Stop other instances or revoke token and create new bot
- **Invalid token**: Get new token from @BotFather
- **Network issues**: Check Railway service is running

---

### Slack bot not responding

**Checklist:**
- [ ] `SLACK_BOT_TOKEN` (starts with `xoxb-`) is set
- [ ] `SLACK_APP_TOKEN` (starts with `xapp-`) is set
- [ ] `SLACK_ALLOWED_CHANNEL` is the correct channel ID (starts with `C`)
- [ ] Bot is invited to the channel: `/invite @YourBot`
- [ ] Socket Mode is enabled in Slack app settings
- [ ] Event subscriptions are configured
- [ ] Bot has required scopes (see DEPLOYMENT.md)

**Get Channel ID:**
1. Right-click channel in Slack
2. Click "View channel details"
3. Scroll down to find Channel ID (starts with `C`)

**Test:**
```bash
# Verify bot token
curl https://slack.com/api/auth.test \
  -H "Authorization: Bearer xoxb-YOUR-TOKEN"
```

**Common Issues:**
- **Not invited**: Invite bot to channel
- **Wrong channel ID**: Use channel ID (C123...), not name
- **Missing scopes**: Add required OAuth scopes in Slack app settings
- **Socket mode disabled**: Enable in Slack app → Socket Mode

---

### Tavily search not working

**Checklist:**
- [ ] `TAVILY_API_KEY` is set correctly
- [ ] Format: `tvly-xxxxxxxxxxxxx`
- [ ] API key is valid and not expired
- [ ] Not exceeded free tier limit (1000/month)

**Test:**
```bash
curl -X POST https://api.tavily.com/search \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "YOUR_TAVILY_KEY",
    "query": "test search"
  }'
```

**Fallback:**
SearXNG fallback should activate automatically when Tavily fails. Check logs for:
```
Trying https://searx.be...
```

---

## LinkedIn Scraper Issues

### Error 401: Not authenticated

**Symptom:**
```json
{
  "success": false,
  "error": "Not authenticated. Please login first using /api/auth/login"
}
```

**Solution:**
Authenticate the scraper:

```bash
curl -X POST https://YOUR-SCRAPER-URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-linkedin-email@example.com",
    "password": "your-linkedin-password"
  }'
```

**Session persistence:**
- Sessions are saved to `/tmp/linkedin-session.json`
- Sessions persist across restarts
- If session expires, re-authenticate

---

### Error 429: Rate limit exceeded

**Symptom:**
```json
{
  "success": false,
  "error": "Rate limit exceeded. Maximum 30 requests per hour.",
  "resetTime": "2026-02-15T11:00:00.000Z"
}
```

**Solution:**
- Wait until `resetTime`
- Check current rate limit:
  ```bash
  curl https://YOUR-SCRAPER-URL/health
  ```

**Adjust rate limit:**
Edit `linkedin-scraper/index.js`:
```javascript
const MAX_REQUESTS_PER_HOUR = 30;  // Change to 60, etc.
```

---

### LinkedIn returns no results

**Possible causes:**
1. **Query too specific**: Try broader search terms
2. **Session expired**: Re-authenticate
3. **LinkedIn UI changed**: Update selectors in `index.js`
4. **CAPTCHA required**: LinkedIn detected automation

**Solutions:**
1. Use broader queries
2. Re-authenticate
3. Check browser console for selector changes
4. Complete CAPTCHA manually in browser, then re-authenticate

---

### CAPTCHA challenge

**When it happens:**
- First login
- Suspicious activity detected
- Too many searches

**Solution:**
1. Log into LinkedIn manually in a browser
2. Complete the CAPTCHA
3. Then re-authenticate via API

**Prevention:**
- Use dedicated LinkedIn account
- Keep rate limit low (30/hour)
- Add random delays (already implemented)

---

## Skill Issues

### Skills not installing

**Symptom:**
```
Starting OpenClaw gateway...
(no "Installing SearXNG skill..." message)
```

**Solution:**
1. Check if skill directories already exist:
   ```bash
   railway shell -s openclaw
   ls -la /home/node/.openclaw/skills/
   ```

2. If stuck, force reinstall by deleting volume data in Railway:
   - Settings → Volumes → Delete volume
   - Redeploy

3. Check entrypoint.sh runs:
   ```bash
   railway logs -s openclaw | grep -i "skill"
   ```

---

### npm install fails for skills

**Symptom:**
```
npm ERR! code ENETUNREACH
npm ERR! network request to https://registry.npmjs.org/node-fetch failed
```

**Solution:**
1. Temporary network issue - redeploy
2. Check Railway status: https://status.railway.app
3. Verify npm registry is accessible

**Add retry logic** in entrypoint.sh:
```bash
cd "$SEARXNG_SKILL_DIR"
npm install --retry 3 --loglevel verbose
```

---

### Skill command not found

**Symptom:**
When using skills from chat:
```
Error: Command not found: searxng-fallback
```

**Solution:**
1. Skills must be in: `/home/node/.openclaw/skills/`
2. Each skill needs `SKILL.md` with proper frontmatter
3. Scripts must be executable
4. Check OpenClaw skill loading logs

**Verify skill structure:**
```
skills/searxng-fallback/
├── SKILL.md           # Required
├── package.json       # Required
└── scripts/
    └── search.mjs     # Referenced in SKILL.md
```

---

### LinkedIn skill can't connect to scraper

**Symptom:**
```
Error: LINKEDIN_SCRAPER_URL environment variable not set
```

**Solution:**
1. Set `LINKEDIN_SCRAPER_URL` in Railway OpenClaw service
2. Format: `https://your-scraper.railway.app` (no trailing slash)
3. Redeploy OpenClaw service

**Test connection:**
```bash
railway shell -s openclaw
echo $LINKEDIN_SCRAPER_URL
curl $LINKEDIN_SCRAPER_URL/health
```

---

## General Debugging

### View logs in real-time

```bash
# OpenClaw logs
railway logs -s openclaw --follow

# LinkedIn scraper logs
railway logs -s linkedin-scraper --follow
```

### SSH into container

```bash
# OpenClaw
railway shell -s openclaw

# LinkedIn scraper
railway shell -s linkedin-scraper
```

### Check environment variables

```bash
railway variables -s openclaw
railway variables -s linkedin-scraper
```

### Test locally with Docker

```bash
# Build and run OpenClaw
docker build -t openclaw .
docker run --env-file .env openclaw

# Build and run LinkedIn scraper
cd linkedin-scraper
docker build -t linkedin-scraper .
docker run -p 3000:3000 linkedin-scraper
```

---

## Getting Help

1. **Check logs first**: Most issues show up in Railway logs
2. **Review DEPLOYMENT.md**: Step-by-step setup guide
3. **Test components individually**: Isolate the problem
4. **Railway Discord**: https://discord.gg/railway
5. **OpenClaw Docs**: https://github.com/openclaw/openclaw

---

## Quick Fixes Checklist

When something isn't working:

- [ ] Check Railway logs for errors
- [ ] Verify all environment variables are set
- [ ] Confirm services are deployed and running
- [ ] Test health endpoints
- [ ] Re-authenticate LinkedIn if needed
- [ ] Check API quotas (Tavily, Anthropic)
- [ ] Redeploy services
- [ ] Clear volumes and restart fresh

---

**Last Updated:** 2026-02-15
