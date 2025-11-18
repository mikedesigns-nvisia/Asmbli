# PenPot Plugin Bridge Architecture

## Overview

A headless plugin system that connects the PenPot design tool (running in web browser) with the Asmbli Flutter desktop application via HTTP communication.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    User's Web Browser                            │
│  ┌────────────────────────────────────────────────────────┐     │
│  │          design.penpot.app                              │     │
│  │                                                          │     │
│  │  ┌────────────────────────────────────────────┐        │     │
│  │  │  Asmbli Design Agent Plugin (Installed)    │        │     │
│  │  │  - Headless (no UI)                        │        │     │
│  │  │  - 34 MCP Tools for canvas manipulation    │        │     │
│  │  │  - Sends HTTP POST on initialization       │        │     │
│  │  │  - Retries every 3s for 30s                │        │     │
│  │  └────────────────────────────────────────────┘        │     │
│  │                        │                                │     │
│  │                        │ HTTP POST                      │     │
│  │                        │ /plugin-connection             │     │
│  │                        ▼                                │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ localhost:3000
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Asmbli Flutter Desktop App (macOS)                  │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  PluginBridgeServer (port 3000)                        │     │
│  │  - HTTP server with CORS enabled                       │     │
│  │  - Endpoints:                                           │     │
│  │    • POST /plugin-connection (connection status)       │     │
│  │    • POST /mcp-command (future: tool execution)        │     │
│  │  - Broadcasts connection events via Stream             │     │
│  └────────────────────────────────────────────────────────┘     │
│                        │                                         │
│                        │ Stream                                  │
│                        ▼                                         │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  PenpotCanvasScreen                                     │     │
│  │  - Listens to connection status stream                 │     │
│  │  - Updates connection status light:                    │     │
│  │    • Green glow = connected                            │     │
│  │    • Gray dim = disconnected                           │     │
│  │  - Design Agent chat interface                         │     │
│  │  - MCP tool execution via Ollama LLM                   │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Component Breakdown

### 1. PenPot Plugin (TypeScript)
**Location:** `/penpot-plugin/`

**Files:**
- `src/plugin.ts` - Entry point, headless mode, connection logic
- `src/bridge/client.ts` - HTTP client for Flutter communication
- `src/mcp/tool-registry.ts` - 34 MCP tools registry
- `dist/manifest.json` - Plugin metadata
- `dist/plugin.js` - Compiled plugin (15.37 kB)

**Behavior:**
1. Loads when user clicks OPEN in design.penpot.app
2. Immediately sends connection status via HTTP POST
3. Retries every 3 seconds for 10 attempts (30 seconds total)
4. Stops retrying after connection established or timeout
5. Listens for MCP tool calls from Flutter (via WebSocket - planned)

**Connection Payload:**
```typescript
{
  connected: true,
  timestamp: "2025-11-17T20:30:00Z",
  message: "Plugin connected at 8:30:00 PM"
}
```

### 2. PluginBridgeServer (Dart/Flutter)
**Location:** `/apps/desktop/lib/core/services/plugin_bridge_server.dart`

**Responsibilities:**
- HTTP server listening on `localhost:3000`
- CORS headers for cross-origin requests from web browser
- Stream-based event broadcasting
- Connection state management

**Endpoints:**

**POST /plugin-connection**
```dart
// Request
{
  "connected": true,
  "timestamp": "2025-11-17T20:30:00Z",
  "message": "Plugin connected at 8:30:00 PM"
}

// Response
{
  "success": true,
  "message": "Connection status received"
}
```

**POST /mcp-command** (Planned)
```dart
// For future MCP tool execution from plugin
{
  "command": "penpot_create_rectangle",
  "parameters": { "x": 100, "y": 100, ... }
}
```

**State Management:**
```dart
class PluginBridgeServer {
  String? connectionTimestamp;
  String? connectionMessage;
  bool isConnected;
  Stream<Map<String, dynamic>> connectionStatusStream;
}
```

### 3. Canvas UI Integration
**Location:** `/apps/desktop/lib/features/canvas/presentation/penpot_canvas_screen.dart`

**UI Components:**

**Connection Status Light:**
```dart
Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: isPluginConnected
      ? colors.success  // Green
      : colors.onSurfaceVariant.withOpacity(0.3), // Gray
    boxShadow: isPluginConnected ? [
      BoxShadow(
        color: colors.success.withOpacity(0.5),
        blurRadius: 4,
        spreadRadius: 1,
      )
    ] : null,
  )
)
```

**Stream Listener:**
```dart
void _listenToPluginConnection() {
  final pluginBridge = ServiceLocator.instance.get<PluginBridgeServer>();
  pluginBridge.connectionStatusStream.listen((status) {
    setState(() {
      _isPluginConnected = status['connected'] as bool? ?? false;
    });
  });
}
```

## Data Flow

### Connection Establishment

```
1. User opens design.penpot.app in browser
2. User clicks "Installed Plugins" → "Asmbli Design Agent" → OPEN
3. Plugin initializes and calls notifyFlutterConnection()
4. Plugin sends HTTP POST to localhost:3000/plugin-connection
5. PluginBridgeServer receives request
6. Server updates internal state (isConnected = true)
7. Server broadcasts event via connectionStatusStream
8. PenpotCanvasScreen receives stream event
9. UI updates: connection light turns green with glow effect
10. Plugin continues retrying every 3s for 30s (fallback)
```

### MCP Tool Execution (Planned)

```
1. User types message in Design Agent chat
2. Ollama LLM processes message and decides on MCP tools
3. Flutter calls executeTool() on MCPPenpotServer
4. MCPPenpotServer sends POST to /mcp-command endpoint
5. PluginBridgeServer forwards to plugin via WebSocket
6. Plugin executes tool on PenPot canvas
7. Plugin returns result via WebSocket
8. Result shown in Design Agent chat
```

## Service Locator Integration

**Registration:**
```dart
// apps/desktop/lib/core/di/service_locator.dart:418-420

final pluginBridgeServer = PluginBridgeServer(port: 3000);
await pluginBridgeServer.start();
registerSingleton<PluginBridgeServer>(pluginBridgeServer);
```

**Startup Sequence:**
```
1. App launches → main.dart
2. ServiceLocator.initialize()
3. _registerCoreServices()
4. PluginBridgeServer created
5. pluginBridgeServer.start() → HTTP server binds to port 3000
6. Server registered as singleton
7. Available throughout app lifecycle
```

## Network Configuration

**Ports:**
- `3000` - PluginBridgeServer (HTTP)
- `8765` - Plugin development server (HTTP, serves manifest.json)

**CORS Headers:**
```dart
request.response.headers.add('Access-Control-Allow-Origin', '*');
request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
request.response.headers.add('Access-Control-Allow-Headers', '*');
```

**Why CORS?** Plugin runs in browser context (design.penpot.app) making requests to localhost (different origin).

## MCP Tools Available

The plugin provides 34 MCP tools across 10 categories:

### Creation Tools (7)
- `penpot_create_frame`
- `penpot_create_rectangle`
- `penpot_create_ellipse`
- `penpot_create_text`
- `penpot_create_path`
- `penpot_create_image`
- `penpot_create_component`

### Styling Tools (4)
- `penpot_set_fill`
- `penpot_set_stroke`
- `penpot_set_shadow`
- `penpot_set_typography`

### Update Tools (2)
- `penpot_update_element`
- `penpot_update_text_content`

### Transform Tools (4)
- `penpot_rotate_element`
- `penpot_scale_element`
- `penpot_skew_element`
- `penpot_flip_element`

### Delete Tools (2)
- `penpot_trash_element`
- `penpot_delete_element`

### Duplicate Tools (1)
- `penpot_duplicate_element`

### Group Tools (2)
- `penpot_group_elements`
- `penpot_ungroup`

### Reorder Tools (4)
- `penpot_bring_to_front`
- `penpot_send_to_back`
- `penpot_bring_forward`
- `penpot_send_backward`

### Layout Tools (2)
- `penpot_set_constraints`
- `penpot_apply_auto_layout`

### Query Tools (3)
- `penpot_query_canvas`
- `penpot_search_elements`
- `penpot_get_element_details`

### History Tools (3)
- `penpot_undo`
- `penpot_redo`
- `penpot_get_history`

## Testing & Verification

**Verify PluginBridgeServer:**
```bash
lsof -i :3000
# Should show: desktop PID listening on *:hbci
```

**Test Connection Manually:**
```bash
curl -X POST http://localhost:3000/plugin-connection \
  -H "Content-Type: application/json" \
  -d '{"connected": true, "timestamp": "2025-11-17T20:30:00Z", "message": "Test"}'

# Response: {"success":true,"message":"Connection status received"}
```

**Monitor Flutter Logs:**
```
flutter: 🌐 Plugin Bridge Server started on port 3000
flutter: 🔌 Plugin connection status received:
flutter:    Connected: true
flutter:    Timestamp: 2025-11-17T20:30:00Z
flutter:    Message: Plugin connected at 8:30:00 PM
```

## Current Limitations

1. **No Tool Execution Yet** - MCP tools defined but not wired to bridge
2. **One-Way Communication** - Plugin → Flutter only (no Flutter → Plugin)
3. **No Persistence** - Connection state lost on app restart
4. **No Reconnection Logic** - If connection drops, requires plugin reload
5. **WebView Integration Incomplete** - Flutter WebView doesn't use installed plugin

## Future Enhancements

1. **Bidirectional Communication** - Add WebSocket for Flutter → Plugin commands
2. **Tool Execution Pipeline** - Wire Design Agent to plugin MCP tools
3. **Connection Persistence** - Store plugin connection state
4. **Auto-Reconnect** - Detect disconnections and retry
5. **Plugin Discovery** - Auto-detect when plugin is installed/removed
6. **Error Handling** - Better error messages for connection failures

## Security Considerations

**Current Status:**
- ✅ CORS enabled (required for browser → localhost)
- ✅ Localhost only (no external access)
- ❌ No authentication
- ❌ No request validation
- ❌ No rate limiting

**Production Recommendations:**
- Add API key/token authentication
- Validate request payloads
- Implement rate limiting
- Add request logging
- Consider HTTPS with self-signed cert

## Development Workflow

**Plugin Development:**
```bash
cd penpot-plugin
npm run build          # Build plugin (dist/plugin.js)
npm run dev            # Development server on :8765
```

**Flutter Development:**
```bash
cd apps/desktop
flutter run -d macos   # Run app, server starts on :3000
```

**Plugin Installation:**
1. Visit design.penpot.app
2. Go to Plugins panel
3. Install from URL: `http://localhost:8765/manifest.json`
4. Click OPEN to activate

**Testing Connection:**
1. Run Flutter app (Canvas screen)
2. Open plugin in browser
3. Watch connection light turn green in Flutter app

## Troubleshooting

**Connection light stays gray:**
- Check if Flutter app is running (port 3000 listening)
- Check if plugin is installed in design.penpot.app
- Check browser console for HTTP errors
- Verify CORS headers in Network tab

**Plugin shows error:**
- Check plugin server is running (port 8765)
- Verify manifest.json is accessible
- Check plugin build output for errors

**Server won't start:**
- Check if port 3000 is already in use
- Verify ServiceLocator initialized successfully
- Check Flutter console for startup errors

## File Structure

```
Asmbli/
├── penpot-plugin/
│   ├── src/
│   │   ├── plugin.ts              # Entry point, connection logic
│   │   ├── bridge/
│   │   │   └── client.ts          # HTTP client for Flutter
│   │   └── mcp/
│   │       └── tool-registry.ts   # 34 MCP tools
│   ├── dist/
│   │   ├── manifest.json          # Plugin metadata
│   │   └── plugin.js              # Compiled bundle (15.37 kB)
│   └── package.json
│
└── apps/desktop/lib/
    ├── core/
    │   ├── di/
    │   │   └── service_locator.dart          # Registers PluginBridgeServer
    │   └── services/
    │       └── plugin_bridge_server.dart     # HTTP server implementation
    │
    └── features/canvas/presentation/
        └── penpot_canvas_screen.dart         # UI with connection light

```

## Performance Metrics

**Plugin Size:** 15.37 kB (gzipped: 4.07 kB)
**Server Startup:** ~5ms (part of 183ms total ServiceLocator init)
**Connection Latency:** <10ms (localhost HTTP)
**Retry Interval:** 3 seconds
**Retry Limit:** 10 attempts (30 seconds total)

## Version History

**v0.1.0** - Initial headless plugin implementation
- HTTP-based connection signaling
- Connection status light in UI
- 34 MCP tools registry
- Periodic retry logic (3s × 10)

**Planned v0.2.0:**
- MCP tool execution from Design Agent
- WebSocket bidirectional communication
- Error recovery and reconnection
