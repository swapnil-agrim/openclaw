#!/bin/bash
set -e

mkdir -p /data/.openclaw /data/workspace

# Force recreate config (remove this rm line after first successful deploy)
rm -f /data/.openclaw/openclaw.json

cat <<EOF > /data/.openclaw/openclaw.json
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
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-haiku-4-5-20251001"
      }
    }
  }
}
