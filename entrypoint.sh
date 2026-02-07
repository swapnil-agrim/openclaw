#!/bin/bash
set -e

mkdir -p /data/.openclaw /data/workspace

if [ ! -f /data/.openclaw/openclaw.json ]; then
  cat <<EOF > /data/.openclaw/openclaw.json
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
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
EOF
  echo "Config created."
fi

exec openclaw gateway --port 18789 --verbose
