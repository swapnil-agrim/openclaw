# OpenClaw - AI Agent Platform

Production-ready OpenClaw deployment with Telegram, Slack, Tavily search, SearXNG fallback, and LinkedIn research capabilities.

## 🚀 Features

- **Multi-Channel Support**: Telegram and Slack integration
- **Intelligent Search**: Tavily API (primary) with SearXNG fallback (unlimited free)
- **LinkedIn Research**: Automated people and company search
- **Railway Optimized**: Ready-to-deploy Docker configuration
- **Auto-Installing Skills**: SearXNG and LinkedIn skills install on startup
- **Claude Sonnet 4.5**: Powered by the latest Anthropic models

## 📋 Architecture

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

## 🛠️ Components

### OpenClaw Service
- **Location**: Root directory
- **Files**: `Dockerfile`, `entrypoint.sh`, `openclaw.json`
- **Integrations**: Telegram, Slack, Tavily, SearXNG, LinkedIn
- **Auto-installs skills on startup**

### LinkedIn Scraper Service
- **Location**: `linkedin-scraper/`
- **Files**: `index.js`, `package.json`, `Dockerfile`
- **Technology**: Express + Playwright
- **Rate Limit**: 30 requests/hour

## 📦 Quick Start

### Prerequisites

- Railway account
- Anthropic API key
- Tavily API key (free tier: 1000 searches/month)
- Telegram bot token (from @BotFather)
- Slack bot tokens (bot token + app token)
- LinkedIn account (for scraper authentication)

### Deployment

**See [DEPLOYMENT.md](./DEPLOYMENT.md) for complete step-by-step instructions.**

Quick summary:
1. Deploy LinkedIn scraper to Railway
2. Authenticate with your LinkedIn account
3. Deploy OpenClaw service to Railway
4. Configure environment variables
5. Test integrations

## 🔧 Environment Variables

### OpenClaw Service

```bash
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
OPENCLAW_GATEWAY_TOKEN=your-strong-random-token
TAVILY_API_KEY=tvly-xxxxx
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
SLACK_BOT_TOKEN=xoxb-xxxxx
SLACK_APP_TOKEN=xapp-xxxxx
SLACK_ALLOWED_CHANNEL=C1234567890
LINKEDIN_SCRAPER_URL=https://your-scraper.railway.app
```

### LinkedIn Scraper Service

```bash
PORT=3000
```

## 📖 Skills

### SearXNG Fallback
- **Auto-installed** on container startup
- **Free unlimited searches** using public SearXNG instances
- **Fallback instances**: searx.be, search.bus-hit.me, searx.work
- **No API key required**

### LinkedIn Research
- **Auto-installed** on container startup
- **People search**: name, title, location, profile URL
- **Company search**: name, industry, location, company URL
- **Rate limited** to protect your account

## 🧪 Testing

### Telegram
```
1. Find your bot on Telegram
2. Send: /start
3. Try: "What's the weather in San Francisco?"
```

### Slack
```
1. Invite bot: /invite @YourBotName
2. Mention: @YourBotName What's trending in AI?
```

### LinkedIn Research
```
Via Telegram/Slack:
"Find LinkedIn profiles for Machine Learning Engineers at Google"
"Search LinkedIn companies for AI startups in San Francisco"
```

## 📁 Project Structure

```
openclaw/
├── Dockerfile                    # OpenClaw container
├── entrypoint.sh                # Skills auto-install + config
├── openclaw.json                # OpenClaw configuration
├── DEPLOYMENT.md                # Complete deployment guide
├── linkedin-scraper/            # Separate LinkedIn service
│   ├── Dockerfile              # Playwright container
│   ├── index.js                # Express API server
│   ├── package.json            # Dependencies
│   ├── .gitignore              # Git ignore
│   └── README.md               # LinkedIn scraper docs
└── README.md                    # This file
```

## 🔐 Security

- Environment variables stored securely in Railway
- LinkedIn session persistence with cookie-based auth
- Rate limiting on LinkedIn API (30 req/hour)
- Strong gateway token required for OpenClaw access
- Dedicated LinkedIn account recommended

## 💰 Cost Estimation

**Railway** (~$10-15/month):
- OpenClaw service: ~$5/month
- LinkedIn scraper: ~$5-10/month

**APIs**:
- Anthropic (Claude Sonnet 4.5): $20-50/month (moderate usage)
- Tavily: Free tier (1000 searches/month)
- SearXNG: Free (unlimited)

**Total**: ~$30-100/month depending on usage

## 📚 Documentation

- **[DEPLOYMENT.md](./DEPLOYMENT.md)**: Complete Railway deployment guide
- **[linkedin-scraper/README.md](./linkedin-scraper/README.md)**: LinkedIn scraper API docs
- **[OpenClaw Docs](https://github.com/openclaw/openclaw)**: Official OpenClaw documentation

## 🐛 Troubleshooting

### Telegram bot not responding
- Check `TELEGRAM_BOT_TOKEN` is correct
- Verify bot is not running elsewhere
- Check logs in Railway dashboard

### LinkedIn scraper returns 401
- Re-authenticate via `/api/auth/login`
- Session may have expired
- LinkedIn may require CAPTCHA (handle manually)

### Skills not found
- Check entrypoint.sh logs during startup
- Verify npm install succeeded
- Skills location: `/home/node/.openclaw/skills/`

### Tavily search fails
- SearXNG fallback activates automatically
- Check `TAVILY_API_KEY` is valid
- Verify Tavily quota at [tavily.com](https://tavily.com)

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details

## ⚠️ Disclaimer

**LinkedIn Scraper**: This tool is for educational and research purposes. Users are responsible for complying with LinkedIn's Terms of Service. The authors are not responsible for misuse or violations.

## 🔗 Links

- **Repository**: https://github.com/swapnil-agrim/openclaw
- **Railway**: https://railway.app
- **OpenClaw**: https://github.com/openclaw/openclaw
- **Anthropic**: https://www.anthropic.com
- **Tavily**: https://tavily.com

---

**Built with ❤️ for the OpenClaw community**
