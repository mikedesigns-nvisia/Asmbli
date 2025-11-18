# PenPot Plugin Deployment Options

## The Problem

**PenPot.app (hosted version) cannot access localhost URLs** because:
- localhost (127.0.0.1) refers to YOUR computer
- PenPot.app runs on PenPot's servers
- They are on different networks

## Solutions

### Option 1: Cloudflare Tunnel (Recommended - Free & Easy)

Create a temporary public URL that tunnels to your localhost:

```bash
# Install Cloudflare Tunnel (if not installed)
brew install cloudflare/cloudflare/cloudflared

# Start tunnel
cd penpot-plugin
cloudflared tunnel --url http://localhost:8765
```

This will output a public URL like: `https://random-words.trycloudflare.com`

**Then install in PenPot:**
```
https://random-words.trycloudflare.com/manifest.json
```

**Pros:**
- ✅ Free
- ✅ No account needed
- ✅ Works immediately
- ✅ HTTPS automatically

**Cons:**
- ⚠️ URL changes each time you restart
- ⚠️ Temporary (expires when you close tunnel)

### Option 2: GitHub Pages (Recommended - Permanent)

Deploy to GitHub Pages for a permanent public URL:

```bash
# Create gh-pages branch and deploy
cd penpot-plugin
git checkout -b gh-pages
git add dist/
git commit -m "Deploy PenPot plugin to GitHub Pages"
git push origin gh-pages

# Enable GitHub Pages
# Go to: GitHub repo → Settings → Pages
# Source: gh-pages branch, / (root) folder
```

**Plugin URL:**
```
https://YOUR_USERNAME.github.io/Asmbli/penpot-plugin/dist/manifest.json
```

**Pros:**
- ✅ Free
- ✅ Permanent URL
- ✅ HTTPS
- ✅ No tunneling needed
- ✅ Professional

**Cons:**
- ⚠️ Requires git push for updates
- ⚠️ Public repository (plugin code is visible)

### Option 3: Netlify Drop (Easy & Permanent)

Drag and drop deployment:

1. Go to https://app.netlify.com/drop
2. Drag the `penpot-plugin/dist` folder onto the page
3. Get instant public URL

**Plugin URL:**
```
https://random-name-12345.netlify.app/manifest.json
```

**Pros:**
- ✅ Free
- ✅ Super easy (drag & drop)
- ✅ Permanent URL
- ✅ HTTPS
- ✅ Can update by dragging again

**Cons:**
- ⚠️ Requires Netlify account (free)
- ⚠️ Random URL (can customize with paid plan)

### Option 4: Self-Host PenPot Locally

Run your own PenPot instance that CAN access localhost:

```bash
# Using Docker
git clone https://github.com/penpot/penpot.git
cd penpot/docker
docker compose up
```

**Then access:**
- PenPot: http://localhost:9001
- Install plugin: http://localhost:8765/manifest.json

**Pros:**
- ✅ Full control
- ✅ Works with localhost plugins
- ✅ No internet needed
- ✅ Private

**Cons:**
- ⚠️ Requires Docker
- ⚠️ More complex setup
- ⚠️ Uses local resources
- ⚠️ Separate instance from penpot.app

## Quick Comparison

| Method | Setup Time | Cost | Permanent | Ease |
|--------|-----------|------|-----------|------|
| Cloudflare Tunnel | 2 min | Free | No | ★★★★★ |
| GitHub Pages | 5 min | Free | Yes | ★★★★☆ |
| Netlify Drop | 3 min | Free | Yes | ★★★★★ |
| Self-host PenPot | 15 min | Free | Yes | ★★☆☆☆ |

## Recommended Flow

**For Development (Quick Testing):**
1. Use Cloudflare Tunnel for instant public URL
2. Test plugin in PenPot
3. Iterate quickly

**For Production (Permanent Use):**
1. Deploy to GitHub Pages
2. Share permanent URL with team
3. Update via git push

## Current Status

Our plugin server is running at `http://localhost:8765` with CORS enabled.

**Next step:** Choose deployment method above and create public URL.
