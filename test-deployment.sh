#!/bin/bash

# OpenClaw Deployment Testing Script
# Usage: ./test-deployment.sh <linkedin-scraper-url> <openclaw-url>

set -e

LINKEDIN_URL="${1}"
OPENCLAW_URL="${2}"

if [ -z "$LINKEDIN_URL" ] || [ -z "$OPENCLAW_URL" ]; then
  echo "Usage: ./test-deployment.sh <linkedin-scraper-url> <openclaw-url>"
  echo ""
  echo "Example:"
  echo "  ./test-deployment.sh https://linkedin-scraper.railway.app https://openclaw.railway.app"
  exit 1
fi

echo "🧪 Testing OpenClaw Deployment"
echo "================================"
echo ""

# Test LinkedIn Scraper Health
echo "1️⃣  Testing LinkedIn Scraper Health..."
HEALTH_RESPONSE=$(curl -s "${LINKEDIN_URL}/health")
if echo "$HEALTH_RESPONSE" | grep -q '"success":true'; then
  echo "✅ LinkedIn scraper is healthy"
  echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
else
  echo "❌ LinkedIn scraper health check failed"
  echo "$HEALTH_RESPONSE"
fi
echo ""

# Test OpenClaw Health (if endpoint exists)
echo "2️⃣  Testing OpenClaw Endpoint..."
OPENCLAW_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${OPENCLAW_URL}/health" 2>/dev/null || echo "N/A")
if [ "$OPENCLAW_RESPONSE" = "200" ]; then
  echo "✅ OpenClaw is responding"
elif [ "$OPENCLAW_RESPONSE" = "N/A" ]; then
  echo "ℹ️  OpenClaw health endpoint not available (this is normal)"
else
  echo "⚠️  OpenClaw returned HTTP ${OPENCLAW_RESPONSE}"
fi
echo ""

# Test LinkedIn Authentication Status
echo "3️⃣  Checking LinkedIn Authentication..."
AUTH_STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.authenticated' 2>/dev/null || echo "unknown")
if [ "$AUTH_STATUS" = "true" ]; then
  echo "✅ LinkedIn scraper is authenticated"
  REQUESTS_REMAINING=$(echo "$HEALTH_RESPONSE" | jq -r '.requestsRemaining' 2>/dev/null || echo "unknown")
  echo "   Requests remaining: ${REQUESTS_REMAINING}/30"
elif [ "$AUTH_STATUS" = "false" ]; then
  echo "❌ LinkedIn scraper needs authentication"
  echo ""
  echo "Run the following command to authenticate:"
  echo ""
  echo "curl -X POST ${LINKEDIN_URL}/api/auth/login \\"
  echo "  -H 'Content-Type: application/json' \\"
  echo "  -d '{\"email\": \"your-email@example.com\", \"password\": \"your-password\"}'"
else
  echo "⚠️  Could not determine authentication status"
fi
echo ""

# Summary
echo "================================"
echo "📋 Test Summary"
echo "================================"
echo ""
echo "LinkedIn Scraper URL: ${LINKEDIN_URL}"
echo "OpenClaw URL: ${OPENCLAW_URL}"
echo ""
echo "Next Steps:"
echo "1. If LinkedIn is not authenticated, run the auth command above"
echo "2. Test Telegram: Send /start to your bot"
echo "3. Test Slack: Mention @YourBot in your allowed channel"
echo "4. Test search: Ask 'What's the weather in San Francisco?'"
echo "5. Test LinkedIn: Ask 'Find LinkedIn profiles for AI engineers'"
echo ""
echo "📚 Full documentation: DEPLOYMENT.md"
