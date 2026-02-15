FROM node:22-bookworm

RUN apt-get update && apt-get install -y \
    git python3 make g++ curl \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw@latest

# Use /root since container runs as root by default
ENV OPENCLAW_STATE_DIR=/root/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/root/.openclaw/workspace
ENV OPENCLAW_CONFIG_PATH=/root/.openclaw/openclaw.json

EXPOSE 18789

WORKDIR /app

COPY openclaw.json /app/openclaw.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
