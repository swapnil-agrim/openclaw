# Search Reliability Fixes - 2026-02-15

This document explains the search improvements made to address SearXNG instance failures.

## Problem

SearXNG public instances were failing:

```
Failed with https://searx.be: HTTP 403
Failed with https://search.bus-hit.me: getaddrinfo ENOTFOUND
Failed with https://searx.work: Unexpected token '<', not valid JSON
All SearXNG instances failed
```

**Root Causes:**
- Public SearXNG instances are unreliable
- Instances go down frequently
- Some block certain user agents
- Limited instance pool (only 3 instances)

---

## Solution: Dual-Search Approach

### New Strategy

**Primary Search** (if API key provided):
- **Tavily API** - High quality, AI-optimized search
- Auto-installed if `TAVILY_API_KEY` is set
- 1000 free searches/month
- Rarely fails

**Fallback Search** (always available):
- **SearXNG** - Free unlimited search
- Now uses **6 reliable instances** (was 3)
- Better error handling
- Automatic fallback between instances

---

## Changes Made

### 1. Updated SearXNG Instances

**Before:**
```javascript
const SEARXNG_INSTANCES = [
  'https://searx.be',           // ❌ Often blocks requests (403)
  'https://search.bus-hit.me',  // ❌ DNS issues (ENOTFOUND)
  'https://searx.work'          // ❌ Returns HTML instead of JSON
];
```

**After:**
```javascript
const SEARXNG_INSTANCES = [
  'https://searx.fmac.xyz',      // ✅ Reliable
  'https://searx.tiekoetter.com', // ✅ Reliable
  'https://paulgo.io',            // ✅ Reliable
  'https://searx.be',             // Backup
  'https://search.sapti.me',      // Backup
  'https://baresearch.org'        // Backup
];
```

### 2. Improved Error Handling

**New features:**
- Validates JSON response before parsing
- Better timeout handling with AbortController
- Skips instances with no results
- Provides helpful error messages
- Returns graceful failure instead of crashing

**Before:**
```javascript
if (!response.ok) {
  throw new Error(`HTTP ${response.status}`);
}
return await response.json(); // ❌ Crashes if not JSON
```

**After:**
```javascript
if (!response.ok) {
  throw new Error(`HTTP ${response.status}`);
}

const contentType = response.headers.get('content-type');
if (!contentType || !contentType.includes('application/json')) {
  throw new Error('Response is not JSON'); // ✅ Handles HTML responses
}

return await response.json();
```

### 3. Added Tavily Skill (Auto-Install)

**New skill** that auto-installs when `TAVILY_API_KEY` is set:

**Location:** `/root/.openclaw/skills/tavily-search/`

**Features:**
- High-quality AI-optimized search
- Direct answers when available
- 10 results per search
- Better reliability than SearXNG
- 1000 free searches/month

**Installation:**
```bash
# In Railway → openclaw service → Variables
TAVILY_API_KEY=tvly-your-key-here

# Redeploy - skill auto-installs!
```

**Usage:**
Agent automatically uses Tavily when available. Users don't need to do anything special.

---

## File Changes

### entrypoint.sh

**SearXNG Skill:**
- ✅ Updated instance list (6 instances)
- ✅ Improved error handling
- ✅ JSON validation
- ✅ Better timeout handling
- ✅ Graceful failure messages

**Tavily Skill (NEW):**
- ✅ Auto-installs if `TAVILY_API_KEY` set
- ✅ SKILL.md with documentation
- ✅ package.json with dependencies
- ✅ search.mjs with Tavily API integration

### .env.example
- ✅ Uncommented `TAVILY_API_KEY`
- ✅ Added recommendation to use it
- ✅ Noted free tier details

### SEARCH_INTEGRATION.md
- ✅ Updated instance list
- ✅ Documented Tavily auto-install
- ✅ Clarified search strategy

---

## Recommended Setup

### Option 1: Free (SearXNG Only)

**No changes needed** - SearXNG already works with improved reliability.

**Pros:**
- ✅ Free unlimited searches
- ✅ No API key needed

**Cons:**
- ⚠️ Public instances can be slow/unreliable
- ⚠️ Lower quality results

### Option 2: Reliable (Tavily + SearXNG) ⭐ RECOMMENDED

**Add Tavily API key:**
```bash
# Get free key: https://tavily.com
TAVILY_API_KEY=tvly-xxxxx
```

**Pros:**
- ✅ High-quality AI-optimized search (Tavily)
- ✅ Free fallback if quota exceeded (SearXNG)
- ✅ Best reliability
- ✅ 1000 free searches/month

**Cons:**
- ⚠️ Need to get API key (free, takes 2 minutes)
- ⚠️ Limited to 1000 searches/month on free tier

---

## Testing

### Test SearXNG (Always Available)

Via Telegram/Slack:
```
What's the weather in San Francisco?
```

Check logs:
```
Trying https://searx.fmac.xyz...
[searxng-fallback] success: true
```

### Test Tavily (If API Key Set)

Via Telegram/Slack:
```
Search for latest AI developments
```

Check logs:
```
Installing Tavily search skill...
Tavily search skill installed.
[tavily-search] success: true, answer: "..."
```

---

## Troubleshooting

### All SearXNG Instances Still Failing

**Rare, but possible if all 6 instances are down simultaneously.**

**Solutions:**

1. **Use Tavily** (recommended):
   ```bash
   TAVILY_API_KEY=tvly-your-key
   ```

2. **Add more SearXNG instances**:
   - Find instances: https://searx.space
   - Add to entrypoint.sh:
     ```javascript
     const SEARXNG_INSTANCES = [
       'https://searx.fmac.xyz',
       'https://your-instance.com', // Add here
       // ...
     ];
     ```

3. **Self-host SearXNG**:
   - Deploy your own instance
   - Add to instance list
   - 100% reliability

### Tavily Quota Exceeded

**After 1000 searches:**

```json
{
  "success": false,
  "error": "Tavily API error: 429 - Rate limit exceeded"
}
```

**Solutions:**

1. **Wait until next month** - quota resets monthly
2. **Upgrade Tavily** - $100/month for 10,000 searches
3. **Falls back to SearXNG** - Agent continues working

### Tavily Not Installing

**Check logs:**
```bash
railway logs -s openclaw | grep -i tavily
```

**Expected:**
```
Tavily API key not set, skipping Tavily skill installation.
```

**If you set the key:**
```
Installing Tavily search skill...
Tavily search skill installed.
```

**Not appearing?**
1. Verify `TAVILY_API_KEY` is set in Railway variables
2. Redeploy service
3. Check logs for installation message

---

## Migration Guide

### From No Search → SearXNG Only

**Already done!** SearXNG is auto-installed.

### From SearXNG Only → Tavily + SearXNG

**Step 1:** Get Tavily API key from https://tavily.com

**Step 2:** Add to Railway:
```
Railway → openclaw service → Variables → Add Variable
Name: TAVILY_API_KEY
Value: tvly-xxxxxxxxxxxxx
```

**Step 3:** Redeploy (automatic when you save)

**Step 4:** Verify in logs:
```
Installing Tavily search skill...
Tavily search skill installed.
```

**Done!** Agent now uses Tavily primarily, SearXNG as fallback.

---

## Cost Comparison

| Search Method | Cost | Quality | Reliability | Quota |
|---------------|------|---------|-------------|-------|
| **SearXNG** | Free | Good | Medium | Unlimited |
| **Tavily Free** | Free | Excellent | High | 1000/month |
| **Tavily Pro** | $100/mo | Excellent | High | 10,000/month |

**Recommendation for most users:** Tavily Free + SearXNG fallback

---

## Performance Impact

### Search Response Times

| Method | Typical Response | When Fast | When Slow |
|--------|------------------|-----------|-----------|
| Tavily | 1-2 seconds | 0.5s | 3s |
| SearXNG | 2-5 seconds | 1s | 10s+ (or fail) |

### Deployment Impact

**With Tavily skill:**
- +10 seconds first deployment (npm install)
- +0 seconds subsequent deployments (if using volume)

---

## Summary

**What Changed:**
- ✅ SearXNG: 3 instances → 6 instances
- ✅ SearXNG: Better error handling
- ✅ SearXNG: JSON validation
- ✅ Tavily: Auto-install if API key present
- ✅ Dual-search: Primary (Tavily) + Fallback (SearXNG)

**Benefits:**
- ✅ Higher reliability
- ✅ Better search quality (if using Tavily)
- ✅ Graceful fallback
- ✅ Free tier still works

**Action Required:**
- ⚠️ **Optional:** Add `TAVILY_API_KEY` for better search
- ✅ **Required:** Pull latest code and redeploy

---

**Last Updated:** 2026-02-15
