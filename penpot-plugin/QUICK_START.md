# Quick Start: Installing Asmbli PenPot Plugin

## Current Status ✅

- ✅ Plugin server is **running** at http://localhost:8765
- ✅ Manifest.json **fixed** with required fields (code, icon)
- ✅ All plugin files **accessible** and ready
- ✅ 34 MCP tools + AI chat interface **built**

## Install Now (3 Steps)

### Step 1: Open PenPot

Go to: **https://design.penpot.app**

(Create a free account if you don't have one)

### Step 2: Open Plugin Manager

Press: **⌘ + Alt + P** (macOS) or **Ctrl + Alt + P** (Windows/Linux)

Or click: **Plugins → Manage Plugins** from the menu

### Step 3: Install Plugin

In the text field, enter:

```
http://localhost:8765/manifest.json
```

Click **"INSTALL"**

## What You'll See

After installation:

1. **"Asmbli Design Agent"** appears in your plugin list
2. **Plugin panel opens** with AI chat interface
3. **Status indicator** shows:
   - 🟢 "AI Ready" (if Ollama is running)
   - 🔴 "AI Unavailable" (if Ollama is not running)

## Test It

Try these commands in the chat:

```
Create a blue rectangle
```

```
Create a mobile wireframe
```

```
Add a hero section with heading and button
```

The AI will process your request and create the designs on the PenPot canvas.

## Troubleshooting

### "Failed to load plugin"

**Check server is running:**
```bash
curl http://localhost:8765/manifest.json
```

Should return plugin metadata.

**If server stopped, restart it:**
```bash
cd penpot-plugin
./serve-plugin.sh
```

### "AI Unavailable"

**Start Ollama:**
```bash
ollama serve
```

**Verify it's running:**
```bash
curl http://localhost:11434/api/tags
```

### Nothing happens when I send messages

1. Open browser console (F12)
2. Look for JavaScript errors
3. Check that you have a PenPot board/page open
4. Try a simple command: "Create a rectangle"

## Server Management

The plugin server is currently running in the background.

**To stop it:**
```bash
pkill -f "http.server 8765"
```

**To restart it:**
```bash
cd penpot-plugin
./serve-plugin.sh
```

**To rebuild plugin after code changes:**
```bash
cd penpot-plugin
npm run build
./serve-plugin.sh
```

## Next Steps

Once the plugin is installed and working:

1. **Test all MCP tools** - Try creating frames, text, shapes
2. **Test AI integration** - Ask for complex layouts
3. **Monitor from Flutter app** - Watch Mode should show canvas updates
4. **Explore design tokens** - AI uses your brand's design system

## Resources

- Full installation guide: [INSTALLATION.md](INSTALLATION.md)
- Plugin research: [PLUGIN_RESEARCH.md](PLUGIN_RESEARCH.md)
- Testing guide: [TESTING.md](TESTING.md)
- Plugin README: [README.md](README.md)

## Support

If you encounter issues:

1. Check browser console (F12) for errors
2. Verify all URLs are accessible:
   - http://localhost:8765/manifest.json
   - http://localhost:8765/plugin.js
   - http://localhost:8765/index.html
3. Ensure Ollama is running (localhost:11434)
4. Try reloading the PenPot page

---

**Ready to install?** Open https://design.penpot.app and press ⌘+Alt+P!
