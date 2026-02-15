#!/bin/bash
set -e

# Create OpenClaw directories (use /root since running as root)
mkdir -p /root/.openclaw/workspace

# Copy and process config file
cp /app/openclaw.json /root/.openclaw/openclaw.json

# Replace environment variables in config
sed -i "s|\${TELEGRAM_BOT_TOKEN}|${TELEGRAM_BOT_TOKEN}|g" /root/.openclaw/openclaw.json
sed -i "s|\${SLACK_BOT_TOKEN}|${SLACK_BOT_TOKEN}|g" /root/.openclaw/openclaw.json
sed -i "s|\${SLACK_APP_TOKEN}|${SLACK_APP_TOKEN}|g" /root/.openclaw/openclaw.json
sed -i "s|\${SLACK_ALLOWED_CHANNEL}|${SLACK_ALLOWED_CHANNEL}|g" /root/.openclaw/openclaw.json
sed -i "s|\${OPENCLAW_GATEWAY_TOKEN}|${OPENCLAW_GATEWAY_TOKEN}|g" /root/.openclaw/openclaw.json

# Create memory directory and files (agent expects memory to be a directory)
mkdir -p /root/.openclaw/workspace/memory
touch /root/.openclaw/workspace/MEMORY.md

echo "Config created and environment variables replaced."

# Install SearXNG Fallback Skill (skip if Tavily is available)
SEARXNG_SKILL_DIR="/root/.openclaw/skills/searxng-fallback"
if [ ! -d "$SEARXNG_SKILL_DIR" ] && [ -z "$TAVILY_API_KEY" ]; then
  echo "Installing SearXNG fallback skill..."
  echo "NOTE: SearXNG public instances are unreliable. Consider using Tavily instead."
  mkdir -p "$SEARXNG_SKILL_DIR/scripts"

  cat > "$SEARXNG_SKILL_DIR/SKILL.md" << 'EOF'
---
name: searxng-fallback
description: Free unlimited web search using SearXNG instances as fallback when primary search is unavailable
commands:
  - name: search
    description: Search the web using SearXNG
    args:
      - name: query
        description: Search query
        required: true
---

# SearXNG Fallback Search

Provides free unlimited web search using public SearXNG instances.

## Usage

```bash
searxng-fallback search "your query here"
```

## Features

- Fallback across multiple SearXNG instances
- No API key required
- Unlimited searches
- Returns title, URL, and snippet for each result
EOF

  cat > "$SEARXNG_SKILL_DIR/package.json" << 'EOF'
{
  "name": "searxng-fallback",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "node-fetch": "^3.3.0"
  }
}
EOF

  cat > "$SEARXNG_SKILL_DIR/scripts/search.mjs" << 'EOF'
import fetch from 'node-fetch';

// More reliable SearXNG instances (updated 2026-02-15)
const SEARXNG_INSTANCES = [
  'https://searx.fmac.xyz',
  'https://searx.tiekoetter.com',
  'https://paulgo.io',
  'https://searx.be',
  'https://search.sapti.me',
  'https://baresearch.org'
];

async function searchSearXNG(instance, query) {
  const url = `${instance}/search?q=${encodeURIComponent(query)}&format=json&categories=general`;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);

  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json'
      },
      signal: controller.signal
    });

    clearTimeout(timeout);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const contentType = response.headers.get('content-type');
    if (!contentType || !contentType.includes('application/json')) {
      throw new Error('Response is not JSON');
    }

    return await response.json();
  } catch (error) {
    clearTimeout(timeout);
    throw error;
  }
}

async function search(query) {
  const errors = [];

  for (const instance of SEARXNG_INSTANCES) {
    try {
      console.error(`Trying ${instance}...`);
      const data = await searchSearXNG(instance, query);

      if (!data.results || data.results.length === 0) {
        console.error(`${instance} returned no results, trying next...`);
        continue;
      }

      const results = data.results.slice(0, 10).map(r => ({
        title: r.title || 'No title',
        url: r.url || '',
        snippet: r.content || r.description || ''
      })).filter(r => r.url);

      if (results.length === 0) {
        console.error(`${instance} returned empty results after filtering`);
        continue;
      }

      console.log(JSON.stringify({
        success: true,
        instance,
        count: results.length,
        results
      }, null, 2));

      return;
    } catch (error) {
      const errorMsg = `${instance}: ${error.message}`;
      console.error(`Failed - ${errorMsg}`);
      errors.push(errorMsg);
    }
  }

  // All instances failed, return error summary
  console.error('All SearXNG instances failed. Errors:');
  errors.forEach(err => console.error(`  - ${err}`));

  console.log(JSON.stringify({
    success: false,
    error: 'All SearXNG instances are currently unavailable',
    tried: SEARXNG_INSTANCES.length,
    suggestion: 'Please try again in a few moments or use a different search method'
  }, null, 2));

  process.exit(1);
}

const query = process.argv[2];
if (!query) {
  console.error('Usage: search.mjs <query>');
  process.exit(1);
}

search(query);
EOF

  cd "$SEARXNG_SKILL_DIR"
  npm install
  echo "SearXNG skill installed."
elif [ -n "$TAVILY_API_KEY" ]; then
  echo "Skipping SearXNG (Tavily API key found - using Tavily for search instead)"
else
  echo "SearXNG skill already installed."
fi

# Install LinkedIn Research Skill
LINKEDIN_SKILL_DIR="/root/.openclaw/skills/linkedin-research"
if [ ! -d "$LINKEDIN_SKILL_DIR" ]; then
  echo "Installing LinkedIn research skill..."
  mkdir -p "$LINKEDIN_SKILL_DIR/scripts"

  cat > "$LINKEDIN_SKILL_DIR/SKILL.md" << 'EOF'
---
name: linkedin-research
description: Research people and companies on LinkedIn via scraper service
commands:
  - name: search-people
    description: Search for people on LinkedIn
    args:
      - name: query
        description: Search query (name, title, company)
        required: true
  - name: search-companies
    description: Search for companies on LinkedIn
    args:
      - name: query
        description: Company name or industry
        required: true
---

# LinkedIn Research

Research people and companies on LinkedIn using the scraper service.

## Setup

Requires LINKEDIN_SCRAPER_URL environment variable pointing to the scraper service.

## Usage

```bash
# Search for people
linkedin-research search-people "Software Engineer at Google"

# Search for companies
linkedin-research search-companies "AI startups San Francisco"
```

## Features

- People search: name, title, location, profile URL
- Company search: name, industry, location, company URL
- Rate-limited to protect account
EOF

  cat > "$LINKEDIN_SKILL_DIR/package.json" << 'EOF'
{
  "name": "linkedin-research",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "node-fetch": "^3.3.0"
  }
}
EOF

  cat > "$LINKEDIN_SKILL_DIR/scripts/search-people.mjs" << 'EOF'
import fetch from 'node-fetch';

const SCRAPER_URL = process.env.LINKEDIN_SCRAPER_URL;

if (!SCRAPER_URL) {
  console.error('Error: LINKEDIN_SCRAPER_URL environment variable not set');
  process.exit(1);
}

async function searchPeople(query) {
  try {
    const response = await fetch(`${SCRAPER_URL}/api/search/people`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ query })
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${await response.text()}`);
    }

    const data = await response.json();
    console.log(JSON.stringify(data, null, 2));
  } catch (error) {
    console.error('Error searching LinkedIn:', error.message);
    process.exit(1);
  }
}

const query = process.argv[2];
if (!query) {
  console.error('Usage: search-people.mjs <query>');
  process.exit(1);
}

searchPeople(query);
EOF

  cat > "$LINKEDIN_SKILL_DIR/scripts/search-companies.mjs" << 'EOF'
import fetch from 'node-fetch';

const SCRAPER_URL = process.env.LINKEDIN_SCRAPER_URL;

if (!SCRAPER_URL) {
  console.error('Error: LINKEDIN_SCRAPER_URL environment variable not set');
  process.exit(1);
}

async function searchCompanies(query) {
  try {
    const response = await fetch(`${SCRAPER_URL}/api/search/companies`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ query })
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${await response.text()}`);
    }

    const data = await response.json();
    console.log(JSON.stringify(data, null, 2));
  } catch (error) {
    console.error('Error searching LinkedIn:', error.message);
    process.exit(1);
  }
}

const query = process.argv[2];
if (!query) {
  console.error('Usage: search-companies.mjs <query>');
  process.exit(1);
}

searchCompanies(query);
EOF

  cd "$LINKEDIN_SKILL_DIR"
  npm install
  echo "LinkedIn research skill installed."
fi

# Install Tavily Search Skill (optional - only if API key is set)
TAVILY_SKILL_DIR="/root/.openclaw/skills/tavily-search"
if [ ! -d "$TAVILY_SKILL_DIR" ] && [ -n "$TAVILY_API_KEY" ]; then
  echo "Installing Tavily search skill..."
  mkdir -p "$TAVILY_SKILL_DIR/scripts"

  cat > "$TAVILY_SKILL_DIR/SKILL.md" << 'EOF'
---
name: tavily-search
description: AI-optimized web search using Tavily API (primary search if API key provided)
commands:
  - name: search
    description: Search the web using Tavily
    args:
      - name: query
        description: Search query
        required: true
---

# Tavily Search

High-quality AI-optimized web search using Tavily API.

## Usage

```bash
tavily-search search "your query here"
```

## Features

- AI-optimized search results
- Direct answers when available
- Better quality than SearXNG
- Requires API key (1000 free searches/month)

## Setup

Set TAVILY_API_KEY environment variable in Railway.
EOF

  cat > "$TAVILY_SKILL_DIR/package.json" << 'EOF'
{
  "name": "tavily-search",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "node-fetch": "^3.3.0"
  }
}
EOF

  cat > "$TAVILY_SKILL_DIR/scripts/search.mjs" << 'EOF'
import fetch from 'node-fetch';

const TAVILY_API_KEY = process.env.TAVILY_API_KEY;

if (!TAVILY_API_KEY) {
  console.error('Error: TAVILY_API_KEY environment variable not set');
  console.log(JSON.stringify({
    success: false,
    error: 'TAVILY_API_KEY not configured'
  }, null, 2));
  process.exit(1);
}

async function search(query) {
  try {
    const response = await fetch('https://api.tavily.com/search', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        api_key: TAVILY_API_KEY,
        query: query,
        search_depth: 'basic',
        include_answer: true,
        include_images: false,
        include_raw_content: false,
        max_results: 10
      })
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Tavily API error: ${response.status} - ${error}`);
    }

    const data = await response.json();

    const results = (data.results || []).map(r => ({
      title: r.title,
      url: r.url,
      snippet: r.content || ''
    }));

    console.log(JSON.stringify({
      success: true,
      answer: data.answer || null,
      count: results.length,
      results
    }, null, 2));

  } catch (error) {
    console.error('Tavily search failed:', error.message);
    console.log(JSON.stringify({
      success: false,
      error: error.message
    }, null, 2));
    process.exit(1);
  }
}

const query = process.argv[2];
if (!query) {
  console.error('Usage: search.mjs <query>');
  process.exit(1);
}

search(query);
EOF

  cd "$TAVILY_SKILL_DIR"
  npm install
  echo "Tavily search skill installed."
elif [ -n "$TAVILY_API_KEY" ]; then
  echo "Tavily search skill already installed."
else
  echo "Tavily API key not set, skipping Tavily skill installation."
fi

# Set environment variables for OpenClaw
export OPENCLAW_STATE_DIR=/root/.openclaw
export OPENCLAW_WORKSPACE_DIR=/root/.openclaw/workspace
export OPENCLAW_CONFIG_PATH=/root/.openclaw/openclaw.json

# Set API keys via environment variables (OpenClaw reads these automatically)
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
export TAVILY_API_KEY="${TAVILY_API_KEY}"

echo "Starting OpenClaw gateway..."
echo "State dir: $OPENCLAW_STATE_DIR"
echo "Workspace dir: $OPENCLAW_WORKSPACE_DIR"
echo "Config path: $OPENCLAW_CONFIG_PATH"

# Start OpenClaw gateway
exec openclaw gateway
