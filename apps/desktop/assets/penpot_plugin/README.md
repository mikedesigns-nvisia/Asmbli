# Asmbli Penpot Plugin

TypeScript plugin that enables programmatic control of Penpot for AI design agents.

## Overview

This plugin runs inside the Penpot web app and provides a JavaScript bridge for the Flutter desktop app to control Penpot programmatically. It's part of the MCP-based design agent system.

## Architecture

```
Flutter App (Dart)
    ↓ WebView JavaScript Bridge
Penpot Plugin (TypeScript)
    ↓ Penpot Plugin API
Penpot Canvas (Web App)
```

## Setup

### Install Dependencies

```bash
cd apps/desktop/assets/penpot_plugin
npm install
```

### Build Plugin

```bash
# One-time build
npm run bundle

# Watch mode (auto-rebuild on changes)
npm run watch
```

This generates `dist/plugin.js` which gets injected into Penpot by the Flutter app.

## Development Workflow

1. **Edit TypeScript**: Modify `src/plugin.ts`
2. **Build**: Run `npm run bundle`
3. **Test**: Run Flutter app, plugin auto-loads in Penpot WebView
4. **Iterate**: Make changes, rebuild, hot-reload Flutter app

## Plugin API

### Commands (Flutter → Plugin)

All commands follow this structure:

```typescript
{
  source: 'asmbli-agent',
  type: 'command_name',
  params: { /* command-specific */ },
  requestId: 'unique_id',
  timestamp: 'ISO8601'
}
```

#### Available Commands

**create_rectangle**
```typescript
{
  type: 'create_rectangle',
  params: {
    x?: number,
    y?: number,
    width?: number,
    height?: number,
    fill?: string,          // e.g., '#FF0000'
    stroke?: string,
    strokeWidth?: number,
    borderRadius?: number,
    name?: string
  }
}
```

**create_text**
```typescript
{
  type: 'create_text',
  params: {
    content: string,
    x?: number,
    y?: number,
    fontSize?: number,
    fontFamily?: string,
    fontWeight?: number,
    color?: string,
    name?: string
  }
}
```

**create_frame**
```typescript
{
  type: 'create_frame',
  params: {
    x?: number,
    y?: number,
    width?: number,
    height?: number,
    name?: string,
    children?: any[]
  }
}
```

**get_canvas_state**
```typescript
{
  type: 'get_canvas_state',
  params: {}
}
```

**clear_canvas**
```typescript
{
  type: 'clear_canvas',
  params: {}
}
```

### Responses (Plugin → Flutter)

All responses follow this structure:

```typescript
{
  source: 'asmbli-plugin',
  type: 'command_name_response',
  requestId: 'matches_request',
  success: boolean,
  data?: any,              // If success
  error?: string,          // If failure
  timestamp: 'ISO8601'
}
```

### Special Events

**plugin_ready**
```typescript
{
  source: 'asmbli-plugin',
  type: 'plugin_ready',
  success: true,
  timestamp: 'ISO8601'
}
```

Sent when plugin initializes and Penpot API is ready.

## Testing

### Manual Testing in Browser Console

When Penpot loads with the plugin:

```javascript
// Plugin is available globally
window.asmbliPlugin

// Send test command
window.postMessage({
  source: 'asmbli-agent',
  type: 'create_rectangle',
  params: {
    x: 100,
    y: 100,
    width: 200,
    height: 150,
    fill: '#4ECDC4',
    borderRadius: 8,
    name: 'Test Rectangle'
  },
  requestId: 'test_1',
  timestamp: new Date().toISOString()
}, '*');
```

### Integration Testing

The Flutter app includes integration tests that:
1. Load Penpot in WebView
2. Inject plugin
3. Send commands
4. Verify responses
5. Check canvas state

## File Structure

```
penpot_plugin/
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript config
├── manifest.json         # Plugin metadata
├── src/
│   └── plugin.ts         # Main plugin code
└── dist/
    └── plugin.js         # Built output (generated)
```

## Penpot Plugin API Reference

The plugin uses Penpot's official Plugin API:

- `penpot.createRectangle()` - Create rectangle element
- `penpot.createText(content)` - Create text element
- `penpot.createFrame()` - Create frame (container)
- `penpot.currentPage` - Get current page
- `element.remove()` - Delete element

Full API docs: https://penpot-plugins-api-doc.pages.dev/

## Week 1 Status

- ✅ Plugin structure created
- ✅ TypeScript configuration
- ✅ Basic commands (rectangle, text, frame)
- ✅ JavaScript bridge communication
- ⏳ Build and testing
- ⏳ Flutter integration

## Next Steps (Week 2)

- Add more element types (circles, polygons, images)
- Implement component creation
- Add style management (colors, typography)
- Implement layout constraints (auto-layout)
- Add design token support
