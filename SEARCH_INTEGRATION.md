# Search Integration Guide

This document explains how search functionality works in your OpenClaw deployment.

## Search Strategy

Your OpenClaw instance uses a **dual-search approach**:

1. **Primary**: SearXNG (Free, Unlimited) via auto-installed skill
2. **Optional**: Tavily API (Paid, 1000 free searches/month)

## Why SearXNG Instead of Tavily?

After testing the OpenClaw configuration, we discovered that:

- ❌ OpenClaw doesn't support `mcpServers` configuration (Tavily MCP integration)
- ❌ Direct Tavily API integration requires custom skill development
- ✅ SearXNG provides **free unlimited searches** via public instances
- ✅ SearXNG is **already integrated** as an auto-installed skill
- ✅ No API key needed

## SearXNG Skill

### How It Works

The SearXNG skill is automatically installed when the container starts:

**Location**: `/home/node/.openclaw/skills/searxng-fallback/`

**Public Instances Used**:
- `https://searx.be`
- `https://search.bus-hit.me`
- `https://searx.work`

**Features**:
- Automatic fallback between instances
- Returns up to 10 results per search
- Includes title, URL, and snippet for each result
- No rate limiting
- No API key required

### Usage in Chat

Users can search the web by simply asking:

```
"What's the weather in San Francisco?"
"Search for latest AI news"
"Find information about Python decorators"
```

OpenClaw will automatically use the SearXNG skill for web searches.

### Skill Command (Direct)

Advanced users can call the skill directly:

```bash
searxng-fallback search "your query here"
```

## Optional: Adding Tavily (Advanced)

If you want to add Tavily as an additional search option, you'll need to create a custom skill.

### Create Tavily Skill

1. **Create skill directory structure**:
   ```bash
   /home/node/.openclaw/skills/tavily-search/
   ├── SKILL.md
   ├── package.json
   └── scripts/
       └── search.mjs
   ```

2. **Add to entrypoint.sh** (similar to SearXNG skill):
   ```bash
   TAVILY_SKILL_DIR="/home/node/.openclaw/skills/tavily-search"
   if [ ! -d "$TAVILY_SKILL_DIR" ]; then
     echo "Installing Tavily search skill..."
     # Create skill files here
   fi
   ```

3. **Implement search.mjs**:
   ```javascript
   import fetch from 'node-fetch';

   const TAVILY_API_KEY = process.env.TAVILY_API_KEY;

   async function search(query) {
     const response = await fetch('https://api.tavily.com/search', {
       method: 'POST',
       headers: { 'Content-Type': 'application/json' },
       body: JSON.stringify({
         api_key: TAVILY_API_KEY,
         query: query,
         search_depth: 'basic',
         include_answer: true
       })
     });

     const data = await response.json();
     console.log(JSON.stringify(data, null, 2));
   }

   search(process.argv[2]);
   ```

### Tavily Benefits

If you choose to add Tavily:
- Better search quality (AI-optimized results)
- Includes direct answers
- Deep search mode available
- Structured data extraction

### Tavily Costs

- **Free tier**: 1,000 searches/month
- **Pro**: $100/month for 10,000 searches
- Get API key: https://tavily.com

## LinkedIn Research Skill

In addition to web search, you have **LinkedIn research capabilities**:

### People Search

```
"Find LinkedIn profiles for Machine Learning Engineers at Google"
"Search LinkedIn for AI researchers in San Francisco"
```

### Company Search

```
"Search LinkedIn companies for fintech startups"
"Find AI companies on LinkedIn"
```

### Rate Limits

- 30 requests per hour (configurable)
- Protects your LinkedIn account
- Check status: `curl https://YOUR-SCRAPER-URL/health`

## Search Comparison

| Feature | SearXNG | Tavily | LinkedIn |
|---------|---------|--------|----------|
| Cost | Free | $0-100/mo | Free |
| API Key | No | Yes | No |
| Rate Limit | None | 1000/mo (free) | 30/hour |
| Results | General web | AI-optimized | Professional profiles |
| Quality | Good | Excellent | Specialized |
| Setup | ✅ Auto-installed | ❌ Manual skill | ✅ Auto-installed |

## Recommended Configuration

**For most users**: Stick with **SearXNG + LinkedIn**
- No additional costs
- Unlimited searches
- Professional research capability
- Already configured and working

**For power users**: Add **Tavily** if you need:
- Higher quality search results
- AI-generated answers
- Structured data extraction
- Budget for API costs

## Testing Your Search

### Test SearXNG

Via Telegram or Slack:
```
What are the latest developments in quantum computing?
```

### Test LinkedIn

Via Telegram or Slack:
```
Find LinkedIn profiles for "CEO at tech companies"
Search LinkedIn companies for "AI startups in San Francisco"
```

### Check Logs

Monitor search activity in Railway:
```bash
railway logs -s openclaw | grep -i "searxng\|search"
```

## Environment Variables

Current configuration only needs:

```bash
# Required for OpenClaw
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
OPENCLAW_GATEWAY_TOKEN=your-token
TELEGRAM_BOT_TOKEN=xxxxx
SLACK_BOT_TOKEN=xoxb-xxxxx
SLACK_APP_TOKEN=xapp-xxxxx
SLACK_ALLOWED_CHANNEL=C123456

# Required for LinkedIn research
LINKEDIN_SCRAPER_URL=https://your-scraper.railway.app

# Optional - only if you add Tavily skill manually
TAVILY_API_KEY=tvly-xxxxx  # Not currently used
```

## Troubleshooting

### SearXNG not working

**Check if skill is installed**:
```bash
railway shell -s openclaw
ls -la /home/node/.openclaw/skills/searxng-fallback/
```

**Test manually**:
```bash
cd /home/node/.openclaw/skills/searxng-fallback
node scripts/search.mjs "test query"
```

### All SearXNG instances failing

If all three instances are down (rare), you can:

1. Add more instances to `entrypoint.sh`:
   ```javascript
   const SEARXNG_INSTANCES = [
     'https://searx.be',
     'https://search.bus-hit.me',
     'https://searx.work',
     'https://searx.fmac.xyz',  // Add more
     'https://searx.tiekoetter.com'
   ];
   ```

2. Find more instances: https://searx.space

### LinkedIn research not working

See TROUBLESHOOTING.md for LinkedIn-specific issues.

## Summary

✅ **Current Setup**: SearXNG (free, unlimited) + LinkedIn research
✅ **Works out of the box**: No additional configuration needed
✅ **Cost**: $0 for search (only pay for Anthropic API and Railway hosting)
❌ **Tavily**: Not currently integrated (can be added manually if needed)

Your search capabilities are fully functional with the free, unlimited SearXNG integration!

---

**Last Updated**: 2026-02-15
