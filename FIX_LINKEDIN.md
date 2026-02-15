# Fix LinkedIn Scraper Integration

Your `LINKEDIN_SCRAPER_URL` is currently pointing to the OpenClaw service instead of a separate LinkedIn scraper.

## Current Problem

**Current URL:** `https://openclaw-production-7648.up.railway.app`

This is your OpenClaw Control UI, not the LinkedIn scraper service.

When the agent tries to search LinkedIn:
```
POST https://openclaw-production-7648.up.railway.app/api/search/people
→ Returns 405 Method Not Allowed
```

## Solution: Deploy LinkedIn Scraper Separately

You have two options:

---

### **Option A: Deploy LinkedIn Scraper** (Recommended if you want LinkedIn research)

#### Step 1: Deploy to Railway

1. Go to Railway dashboard
2. Click **New Service** in your project
3. Select **Deploy from GitHub repo**
4. Choose repository: `swapnil-agrim/openclaw`
5. Configure:
   - **Service name**: `linkedin-scraper`
   - **Root Directory**: `linkedin-scraper`
   - **Build Method**: Dockerfile

#### Step 2: Generate Domain

1. Go to service Settings → Networking
2. Click **Generate Domain**
3. Copy the URL (e.g., `https://linkedin-scraper-production-abc123.up.railway.app`)

#### Step 3: Update OpenClaw

1. Go to `openclaw` service → Variables
2. Update `LINKEDIN_SCRAPER_URL`:
   ```
   LINKEDIN_SCRAPER_URL=https://linkedin-scraper-production-abc123.up.railway.app
   ```
3. Save (Railway will auto-redeploy)

#### Step 4: Authenticate

```bash
curl -X POST https://YOUR-SCRAPER-URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-linkedin-email@example.com",
    "password": "your-linkedin-password"
  }'
```

#### Step 5: Test

```bash
curl -X POST https://YOUR-SCRAPER-URL/api/search/people \
  -H "Content-Type: application/json" \
  -d '{"query": "CEO"}'
```

**Done!** LinkedIn research will now work.

---

### **Option B: Disable LinkedIn Skill** (If you don't need LinkedIn research)

#### Step 1: Remove Environment Variable

1. Go to Railway → `openclaw` service → Variables
2. Delete `LINKEDIN_SCRAPER_URL`
3. Save

#### Step 2: Update Entrypoint (Optional)

The skill won't install if `LINKEDIN_SCRAPER_URL` is not set, so you're done!

Or, to prevent installation attempts, you can skip the skill:

```bash
# In entrypoint.sh, change:
if [ ! -d "$LINKEDIN_SKILL_DIR" ]; then

# To:
if [ ! -d "$LINKEDIN_SKILL_DIR" ] && [ -n "$LINKEDIN_SCRAPER_URL" ]; then
```

---

## Check Current Status

Run the check script:

```bash
./check-linkedin-scraper.sh https://openclaw-production-7648.up.railway.app
```

Output will show if it's pointing to the wrong service.

---

## Cost Comparison

| Option | Cost | Features |
|--------|------|----------|
| **Deploy LinkedIn Scraper** | +$5-10/month | Full LinkedIn research |
| **Disable LinkedIn** | $0 | No LinkedIn, but saves money |

---

## Recommended Setup

**For most users:**
- ✅ Deploy LinkedIn scraper ($5-10/month)
- ✅ Enable Tavily (1000 free searches/month)
- ❌ Skip SearXNG (unreliable)

**Total extra cost:** ~$5-15/month for LinkedIn scraper

**Benefits:**
- Professional research capabilities
- Company and people search
- Works alongside Tavily web search

---

## After Fixing

### Verify LinkedIn Works

Via Telegram/Slack:
```
Find LinkedIn profiles for "AI engineers at Google"
```

Should return:
```json
{
  "success": true,
  "count": 15,
  "results": [
    {
      "name": "John Doe",
      "title": "AI Engineer at Google",
      "location": "San Francisco, CA",
      "profileUrl": "https://linkedin.com/in/johndoe"
    }
  ]
}
```

### Check Logs

```bash
railway logs -s openclaw | grep -i linkedin
```

Should show:
```
Installing LinkedIn research skill...
LinkedIn research skill installed.
[linkedin-research] success: true
```

---

## Summary

**Problem:** `LINKEDIN_SCRAPER_URL` points to OpenClaw, not scraper

**Solutions:**
1. **Deploy scraper separately** (recommended) - Full LinkedIn features
2. **Remove the variable** (free) - Disables LinkedIn skill

**Recommendation:** Deploy the scraper if you want LinkedIn research capabilities. It's only $5-10/month and adds significant value for professional research.

---

**Files:**
- `linkedin-scraper/` directory contains everything needed
- Deploy as separate Railway service
- See `DEPLOYMENT.md` Part 1 for detailed steps

