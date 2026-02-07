#!/bin/bash
set -e

mkdir -p /data/.openclaw /data/workspace

rm -f /data/.openclaw/openclaw.json

cat > /data/.openclaw/openclaw.json << 'JSONEOF'
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": 18789,
    "controlUi": {
      "enabled": true,
      "allowInsecureAuth": true
    },
    "auth": {
      "mode": "token"
    },
    "trustedProxies": ["0.0.0.0/0"]
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-haiku-4-5-20251001"
      }
    }
  }
}
JSONEOF

# Inject token from env var
sed -i "s/\"mode\": \"token\"/\"mode\": \"token\",\n      \"token\": \"${OPENCLAW_GATEWAY_TOKEN}\"/" /data/.openclaw/openclaw.json

echo "Config created."

exec openclaw gateway --port 18789 --verbose
