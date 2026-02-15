#!/bin/bash

# LinkedIn Scraper Deployment Check
# This script helps verify your LinkedIn scraper deployment

echo "╔════════════════════════════════════════════════════════╗"
echo "║       LinkedIn Scraper Status Check                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

SCRAPER_URL="${1:-$LINKEDIN_SCRAPER_URL}"

if [ -z "$SCRAPER_URL" ]; then
    echo "Usage: ./check-linkedin-scraper.sh <scraper-url>"
    echo ""
    echo "Or set LINKEDIN_SCRAPER_URL environment variable"
    echo ""
    echo "Example:"
    echo "  ./check-linkedin-scraper.sh https://linkedin-scraper-production.up.railway.app"
    exit 1
fi

echo "Testing LinkedIn scraper at: $SCRAPER_URL"
echo "─────────────────────────────────────────────────────────"
echo ""

# Test health endpoint
echo "1️⃣  Testing /health endpoint..."
HEALTH_RESPONSE=$(curl -s "$SCRAPER_URL/health" 2>&1)
HEALTH_STATUS=$?

if [ $HEALTH_STATUS -eq 0 ]; then
    if echo "$HEALTH_RESPONSE" | grep -q '"success":true'; then
        echo "✅ LinkedIn scraper is healthy"
        echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"

        # Check authentication status
        if echo "$HEALTH_RESPONSE" | grep -q '"authenticated":true'; then
            echo ""
            echo "✅ LinkedIn scraper is authenticated"
        else
            echo ""
            echo "⚠️  LinkedIn scraper needs authentication"
            echo ""
            echo "Run this command to authenticate:"
            echo ""
            echo "curl -X POST $SCRAPER_URL/api/auth/login \\"
            echo "  -H 'Content-Type: application/json' \\"
            echo "  -d '{\"email\": \"your-email@example.com\", \"password\": \"your-password\"}'"
        fi
    else
        echo "❌ Unexpected response from /health"
        echo "$HEALTH_RESPONSE"
    fi
else
    echo "❌ Failed to connect to LinkedIn scraper"
    echo "Error: $HEALTH_RESPONSE"
    echo ""
    echo "This could mean:"
    echo "  1. LinkedIn scraper is not deployed"
    echo "  2. URL is incorrect"
    echo "  3. Service is down"
fi

echo ""
echo "─────────────────────────────────────────────────────────"
echo ""

# Check if it's pointing to OpenClaw instead
echo "2️⃣  Checking if URL points to OpenClaw (common mistake)..."
if echo "$HEALTH_RESPONSE" | grep -q "OpenClaw\|Method Not Allowed\|405"; then
    echo "❌ ERROR: This URL points to OpenClaw, not the LinkedIn scraper!"
    echo ""
    echo "Current URL: $SCRAPER_URL"
    echo ""
    echo "You need to:"
    echo "  1. Deploy the linkedin-scraper/ directory as a SEPARATE Railway service"
    echo "  2. Get the URL of that new service"
    echo "  3. Update LINKEDIN_SCRAPER_URL to point to it"
    echo ""
    echo "See DEPLOYMENT.md for step-by-step instructions."
else
    echo "✅ URL does not point to OpenClaw"
fi

echo ""
echo "─────────────────────────────────────────────────────────"
echo ""
echo "Summary:"
echo ""

if [ $HEALTH_STATUS -eq 0 ] && echo "$HEALTH_RESPONSE" | grep -q '"success":true'; then
    echo "✅ LinkedIn scraper is deployed correctly"

    if echo "$HEALTH_RESPONSE" | grep -q '"authenticated":true'; then
        echo "✅ Ready to use!"
    else
        echo "⚠️  Needs authentication (see command above)"
    fi
else
    echo "❌ LinkedIn scraper is NOT working"
    echo ""
    echo "Next steps:"
    echo "  1. Check if linkedin-scraper service is deployed in Railway"
    echo "  2. Verify LINKEDIN_SCRAPER_URL points to the correct service"
    echo "  3. Check Railway logs: railway logs -s linkedin-scraper"
fi

echo ""
