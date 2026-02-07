#!/bin/bash
set -e

mkdir -p /data/.openclaw /data/workspace

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
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing"
    }
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

sed -i "s/\"mode\": \"token\"/\"mode\": \"token\",\n      \"token\": \"${OPENCLAW_GATEWAY_TOKEN}\"/" /data/.openclaw/openclaw.json

# Inject Telegram bot token if set
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  sed -i "s/\"enabled\": true/\"enabled\": true,\n      \"botToken\": \"${TELEGRAM_BOT_TOKEN}\"/" /data/.openclaw/openclaw.json
fi

echo "Config created."

exec openclaw gateway --port 18789 --verbose
