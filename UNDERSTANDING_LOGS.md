# Understanding OpenClaw Logs

This guide helps you interpret Railway logs and identify what's normal vs. what needs attention.

## ✅ Normal / Expected Messages

These messages appear in logs but are **completely normal** and don't indicate problems:

### 1. "pairing required" Messages

```
gateway connect failed: Error: pairing required
[ws] closed before connect ... code=1008 reason=pairing required
```

**What this means:**
- The web UI is trying to connect without authentication
- This is expected behavior when `controlUi.allowInsecureAuth: true`
- Your Telegram and Slack integrations work independently

**Action needed:** ✅ None - this is normal

---

### 2. WebSocket Closed Messages

```
[ws] closed before connect conn=xxxxx remote=10.x.x.x
```

**What this means:**
- Normal connection lifecycle events
- Connections opening and closing as expected
- Internal health checks and monitoring

**Action needed:** ✅ None - this is normal

---

### 3. Gateway Target Messages

```
Gateway target: ws://10.x.x.x:18789
Source: local lan 10.x.x.x
Config: /root/.openclaw/openclaw.json
Bind: lan
```

**What this means:**
- Gateway is properly configured
- Listening on the correct address
- Config file found and loaded

**Action needed:** ✅ None - this is normal

---

## ✅ SUCCESS Indicators

Look for these messages to confirm everything is working:

### Startup Sequence

```
Config created and environment variables replaced.
State dir: /root/.openclaw
Workspace dir: /root/.openclaw/workspace
Config path: /root/.openclaw/openclaw.json
Installing SearXNG fallback skill...
SearXNG skill installed.
Installing LinkedIn research skill...
LinkedIn research skill installed.
Starting OpenClaw gateway...
✓ Gateway listening on 0.0.0.0:18789
```

**What this means:** ✅ Perfect startup

---

### Channel Connections

```
[telegram] connected
[slack] connected
```

**What this means:** ✅ Integrations working

---

### Message Handling

```
[telegram] received message from user:123456
[agent/embedded] processing message
[slack] delivered reply to channel:C12345
```

**What this means:** ✅ Bot is responding to messages

---

## ⚠️ Warning Messages (Usually OK)

These indicate minor issues that often resolve themselves:

### Skills Already Installed

```
# No "Installing X skill..." messages on subsequent deployments
```

**What this means:**
- Skills already exist (from volume persistence)
- Faster startup time
- Working as intended

**Action needed:** ✅ None if using Railway volume

---

### Read Tool Without Path

```
[agent/embedded] read tool called without path: toolCallId=toolu_xxx
```

**What this means:**
- Agent tried to read without specifying a file
- Usually recovers and asks for clarification

**Action needed:** ⚠️ Monitor - may need to clarify request to agent

---

## 🚨 ERROR Messages (Need Attention)

These indicate actual problems:

### Config Invalid

```
Config invalid
- agents.defaults: Unrecognized key: "apiKeys"
- <root>: Unrecognized key: "mcpServers"
```

**What this means:** ❌ Configuration file has invalid keys

**Action needed:**
1. Pull latest code (this is already fixed)
2. Redeploy

---

### Memory File Errors

```
[tools] write failed: EEXIST: file already exists, mkdir '/root/.openclaw/workspace/memory'
[tools] read failed: ENOENT: no such file or directory, access '/root/.openclaw/workspace/memory'
```

**What this means:** ❌ Memory structure incorrect

**Action needed:**
1. Pull latest code (this is already fixed)
2. Delete Railway volume if exists
3. Redeploy

---

### Environment Variable Missing

```
Error: TELEGRAM_BOT_TOKEN is required
Error: ANTHROPIC_API_KEY not set
```

**What this means:** ❌ Required env var not configured

**Action needed:**
1. Go to Railway → Service → Variables
2. Add missing environment variable
3. Redeploy

---

### Telegram/Slack Connection Failed

```
[telegram] connection failed: unauthorized
[slack] connection failed: invalid_auth
```

**What this means:** ❌ Invalid bot tokens

**Action needed:**
1. Verify tokens are correct
2. Check tokens haven't expired
3. Update Railway env vars
4. Redeploy

---

### LinkedIn Scraper Unreachable

```
Error: LINKEDIN_SCRAPER_URL environment variable not set
fetch failed: connect ECONNREFUSED
```

**What this means:** ❌ Can't connect to LinkedIn scraper

**Action needed:**
1. Verify LinkedIn scraper is deployed
2. Check `LINKEDIN_SCRAPER_URL` is set correctly
3. Test: `curl https://your-scraper-url/health`

---

## Log Filtering Tips

### View Only Errors

```bash
railway logs -s openclaw | grep -i "error\|failed\|invalid"
```

### View Only Success Messages

```bash
railway logs -s openclaw | grep -i "connected\|installed\|listening\|success"
```

### View Telegram Messages

```bash
railway logs -s openclaw | grep -i "telegram"
```

### View Slack Messages

```bash
railway logs -s openclaw | grep -i "slack"
```

### View Agent Activity

```bash
railway logs -s openclaw | grep -i "agent"
```

### Follow Logs in Real-Time

```bash
railway logs -s openclaw --follow
```

---

## Deployment Health Checklist

After deployment, verify these in logs:

- [ ] ✅ "Config created and environment variables replaced"
- [ ] ✅ "SearXNG skill installed" (first deploy) or skipped (with volume)
- [ ] ✅ "LinkedIn research skill installed" (first deploy) or skipped (with volume)
- [ ] ✅ "Gateway listening on 0.0.0.0:18789"
- [ ] ✅ No "Config invalid" errors
- [ ] ✅ No "ENOENT" or "EEXIST" errors
- [ ] ⚠️ "pairing required" messages are OK (ignore these)
- [ ] ⚠️ WebSocket closed messages are OK (ignore these)

---

## Common Log Scenarios

### Scenario 1: Perfect Deployment

```
Config created and environment variables replaced.
State dir: /root/.openclaw
Workspace dir: /root/.openclaw/workspace
Config path: /root/.openclaw/openclaw.json
Installing SearXNG fallback skill...
SearXNG skill installed.
Installing LinkedIn research skill...
LinkedIn research skill installed.
Starting OpenClaw gateway...
Gateway listening on 0.0.0.0:18789
```

**Status:** ✅ Perfect - ready to use

---

### Scenario 2: Deployment with Volume (Second Deploy)

```
Config created and environment variables replaced.
State dir: /root/.openclaw
Workspace dir: /root/.openclaw/workspace
Config path: /root/.openclaw/openclaw.json
Starting OpenClaw gateway...
Gateway listening on 0.0.0.0:18789
```

**Status:** ✅ Perfect - skills already installed (faster!)

---

### Scenario 3: Active Usage

```
Gateway listening on 0.0.0.0:18789
[ws] closed before connect ... pairing required
[telegram] received message from user:123456
[agent/embedded] processing message
[tools] using searxng-fallback skill
[telegram] delivered reply to user:123456
[ws] closed before connect ... pairing required
```

**Status:** ✅ Perfect - bot actively responding

---

### Scenario 4: Problem Deployment

```
Config created and environment variables replaced.
Config invalid
- agents.defaults: Unrecognized key: "apiKeys"
error: Process exited with code 1
```

**Status:** ❌ Problem - pull latest fixes and redeploy

---

## When to Worry

**Don't worry about:**
- ⚠️ "pairing required" messages
- ⚠️ WebSocket closed messages
- ⚠️ Gateway target/source messages

**Do worry about:**
- 🚨 "Config invalid"
- 🚨 "ENOENT: no such file or directory"
- 🚨 "connection failed" (for Telegram/Slack)
- 🚨 Process exiting with code 1

---

## Getting Help

If you see errors you don't understand:

1. **Check TROUBLESHOOTING.md** for solutions
2. **Search logs** for the specific error message
3. **Compare with scenarios** in this guide
4. **Test components individually:**
   ```bash
   # Test LinkedIn scraper
   curl https://your-scraper-url/health

   # Test Telegram
   # Send /start to bot

   # Test Slack
   # Mention bot in channel
   ```

---

## Summary

**Normal Logs:**
- ✅ "pairing required" - Ignore
- ✅ WebSocket closed - Ignore
- ✅ Gateway listening - Good
- ✅ Skills installed - Good
- ✅ Config created - Good

**Problem Logs:**
- 🚨 Config invalid - Pull latest fixes
- 🚨 ENOENT/EEXIST - Pull latest fixes
- 🚨 Connection failed - Check tokens
- 🚨 Process exited - Check error above

**Your deployment is working if:**
- Gateway is listening
- No config errors
- Telegram/Slack bots respond
- Can ignore "pairing required"

---

**Last Updated:** 2026-02-15
