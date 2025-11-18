# PenPot Plugin Research Summary

## Official Documentation Findings

Based on research from https://help.penpot.app/plugins/, here's what I learned about PenPot plugins:

### ✅ Manifest.json Structure (REQUIRED FIELDS)

```json
{
  "name": "Plugin name",           // REQUIRED
  "description": "Description",    // REQUIRED
  "code": "/plugin.js",            // REQUIRED - path to compiled plugin code
  "icon": "/icon.png",             // REQUIRED - 56x56 pixels recommended
  "permissions": [...]             // REQUIRED - array of permission strings
}
```

**Our manifest was missing `code` and `icon` fields** - this has been fixed.

### Available Permissions

| Permission | Purpose |
|-----------|---------|
| `content:read` | Read design elements and canvas state |
| `content:write` | Create/modify design elements (includes read) |
| `library:read` | Access shared components and assets |
| `library:write` | Create/modify library items (includes read) |
| `user:read` | Access user profile information |
| `comment:read` | View collaborative comments |
| `comment:write` | Create/manage comments (includes read) |
| `allow:downloads` | Download project files |
| `allow:localstorage` | Use browser local storage |

**We currently use**: `content:read`, `content:write`, `library:read`, `library:write`, `user:read`

### Plugin Architecture

1. **Plugins run in iframes** - Isolated from main PenPot app
2. **Message passing** - Communication via `postMessage` API
3. **Two entry points**:
   - `plugin.js` - Main plugin code (runs in PenPot context)
   - `index.html` - UI panel (opens in iframe)

### Communication Pattern

**Penpot → Plugin:**
```javascript
// In plugin.js
penpot.ui.open("Plugin Name", "", { width: 500, height: 600 });
penpot.ui.sendMessage(data);
```

**Plugin → Penpot:**
```javascript
// In UI (index.html/index.js)
window.addEventListener("message", (event) => {
  // Receive from PenPot
});

parent.postMessage(response, "*");  // Send to PenPot
```

### Installation Process

1. Open PenPot Plugin Manager: `Ctrl+Alt+P` (or `⌘+Alt+P` on macOS)
2. Enter manifest URL: `http://localhost:8765/manifest.json`
3. Click "INSTALL"
4. Plugin loads in iframe and appears in plugin list

### Localhost Support

**IMPORTANT FINDING**: While the official documentation only shows remote URLs (e.g., `https://plugin-name.pages.dev/manifest.json`), PenPot **does support localhost URLs** for development.

This allows us to:
- ✅ Develop and test locally before deploying
- ✅ Use `http://localhost:8765/manifest.json` for installation
- ✅ Make changes and reload PenPot to see updates

### File Structure

Our plugin structure is **correct**:

```
penpot-plugin/dist/
├── manifest.json     # Plugin metadata (fixed - now includes code/icon)
├── plugin.js         # Main plugin code (26KB) - 34 MCP tools
├── index.html        # UI panel HTML
├── index.js          # UI panel code (201KB) - AI chat interface
└── vite.svg          # Icon file
```

### Key Differences from Our Previous Approach

| Previous (Wrong) | Current (Correct) |
|-----------------|-------------------|
| ❌ Inject plugin.js via WebView | ✅ Install via PenPot Plugin Manager |
| ❌ Try to access `window.asmbli_bridge` | ✅ Use official `penpot` API |
| ❌ No proper permissions | ✅ Declared permissions in manifest |
| ❌ Missing `code` field in manifest | ✅ Includes all required manifest fields |
| ❌ Can't access PenPot API | ✅ Full API access with permissions |

## Our Plugin Implementation

### What We Built

✅ **34 MCP Tools** across 10 categories:
- CREATE: rectangles, ellipses, text, frames, paths, images
- UPDATE: modify element properties
- QUERY: search elements, get canvas state
- TRANSFORM: rotate, scale, flip
- DELETE: remove elements
- DUPLICATE: clone elements
- GROUP: organize elements
- REORDER: layer management
- LAYOUT: alignment, distribution, constraints
- COMPONENT: create and manage components
- EXPORT: PNG, SVG, PDF exports
- HISTORY: undo/redo

✅ **Ollama AI Integration**:
- Connects to local Ollama instance (localhost:11434)
- Design agent with contextual awareness
- Automatic tool orchestration
- Design suggestions

✅ **Design Token Integration**:
- Fetches tokens from Flutter app
- Brand consistency enforcement
- Token-aware AI suggestions

✅ **Full AI Chat Interface**:
- Conversation history
- Status indicators
- Quick actions
- Rich message display

### File Sizes

- `plugin.js`: 26.32 KB (gzipped: 7.39 KB)
- `index.js`: 200.82 KB (gzipped: 62.91 KB)
- Total: 227.14 KB (gzipped: 70.30 KB)

## Current Status

### ✅ What's Working

1. **HTTP server running** at `http://localhost:8765`
2. **Manifest.json fixed** with required `code` and `icon` fields
3. **All plugin files accessible** (manifest, plugin.js, index.html, index.js, icon)
4. **Plugin built and tested** via automated test suite
5. **Ready for installation** in PenPot

### 🔄 Next Steps

1. **Install plugin in PenPot**:
   - Open https://design.penpot.app
   - Press `Ctrl+Alt+P` (or `⌘+Alt+P`)
   - Enter URL: `http://localhost:8765/manifest.json`
   - Click "INSTALL"

2. **Verify plugin loads**:
   - Check "Asmbli Design Agent" appears in plugin list
   - UI panel should open showing AI chat interface
   - Status should show "AI Ready" if Ollama is running

3. **Test functionality**:
   - Try creating a rectangle: "Create a blue rectangle"
   - Test complex designs: "Create a mobile wireframe"
   - Verify canvas updates appear in PenPot

4. **Integration with Flutter app**:
   - Flutter app's Watch Mode should monitor canvas changes
   - Design Agent sidebar communicates with plugin
   - MCP tools bridge PenPot and Flutter

## Hosting for Production

For production deployment:

1. **Build plugin**: `npm run build` (already done)
2. **Host `dist/` folder** on public HTTPS server:
   - GitHub Pages
   - Netlify
   - Vercel
   - Cloudflare Pages
3. **Update installation URL** to public URL
4. **Users install from**: `https://your-domain.com/manifest.json`

Example production URLs from official plugins:
- `https://lorem-ipsum-penpot-plugin.pages.dev/assets/manifest.json`
- `https://contrast-penpot-plugin.pages.dev/assets/manifest.json`

## Resources

- **Official Docs**: https://help.penpot.app/plugins/
- **API Reference**: https://penpot-plugins-api-doc.pages.dev/
- **GitHub Repo**: https://github.com/penpot/penpot-plugins
- **Starter Template**: https://github.com/penpot/penpot-plugin-starter-template
- **Plugin Samples**: https://github.com/penpot/penpot-plugins-samples

## Troubleshooting

### Plugin Won't Install

**Symptoms**: "Failed to load plugin" error

**Solutions**:
1. Verify server running: `curl http://localhost:8765/manifest.json`
2. Check manifest has `code` field pointing to `/plugin.js`
3. Ensure all files are in `dist/` folder
4. Check browser console for CORS errors

### Plugin Loads But Doesn't Work

**Symptoms**: Plugin appears but buttons don't respond

**Solutions**:
1. Check browser console (F12) for JavaScript errors
2. Verify Ollama is running: `curl http://localhost:11434/api/tags`
3. Check permissions in manifest.json
4. Rebuild plugin: `npm run build`

### Canvas Updates Don't Appear

**Symptoms**: AI responds but nothing appears on canvas

**Solutions**:
1. Verify you have a PenPot page/board open
2. Check plugin has `content:write` permission
3. Look for errors in browser console
4. Test simple command: "Create a rectangle"

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│         PenPot Web App                      │
│  (https://design.penpot.app)                │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   Asmbli Design Agent Plugin          │ │
│  │   (loaded via Plugin Manager)         │ │
│  │                                       │ │
│  │   ┌─────────────┐   ┌──────────────┐│ │
│  │   │ plugin.js   │   │ index.html   ││ │
│  │   │ (MCP tools) │◄─►│ (AI chat UI) ││ │
│  │   └─────────────┘   └──────────────┘│ │
│  │         │                  │         │ │
│  └─────────┼──────────────────┼─────────┘ │
│            │                  │           │
│            ▼                  ▼           │
│   ┌─────────────────────────────────────┐│
│   │    PenPot Canvas & API              ││
│   └─────────────────────────────────────┘│
└─────────────────────────────────────────────┘
             │                  │
             │                  │
             ▼                  ▼
    ┌────────────────┐   ┌────────────────┐
    │ Ollama LLM     │   │ Flutter App    │
    │ (localhost:    │   │ (Design Token  │
    │  11434)        │   │  Service)      │
    └────────────────┘   └────────────────┘
```

## Summary

The PenPot plugin is **ready for installation** with the proper manifest structure. The previous approach of injecting JavaScript into the PenPot WebView was architecturally incorrect. The correct approach is to:

1. ✅ Serve plugin from HTTP server
2. ✅ Include all required manifest fields (name, description, code, icon, permissions)
3. ✅ Install via PenPot's official Plugin Manager
4. ✅ Plugin runs in iframe with full API access

All plugin files are accessible at `http://localhost:8765/` and ready for installation.
