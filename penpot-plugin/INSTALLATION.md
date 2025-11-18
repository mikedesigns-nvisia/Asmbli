# Installing Asmbli PenPot Plugin

## Overview

The Asmbli Design Agent plugin provides AI-powered design assistance directly within PenPot using 34 MCP tools.

## Installation Steps

### 1. Start the Plugin Server

The plugin must be served from a local HTTP server so PenPot can load it:

```bash
cd penpot-plugin
./serve-plugin.sh
```

This will start a server at `http://localhost:8765` serving the plugin files.

**Leave this terminal window open** - the server must keep running while you use PenPot.

### 2. Install Plugin in PenPot

1. Open PenPot in your browser: https://design.penpot.app
2. Navigate to **Plugins → Manage Plugins** (or click the Plugins icon in the toolbar)
3. Click **"Install from URL"** or enter the URL in the text field
4. Enter the plugin URL: `http://localhost:8765/manifest.json`
5. Click **"INSTALL"**

### 3. Verify Plugin Loaded

After installation, you should see:
- ✅ "Asmbli Design Agent" listed in your installed plugins
- ✅ Plugin panel appears in PenPot interface
- ✅ AI chat interface with Ollama status indicator

### 4. Start Using the Plugin

The plugin provides:
- **AI Chat Interface**: Ask the design agent to create layouts, components, etc.
- **Quick Actions**: Pre-defined design tasks (Hero Section, Grid Layout, Navigation Bar)
- **34 MCP Tools**: Full design automation capabilities
- **Design Token Integration**: Automatically uses your brand's design tokens

Example prompts:
- "Create a mobile wireframe"
- "Add a hero section with heading and CTA button"
- "Create a navigation bar with logo and menu items"
- "Design a pricing card component"

## Troubleshooting

### Plugin Won't Install

**Issue**: "Failed to load plugin" or network error

**Solution**:
1. Verify the server is running: `curl http://localhost:8765/manifest.json`
2. Check the terminal running `serve-plugin.sh` for errors
3. Ensure PenPot has access to localhost (browser security settings)

### Ollama Not Available

**Issue**: Plugin shows "AI Unavailable" status

**Solution**:
1. Start Ollama: `ollama serve`
2. Verify Ollama is running: `curl http://localhost:11434/api/tags`
3. Pull required model: `ollama pull llama3.2`

### Plugin Doesn't Respond

**Issue**: Clicking buttons or sending messages does nothing

**Solution**:
1. Check browser console (F12) for JavaScript errors
2. Reload PenPot page
3. Rebuild plugin: `cd penpot-plugin && npm run build`
4. Restart plugin server

### Design Elements Not Created

**Issue**: AI responds but nothing appears on canvas

**Solution**:
1. Ensure you have a PenPot page/board open
2. Check that the plugin has permissions (granted during installation)
3. Try a simple command: "Create a blue rectangle"

## Architecture

The plugin works by:
1. **PenPot loads the plugin** via the official Plugin API
2. **Plugin connects to Ollama** running on localhost:11434
3. **AI processes design requests** and determines which MCP tools to use
4. **MCP tools manipulate PenPot canvas** using the PenPot Plugin API
5. **Flutter app can monitor canvas state** via the plugin's update events

## Differences from Flutter WebView Approach

Previously, we tried to **inject the plugin via JavaScript** in the Flutter WebView. This didn't work because:
- ❌ Injected scripts can't access PenPot Plugin API
- ❌ PenPot blocks external script injection for security
- ❌ No proper message passing between injected script and PenPot

The **correct approach** (what we're doing now):
- ✅ Install plugin via PenPot's official plugin system
- ✅ Plugin has full access to PenPot API with proper permissions
- ✅ Plugin loads in PenPot's plugin sandbox with secure communication
- ✅ Works across all browsers and environments

## Next Steps

After the plugin is installed and working in PenPot:

1. **Test Basic Functionality**: Try creating rectangles, text, frames
2. **Test AI Integration**: Ask the design agent to create complex layouts
3. **Test Design Tokens**: Verify brand colors and spacing are applied
4. **Monitor from Flutter App**: The Flutter app's Watch Mode should show canvas updates in real-time

## Development Workflow

For plugin development:

```bash
# Development mode (auto-rebuild on file changes)
cd penpot-plugin
./dev.sh

# After making changes, reload PenPot page to see updates
# (Plugin automatically reloads from localhost:8765)
```

## Production Deployment

For production use, you would:

1. Build the plugin: `npm run build`
2. Host `dist/` folder on a public HTTPS server (e.g., GitHub Pages, Netlify)
3. Update installation URL to the public URL
4. Users install from the public URL instead of localhost

Example public URL:
```
https://asmbli.github.io/penpot-plugin/manifest.json
```
