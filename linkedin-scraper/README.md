# LinkedIn Scraper Service

Express API service using Playwright to scrape LinkedIn search results for OpenClaw integration.

## Features

- 🔍 People search with profile details
- 🏢 Company search with industry info
- 🔐 Session persistence across restarts
- ⏱️ Rate limiting (30 requests/hour)
- 🎭 Browser automation with Playwright
- 💾 Cookie-based authentication

## API Endpoints

### POST /api/auth/login
Authenticate with LinkedIn credentials.

**Request:**
```json
{
  "email": "your-email@example.com",
  "password": "your-password"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully authenticated with LinkedIn"
}
```

### POST /api/search/people
Search for people on LinkedIn.

**Request:**
```json
{
  "query": "Software Engineer at Google"
}
```

**Response:**
```json
{
  "success": true,
  "query": "Software Engineer at Google",
  "count": 15,
  "results": [
    {
      "name": "John Doe",
      "title": "Senior Software Engineer at Google",
      "location": "San Francisco Bay Area",
      "profileUrl": "https://www.linkedin.com/in/johndoe"
    }
  ]
}
```

### POST /api/search/companies
Search for companies on LinkedIn.

**Request:**
```json
{
  "query": "AI startups San Francisco"
}
```

**Response:**
```json
{
  "success": true,
  "query": "AI startups San Francisco",
  "count": 12,
  "results": [
    {
      "name": "AI Startup Inc",
      "industry": "Artificial Intelligence",
      "location": "San Francisco, CA",
      "companyUrl": "https://www.linkedin.com/company/ai-startup"
    }
  ]
}
```

### GET /health
Check service health and rate limit status.

**Response:**
```json
{
  "success": true,
  "status": "healthy",
  "authenticated": true,
  "requestCount": 15,
  "requestsRemaining": 15,
  "resetTime": "2026-02-15T10:30:00.000Z"
}
```

## Local Development

### Prerequisites

- Node.js 18+
- npm or yarn

### Setup

```bash
# Install dependencies
npm install

# Install Playwright browsers
npx playwright install chromium

# Start server
npm start
```

Server runs on `http://localhost:3000`

### Authenticate

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password"
  }'
```

### Test Search

```bash
# Search people
curl -X POST http://localhost:3000/api/search/people \
  -H "Content-Type: application/json" \
  -d '{"query": "CEO"}'

# Search companies
curl -X POST http://localhost:3000/api/search/companies \
  -H "Content-Type: application/json" \
  -d '{"query": "tech companies"}'
```

## Docker Deployment

### Build

```bash
docker build -t linkedin-scraper .
```

### Run

```bash
docker run -p 3000:3000 linkedin-scraper
```

## Railway Deployment

1. Connect repository to Railway
2. Set root directory to `linkedin-scraper`
3. Railway will auto-detect Dockerfile
4. Generate domain and authenticate via `/api/auth/login`

## Configuration

### Environment Variables

```bash
PORT=3000                    # Server port (default: 3000)
```

### Rate Limiting

Configured in `index.js`:
```javascript
const MAX_REQUESTS_PER_HOUR = 30;
```

Adjust based on your LinkedIn account limits and usage needs.

### Session Persistence

Sessions are saved to `/tmp/linkedin-session.json` by default. For production with volumes:

```javascript
const SESSION_FILE = '/data/linkedin-session.json';
```

Mount volume at `/data` for persistent sessions across container restarts.

## Security Considerations

⚠️ **Important:**
- Use a dedicated LinkedIn account, not your personal account
- LinkedIn's Terms of Service may prohibit automated scraping
- This tool is for educational and research purposes
- Rate limiting protects against account suspension
- Store credentials securely, never commit to git

## Troubleshooting

### Session Expired (401 Error)
Re-authenticate using `/api/auth/login` endpoint.

### CAPTCHA Required
LinkedIn may show CAPTCHA. Handle manually:
1. Navigate to LinkedIn in browser
2. Complete CAPTCHA
3. Re-authenticate via API

### Rate Limit Exceeded (429 Error)
Wait for rate limit reset. Check `/health` endpoint for `resetTime`.

### No Results Returned
- Verify authentication is valid
- Check query is not too specific
- LinkedIn may have changed HTML structure (update selectors in `index.js`)

## Integration with OpenClaw

OpenClaw automatically connects to this service via the `linkedin-research` skill.

Set environment variable in OpenClaw:
```bash
LINKEDIN_SCRAPER_URL=https://your-scraper-url.railway.app
```

Use in OpenClaw chat:
```
Search LinkedIn for "AI researchers"
Find companies in "fintech industry"
```

## Technical Details

- **Browser**: Chromium via Playwright
- **User Agent**: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)
- **Delays**: Random 2-4 second delays between actions
- **Results**: Max 20 results per search
- **Timeout**: 10 second page load timeout

## License

MIT License - See LICENSE file for details

## Disclaimer

This tool is provided for educational purposes. Users are responsible for complying with LinkedIn's Terms of Service and applicable laws. The authors are not responsible for misuse or violations.
