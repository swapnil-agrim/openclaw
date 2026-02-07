#!/bin/bash
set -e

mkdir -p /data/.openclaw /data/workspace

rm -f /data/.openclaw/openclaw.json

cat > /data/.openclaw/openclaw.json << JSONEOF
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
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN}"
    },
    "trustedProxies": ["0.0.0.0/0"]
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "pairing"
    },
    "slack": {
      "enabled": true,
      "botToken": "${SLACK_BOT_TOKEN}",
      "appToken": "${SLACK_APP_TOKEN}",
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "channels": {
        "${SLACK_ALLOWED_CHANNEL}": {
          "allow": true,
          "requireMention": true
        }
      }
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

echo "Config created."

exec openclaw gateway --port 18789 --verbose
