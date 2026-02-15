import express from 'express';
import { chromium } from 'playwright';
import fs from 'fs/promises';

const app = express();
app.use(express.json());

const SESSION_FILE = '/tmp/linkedin-session.json';
const PORT = process.env.PORT || 3000;
const MAX_REQUESTS_PER_HOUR = 30;

let browser = null;
let context = null;
let requestCount = 0;
let resetTime = Date.now() + 3600000; // 1 hour from now

// Rate limiting middleware
function rateLimitCheck(req, res, next) {
  if (Date.now() > resetTime) {
    requestCount = 0;
    resetTime = Date.now() + 3600000;
  }

  if (requestCount >= MAX_REQUESTS_PER_HOUR) {
    return res.status(429).json({
      success: false,
      error: 'Rate limit exceeded. Maximum 30 requests per hour.',
      resetTime: new Date(resetTime).toISOString()
    });
  }

  requestCount++;
  next();
}

// Initialize browser
async function initBrowser() {
  if (browser) return;

  browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  // Try to load existing session
  try {
    const sessionData = await fs.readFile(SESSION_FILE, 'utf-8');
    const cookies = JSON.parse(sessionData);
    context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    });
    await context.addCookies(cookies);
    console.log('Loaded existing LinkedIn session');
  } catch (error) {
    console.log('No existing session found, creating new context');
    context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    });
  }
}

// Save session
async function saveSession() {
  if (!context) return;
  const cookies = await context.cookies();
  await fs.writeFile(SESSION_FILE, JSON.stringify(cookies, null, 2));
  console.log('Session saved');
}

// Health check
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'healthy',
    authenticated: context !== null,
    requestCount,
    requestsRemaining: Math.max(0, MAX_REQUESTS_PER_HOUR - requestCount),
    resetTime: new Date(resetTime).toISOString()
  });
});

// Login endpoint
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      error: 'Email and password required'
    });
  }

  try {
    await initBrowser();

    const page = await context.newPage();
    await page.goto('https://www.linkedin.com/login', { waitUntil: 'networkidle' });

    await page.fill('#username', email);
    await page.fill('#password', password);
    await page.click('button[type="submit"]');

    // Wait for navigation
    await page.waitForTimeout(3000);

    // Check if login was successful
    const url = page.url();
    if (url.includes('/feed') || url.includes('/mynetwork')) {
      await saveSession();
      await page.close();

      res.json({
        success: true,
        message: 'Successfully authenticated with LinkedIn'
      });
    } else {
      await page.close();
      res.status(401).json({
        success: false,
        error: 'Authentication failed. Check credentials or handle CAPTCHA manually.'
      });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Search people
app.post('/api/search/people', rateLimitCheck, async (req, res) => {
  const { query } = req.body;

  if (!query) {
    return res.status(400).json({
      success: false,
      error: 'Query parameter required'
    });
  }

  try {
    await initBrowser();

    const page = await context.newPage();
    const searchUrl = `https://www.linkedin.com/search/results/people/?keywords=${encodeURIComponent(query)}`;

    await page.goto(searchUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000 + Math.random() * 2000);

    // Check if we're on the search results page
    const currentUrl = page.url();
    if (currentUrl.includes('/login') || currentUrl.includes('/checkpoint')) {
      await page.close();
      return res.status(401).json({
        success: false,
        error: 'Not authenticated. Please login first using /api/auth/login'
      });
    }

    // Extract people results
    const results = await page.evaluate(() => {
      const items = [];
      const resultCards = document.querySelectorAll('.reusable-search__result-container');

      resultCards.forEach(card => {
        try {
          const nameElement = card.querySelector('.entity-result__title-text a span[aria-hidden="true"]');
          const titleElement = card.querySelector('.entity-result__primary-subtitle');
          const locationElement = card.querySelector('.entity-result__secondary-subtitle');
          const linkElement = card.querySelector('.entity-result__title-text a');

          const name = nameElement?.textContent?.trim() || '';
          const title = titleElement?.textContent?.trim() || '';
          const location = locationElement?.textContent?.trim() || '';
          const profileUrl = linkElement?.href || '';

          if (name) {
            items.push({
              name,
              title,
              location,
              profileUrl: profileUrl.split('?')[0] // Remove query params
            });
          }
        } catch (e) {
          // Skip items that fail to parse
        }
      });

      return items;
    });

    await page.close();

    const filteredResults = results.filter(p => p.name).slice(0, 20);

    res.json({
      success: true,
      query,
      count: filteredResults.length,
      results: filteredResults
    });
  } catch (error) {
    console.error('People search error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Search companies
app.post('/api/search/companies', rateLimitCheck, async (req, res) => {
  const { query } = req.body;

  if (!query) {
    return res.status(400).json({
      success: false,
      error: 'Query parameter required'
    });
  }

  try {
    await initBrowser();

    const page = await context.newPage();
    const searchUrl = `https://www.linkedin.com/search/results/companies/?keywords=${encodeURIComponent(query)}`;

    await page.goto(searchUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000 + Math.random() * 2000);

    // Check if we're on the search results page
    const currentUrl = page.url();
    if (currentUrl.includes('/login') || currentUrl.includes('/checkpoint')) {
      await page.close();
      return res.status(401).json({
        success: false,
        error: 'Not authenticated. Please login first using /api/auth/login'
      });
    }

    // Extract company results
    const results = await page.evaluate(() => {
      const items = [];
      const resultCards = document.querySelectorAll('.reusable-search__result-container');

      resultCards.forEach(card => {
        try {
          const nameElement = card.querySelector('.entity-result__title-text a span[aria-hidden="true"]');
          const industryElement = card.querySelector('.entity-result__primary-subtitle');
          const locationElement = card.querySelector('.entity-result__secondary-subtitle');
          const linkElement = card.querySelector('.entity-result__title-text a');

          const name = nameElement?.textContent?.trim() || '';
          const industry = industryElement?.textContent?.trim() || '';
          const location = locationElement?.textContent?.trim() || '';
          const companyUrl = linkElement?.href || '';

          if (name) {
            items.push({
              name,
              industry,
              location,
              companyUrl: companyUrl.split('?')[0] // Remove query params
            });
          }
        } catch (e) {
          // Skip items that fail to parse
        }
      });

      return items;
    });

    await page.close();

    const filteredResults = results.filter(c => c.name).slice(0, 20);

    res.json({
      success: true,
      query,
      count: filteredResults.length,
      results: filteredResults
    });
  } catch (error) {
    console.error('Company search error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  if (context) await saveSession();
  if (browser) await browser.close();
  process.exit(0);
});

// Start server
app.listen(PORT, async () => {
  console.log(`LinkedIn scraper running on port ${PORT}`);
  await initBrowser();
});
