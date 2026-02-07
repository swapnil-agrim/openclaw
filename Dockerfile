FROM node:22-bookworm

# Install system deps (git is usually present in bookworm, but ensure)
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    make \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw globally
RUN npm install -g openclaw@latest

# Set persistent state and workspace dirs (will mount volume here)
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/workspace

# Create data directory
RUN mkdir -p /data/.openclaw /data/workspace

# Expose gateway port
EXPOSE 18789

COPY openclaw.json /data/.openclaw/openclaw.json
CMD ["openclaw", "gateway", "--port", "18789", "--verbose"]
