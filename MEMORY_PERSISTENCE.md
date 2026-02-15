# Memory Persistence Guide

This guide explains how to persist OpenClaw's memory and conversation history across deployments on Railway.

## Problem

By default, when Railway redeploys your container:
- ❌ Conversation history is lost
- ❌ Memory files are erased
- ❌ Skills need to be reinstalled
- ❌ Agent context is reset

## Solution: Railway Volumes

Railway Volumes allow you to persist data across deployments.

## Setup Instructions

### Step 1: Add Volume to OpenClaw Service

1. Go to your Railway dashboard
2. Select your **openclaw** service
3. Click **Settings** tab
4. Scroll to **Volumes** section
5. Click **+ Add Volume**

### Step 2: Configure Volume

**Mount Path**: `/root/.openclaw`

This will persist:
- ✅ Configuration files
- ✅ Workspace and memory files
- ✅ Conversation history
- ✅ Installed skills (no reinstall needed)
- ✅ Session data

### Step 3: Redeploy

After adding the volume:
1. Railway will automatically redeploy
2. On first deployment with volume, skills will be installed
3. Memory files will be created
4. Future deployments will preserve all data

## What Gets Persisted

With the volume mounted at `/root/.openclaw`:

```
/root/.openclaw/
├── openclaw.json          # Configuration (regenerated on each start)
├── workspace/             # ✅ PERSISTED
│   ├── memory/            # Agent memory directory
│   ├── MEMORY.md          # Conversation summaries
│   └── <other files>      # Any files created by agent
└── skills/                # ✅ PERSISTED
    ├── searxng-fallback/  # SearXNG skill (not reinstalled)
    └── linkedin-research/ # LinkedIn skill (not reinstalled)
```

## Verify Persistence

After setting up the volume, test it:

### Test 1: Create a Memory

Via Telegram/Slack:
```
Remember that my favorite color is blue
```

### Test 2: Redeploy

Trigger a redeploy:
```bash
# Make a small change and push
git commit --allow-empty -m "Test memory persistence"
git push origin main
```

### Test 3: Check Memory Persists

After redeployment, ask:
```
What's my favorite color?
```

If the volume is working, the agent will remember it's blue.

## Volume Benefits

### 1. Faster Deployments
- Skills don't need to reinstall (saves ~30 seconds)
- No npm install on every deployment

### 2. Persistent Memory
- Agent remembers past conversations
- Context carries over between sessions
- Workspace files are preserved

### 3. Better Experience
- Users don't need to re-pair on Telegram/Slack
- Preferences and settings persist
- Smoother continuity

## Volume Size

Default volume size: **1 GB** (plenty for OpenClaw)

Storage used:
- Skills: ~5-10 MB
- Memory/Workspace: ~10-50 MB
- Total: Usually < 100 MB

## Important Notes

### Config File Regeneration

The `openclaw.json` file is **regenerated on each startup** from environment variables:
- This is intentional
- Ensures config stays in sync with Railway env vars
- Memory and workspace files are **never** overwritten

### Skills Installation

With volume:
```bash
# First deployment
Installing SearXNG fallback skill...
Installing LinkedIn research skill...

# Subsequent deployments (skills already exist)
# Skipped - skills already installed
```

### Clearing Persisted Data

To start fresh:

**Option 1: Delete Volume**
1. Railway → Service → Settings → Volumes
2. Delete volume
3. Redeploy

**Option 2: SSH and Clear**
```bash
railway shell -s openclaw
rm -rf /root/.openclaw/workspace/*
rm -rf /root/.openclaw/skills/*
exit
# Redeploy to reinstall skills
```

## Memory File Locations

### Primary Memory Files

**Short-term memory directory:**
```
/root/.openclaw/workspace/memory/
```

**Long-term memory/summaries:**
```
/root/.openclaw/workspace/MEMORY.md
```

### Accessing Memory Files

Via Railway SSH:
```bash
# SSH into container
railway shell -s openclaw

# View memory directory
ls -la /root/.openclaw/workspace/memory/

# View long-term memory
cat /root/.openclaw/workspace/MEMORY.md

# List workspace files
ls -la /root/.openclaw/workspace/
```

## Backup Memory (Optional)

To backup your agent's memory locally:

```bash
# Download memory file
railway run -s openclaw cat /root/.openclaw/workspace/MEMORY.md > backup.md

# Download entire workspace
railway run -s openclaw tar -czf - /root/.openclaw/workspace | tar -xzf -
```

## Restore Memory (Optional)

To restore memory to a new deployment:

```bash
# SSH into container
railway shell -s openclaw

# Create/update memory file
cat > /root/.openclaw/workspace/MEMORY.md << 'EOF'
Your backed up memory content here...
EOF
```

## Troubleshooting

### Memory not persisting

**Check volume is mounted:**
```bash
railway shell -s openclaw
df -h | grep openclaw
```

Should show:
```
/dev/vdb  1.0G  100M  900M  10%  /root/.openclaw
```

**Check permissions:**
```bash
railway shell -s openclaw
ls -la /root/.openclaw/workspace/
```

Should show files owned by root.

### Skills reinstalling every time

**Problem**: Volume not mounted or wrong mount path

**Solution**:
1. Verify mount path is `/root/.openclaw` (not `/home/node/.openclaw`)
2. Check Railway → Settings → Volumes

### Out of space

**Symptoms**:
```
ENOSPC: no space left on device
```

**Solution**:
1. Railway → Settings → Volumes
2. Increase volume size (default 1GB → 2GB)

## Summary

✅ **Mount volume at**: `/root/.openclaw`
✅ **Persists**: Memory, workspace, skills
✅ **Regenerated**: openclaw.json (from env vars)
✅ **Benefit**: Faster deployments, persistent context
✅ **Size needed**: 1 GB (default is fine)

Your agent will now maintain memory and context across all deployments!

---

**Last Updated**: 2026-02-15
