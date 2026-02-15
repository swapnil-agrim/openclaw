#!/bin/bash
set -e

# Create OpenClaw directories
mkdir -p /home/node/.openclaw /data/workspace

# Copy and process config file
cp /app/openclaw.json /home/node/.openclaw/openclaw.json

# Replace environment variables in config
sed -i "s|\${TELEGRAM_BOT_TOKEN}|${TELEGRAM_BOT_TOKEN}|g" /home/node/.openclaw/openclaw.json
sed -i "s|\${SLACK_BOT_TOKEN}|${SLACK_BOT_TOKEN}|g" /home/node/.openclaw/openclaw.json
sed -i "s|\${SLACK_APP_TOKEN}|${SLACK_APP_TOKEN}|g" /home/node/.openclaw/openclaw.json
sed -i "s|\${SLACK_ALLOWED_CHANNEL}|${SLACK_ALLOWED_CHANNEL}|g" /home/node/.openclaw/openclaw.json
sed -i "s|\${OPENCLAW_GATEWAY_TOKEN}|${OPENCLAW_GATEWAY_TOKEN}|g" /home/node/.openclaw/openclaw.json

echo "Config created and environment variables replaced."

# Install SearXNG Fallback Skill
SEARXNG_SKILL_DIR="/home/node/.openclaw/skills/searxng-fallback"
if [ ! -d "$SEARXNG_SKILL_DIR" ]; then
  echo "Installing SearXNG fallback skill..."
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

const SEARXNG_INSTANCES = [
  'https://searx.be',
  'https://search.bus-hit.me',
  'https://searx.work'
];

async function searchSearXNG(instance, query) {
  const url = `${instance}/search?q=${encodeURIComponent(query)}&format=json&categories=general`;

  const response = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; OpenClaw/1.0)'
    },
    timeout: 10000
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  return await response.json();
}

async function search(query) {
  for (const instance of SEARXNG_INSTANCES) {
    try {
      console.error(`Trying ${instance}...`);
      const data = await searchSearXNG(instance, query);

      const results = (data.results || []).slice(0, 10).map(r => ({
        title: r.title,
        url: r.url,
        snippet: r.content || r.description || ''
      }));

      console.log(JSON.stringify({
        success: true,
        instance,
        count: results.length,
        results
      }, null, 2));

      return;
    } catch (error) {
      console.error(`Failed with ${instance}: ${error.message}`);
    }
  }

  console.error('All SearXNG instances failed');
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
fi

# Install LinkedIn Research Skill
LINKEDIN_SKILL_DIR="/home/node/.openclaw/skills/linkedin-research"
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

# Set environment variables for OpenClaw
export OPENCLAW_STATE_DIR=/home/node/.openclaw
export OPENCLAW_WORKSPACE_DIR=/data/workspace
export OPENCLAW_CONFIG_PATH=/home/node/.openclaw/openclaw.json

# Set API keys via environment variables (OpenClaw reads these automatically)
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
export TAVILY_API_KEY="${TAVILY_API_KEY}"

# Start OpenClaw gateway
echo "Starting OpenClaw gateway..."
exec openclaw gateway
