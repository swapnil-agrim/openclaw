#!/bin/bash

# OpenClaw Deployment Status Check
# This script helps verify your deployment is working correctly

echo "╔════════════════════════════════════════════════════════╗"
echo "║       OpenClaw Deployment Status Check                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "openclaw.json" ]; then
    echo -e "${RED}❌ Error: openclaw.json not found${NC}"
    echo "Please run this script from the openclaw directory"
    exit 1
fi

echo "1️⃣  Checking Git Status..."
echo "─────────────────────────────────────────────────────────"
git status --short
echo ""

echo "2️⃣  Checking File Structure..."
echo "─────────────────────────────────────────────────────────"
files_ok=true

# Check critical files
if [ -f "Dockerfile" ]; then
    echo -e "${GREEN}✓${NC} Dockerfile exists"
else
    echo -e "${RED}✗${NC} Dockerfile missing"
    files_ok=false
fi

if [ -f "entrypoint.sh" ]; then
    echo -e "${GREEN}✓${NC} entrypoint.sh exists"
else
    echo -e "${RED}✗${NC} entrypoint.sh missing"
    files_ok=false
fi

if [ -f "openclaw.json" ]; then
    echo -e "${GREEN}✓${NC} openclaw.json exists"
else
    echo -e "${RED}✗${NC} openclaw.json missing"
    files_ok=false
fi

if [ -d "linkedin-scraper" ]; then
    echo -e "${GREEN}✓${NC} linkedin-scraper/ directory exists"
else
    echo -e "${RED}✗${NC} linkedin-scraper/ directory missing"
    files_ok=false
fi

echo ""

echo "3️⃣  Checking Configuration..."
echo "─────────────────────────────────────────────────────────"

# Check for proper directory usage in entrypoint.sh
if grep -q "mkdir -p /root/.openclaw/workspace/memory" entrypoint.sh; then
    echo -e "${GREEN}✓${NC} Memory created as directory (correct)"
else
    echo -e "${RED}✗${NC} Memory not created as directory"
fi

if grep -q "/root/.openclaw" entrypoint.sh; then
    echo -e "${GREEN}✓${NC} Uses /root/.openclaw paths"
else
    echo -e "${YELLOW}⚠${NC} May have path issues"
fi

# Validate JSON
if command -v jq &> /dev/null; then
    if jq empty openclaw.json 2>/dev/null; then
        echo -e "${GREEN}✓${NC} openclaw.json is valid JSON"
    else
        echo -e "${RED}✗${NC} openclaw.json has JSON errors"
    fi
else
    echo -e "${YELLOW}⚠${NC} jq not installed, skipping JSON validation"
fi

# Check for invalid keys
if grep -q "mcpServers" openclaw.json; then
    echo -e "${RED}✗${NC} openclaw.json contains invalid 'mcpServers' key"
else
    echo -e "${GREEN}✓${NC} No mcpServers key (correct)"
fi

if grep -q "apiKeys" openclaw.json; then
    echo -e "${RED}✗${NC} openclaw.json contains invalid 'apiKeys' key"
else
    echo -e "${GREEN}✓${NC} No apiKeys key (correct)"
fi

echo ""

echo "4️⃣  Checking Documentation..."
echo "─────────────────────────────────────────────────────────"
docs=("README.md" "DEPLOYMENT.md" "TROUBLESHOOTING.md" "MEMORY_PERSISTENCE.md" "SEARCH_INTEGRATION.md" "RAILWAY.md")

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✓${NC} $doc"
    else
        echo -e "${YELLOW}⚠${NC} $doc missing"
    fi
done

echo ""

echo "5️⃣  Summary"
echo "─────────────────────────────────────────────────────────"

if [ "$files_ok" = true ]; then
    echo -e "${GREEN}✓ All critical files present${NC}"
else
    echo -e "${RED}✗ Some files are missing${NC}"
fi

echo ""
echo "Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if there are uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 You have uncommitted changes:"
    echo ""
    echo "   git add -A"
    echo "   git commit -m \"Fix: Memory directory structure and path consistency\""
    echo "   git push origin main"
    echo ""
else
    echo -e "${GREEN}✓ All changes committed${NC}"
    echo ""
fi

echo "🚀 After pushing to Railway:"
echo ""
echo "   1. Check Railway logs:"
echo "      railway logs -s openclaw"
echo ""
echo "   2. Look for these SUCCESS indicators:"
echo "      ✓ Config created and environment variables replaced"
echo "      ✓ Installing SearXNG fallback skill..."
echo "      ✓ Installing LinkedIn research skill..."
echo "      ✓ Starting OpenClaw gateway..."
echo "      ✓ Gateway listening on 0.0.0.0:18789"
echo ""
echo "   3. Ignore these EXPECTED messages (they're normal):"
echo "      ⚠ 'pairing required' - Web UI auth (not used)"
echo "      ⚠ WebSocket closed - Normal connection handling"
echo ""
echo "   4. Test integrations:"
echo "      • Telegram: Send /start to your bot"
echo "      • Slack: Mention @YourBot in channel"
echo "      • Ask: \"What's the weather in San Francisco?\""
echo ""
echo "   5. Add Railway Volume (Important for memory persistence!):"
echo "      • Railway → openclaw service → Settings → Volumes"
echo "      • Mount path: /root/.openclaw"
echo "      • See MEMORY_PERSISTENCE.md for details"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Documentation:"
echo "   • Full deployment: DEPLOYMENT.md"
echo "   • Troubleshooting: TROUBLESHOOTING.md"
echo "   • Memory setup: MEMORY_PERSISTENCE.md"
echo "   • Search info: SEARCH_INTEGRATION.md"
echo ""
