# Penpot Agent Integration Guide

**Status**: ✅ Week 3 Task 25 Complete
**Date**: 2025-11-15
**Purpose**: Guide for AI agents to use Penpot MCP tools programmatically

---

## Overview

The **MCPPenpotServer** provides 23 MCP-compliant tools for AI agents to programmatically control the Penpot design canvas. This enables agents to:
- Create and manipulate design elements
- Apply design tokens for consistency
- Query canvas state and statistics
- Manage design history (undo/redo)
- Export designs in multiple formats

---

## Architecture

### Embedded MCP Server

Unlike external MCP servers (GitHub, filesystem), MCPPenpotServer is **embedded** directly in the Flutter app:

```dart
// Located at: apps/desktop/lib/core/services/mcp_penpot_server.dart
class MCPPenpotServer {
  final GlobalKey<PenpotCanvasState> canvasKey;
  final DesignTokensService? designTokensService;
  final DesignHistoryService? historyService;

  // MCP Protocol Implementation
  Future<Map<String, dynamic>> listTools() async { ... }
  Future<Map<String, dynamic>> handleToolCall(String toolName, Map<String, dynamic> arguments) async { ... }
}
```

### Integration Points

1. **Canvas Widget**: PenpotCanvas widget ([penpot_canvas.dart](../apps/desktop/lib/core/widgets/penpot_canvas.dart))
2. **MCP Server**: MCPPenpotServer service
3. **Design Tokens**: DesignTokensService for brand consistency
4. **History Tracking**: DesignHistoryService for undo/redo
5. **Canvas Library**: UI dashboard for discovering capabilities

---

## Available MCP Tools (23 Total)

### Week 1: Foundation (6 tools)

**Basic Element Creation**:
- `penpot_create_rectangle` - Create rectangles/squares
- `penpot_create_text` - Create text elements
- `penpot_create_frame` - Create container frames

**Canvas Management**:
- `penpot_clear_canvas` - Remove all elements
- `penpot_get_canvas_state` - Get current canvas data
- `penpot_build_design_from_spec` - Build complete designs from structured JSON

### Week 2: Advanced Features (7 tools)

**Advanced Elements**:
- `penpot_create_ellipse` - Create circles/ellipses
- `penpot_create_path` - Create custom SVG paths
- `penpot_create_image` - Upload images via data URL

**Component System**:
- `penpot_create_component` - Convert elements to reusable components
- `penpot_create_color_style` - Create named color styles
- `penpot_create_typography_style` - Create text styles

**Layout**:
- `penpot_apply_layout_constraints` - Apply auto-layout and flexbox

### Week 3: Professional Capabilities (10 tools)

**Design Tokens**:
- `penpot_get_design_tokens` - Fetch brand colors, typography, spacing, effects

**Canvas State**:
- `penpot_get_canvas_state_detailed` - Full state with statistics and element tree
- `penpot_get_canvas_statistics` - Element counts, style usage, layer count
- `penpot_query_elements_by_type` - Filter by element type

**Design History**:
- `penpot_undo` - Undo last action
- `penpot_redo` - Redo undone action
- `penpot_get_history` - Query history with summary

**Export**:
- `penpot_export_png` - Export as PNG (1x-4x scale)
- `penpot_export_svg` - Export as vector SVG
- `penpot_export_pdf` - Export as print-ready PDF

---

## Agent Usage Examples

### Example 1: Create a Simple Design

```javascript
// Agent workflow
1. Get design tokens
const tokens = await callTool('penpot_get_design_tokens', {});

2. Create frame
const frame = await callTool('penpot_create_frame', {
  x: 100,
  y: 100,
  width: 400,
  height: 300,
  name: 'Card'
});

3. Add rectangle with brand color
const rect = await callTool('penpot_create_rectangle', {
  x: 120,
  y: 120,
  width: 360,
  height: 80,
  fill: tokens.colors.primary,
  name: 'Header'
});

4. Add text with brand typography
const text = await callTool('penpot_create_text', {
  x: 140,
  y: 140,
  content: 'Welcome',
  fontFamily: tokens.typography.headingFont,
  fontSize: tokens.typography.scale['2xl'],
  fill: tokens.colors.text
});
```

### Example 2: Query and Modify Existing Elements

```javascript
// Get canvas state with statistics
const state = await callTool('penpot_get_canvas_state_detailed', {});
console.log(`Total elements: ${state.statistics.totalElements}`);
console.log(`Rectangles: ${state.statistics.elementsByType.rectangle}`);

// Query all text elements
const textElements = await callTool('penpot_query_elements_by_type', {
  elementType: 'text'
});

// Iterate and update (would require update tools in future)
for (const element of textElements.elements) {
  console.log(`Found text: ${element.name}`);
}
```

### Example 3: Design with Undo/Redo

```javascript
// Create element
await callTool('penpot_create_rectangle', {
  x: 50,
  y: 50,
  width: 100,
  height: 100,
  fill: '#FF0000'
});

// Check history
const history = await callTool('penpot_get_history', { limit: 10 });
console.log(`Actions: ${history.summary.totalEntries}`);
console.log(`Can undo: ${history.summary.canUndo}`);

// Undo if mistake
if (history.summary.canUndo) {
  await callTool('penpot_undo', {});
}

// Redo if needed
if (history.summary.canRedo) {
  await callTool('penpot_redo', {});
}
```

### Example 4: Export Design

```javascript
// Export as PNG at 2x scale for retina displays
const png = await callTool('penpot_export_png', {
  scale: 2.0
});
console.log(`PNG data URL: ${png.dataUrl.substring(0, 50)}...`);

// Export as SVG for web
const svg = await callTool('penpot_export_svg', {});
console.log(`SVG data URL: ${svg.dataUrl.substring(0, 50)}...`);

// Export as PDF for print
const pdf = await callTool('penpot_export_pdf', {});
console.log(`PDF data URL: ${pdf.dataUrl.substring(0, 50)}...`);
```

---

## Integration for Agents

### Step 1: Access MCPPenpotServer

The MCP server is created with a reference to the Penpot canvas:

```dart
// In canvas screen initialization
final GlobalKey<PenpotCanvasState> _canvasKey = GlobalKey();

// Create MCP server
final mcpServer = MCPPenpotServer(
  canvasKey: _canvasKey,
  designTokensService: ServiceLocator.instance.get<DesignTokensService>(),
  historyService: DesignHistoryService(),
);
```

### Step 2: Discover Available Tools

```dart
// Get all available tools
final toolsResponse = await mcpServer.listTools();
final tools = toolsResponse['tools'] as List;

print('Available tools: ${tools.length}');
for (final tool in tools) {
  print('- ${tool['name']}: ${tool['description']}');
}
```

### Step 3: Call Tools

```dart
// Execute a tool call
final result = await mcpServer.handleToolCall(
  'penpot_create_rectangle',
  {
    'x': 100,
    'y': 100,
    'width': 200,
    'height': 150,
    'fill': '#4ECDC4',
    'name': 'My Rectangle',
  },
);

if (result['success']) {
  print('Created element: ${result['elementId']}');
} else {
  print('Error: ${result['error']}');
}
```

### Step 4: Handle Responses

All tool calls return a standardized response:

```dart
{
  'success': true,  // or false if error
  'elementId': '123',  // for creation tools
  'data': { ... },  // tool-specific data
  'error': null,  // error message if failed
}
```

---

## Design Tokens Integration

### Setting Up Design Tokens

**For Users**:
1. Create a context document in the Context Library
2. Tag it with `design-tokens` or `design-system`
3. Add JSON design tokens in a code block:

```json
{
  "colors": {
    "primary": "#4ECDC4",
    "secondary": "#556270",
    "accent": "#FF6B6B",
    "text": "#1A1A1A",
    "background": "#FFFFFF",
    "surface": "#F8F9FA",
    "border": "#E0E0E0",
    "success": "#10B981",
    "warning": "#F59E0B",
    "error": "#EF4444",
    "onSurface": "#1F2937",
    "onSurfaceVariant": "#6B7280"
  },
  "typography": {
    "headingFont": "Space Grotesk",
    "bodyFont": "Inter",
    "monoFont": "JetBrains Mono",
    "baseSize": 16,
    "scale": {
      "xs": 12,
      "sm": 14,
      "base": 16,
      "lg": 18,
      "xl": 20,
      "2xl": 24,
      "3xl": 30,
      "4xl": 36,
      "5xl": 48
    },
    "weights": {
      "light": 300,
      "normal": 400,
      "medium": 500,
      "semibold": 600,
      "bold": 700
    },
    "lineHeights": {
      "tight": 1.25,
      "normal": 1.5,
      "relaxed": 1.75
    }
  },
  "spacing": {
    "unit": 8,
    "scale": {
      "xs": 4,
      "sm": 8,
      "md": 16,
      "lg": 24,
      "xl": 32,
      "2xl": 48,
      "3xl": 64
    }
  },
  "effects": {
    "borderRadius": {
      "sm": 2,
      "md": 6,
      "lg": 8,
      "xl": 12,
      "full": 9999
    },
    "shadows": {
      "sm": "0 1px 2px rgba(0, 0, 0, 0.05)",
      "md": "0 4px 6px rgba(0, 0, 0, 0.1)",
      "lg": "0 10px 15px rgba(0, 0, 0, 0.1)",
      "xl": "0 20px 25px rgba(0, 0, 0, 0.1)"
    }
  }
}
```

**For Agents**:
```javascript
// Fetch tokens
const tokens = await callTool('penpot_get_design_tokens', {});

// Use in designs
await callTool('penpot_create_rectangle', {
  x: 0,
  y: 0,
  width: 400,
  height: 60,
  fill: tokens.colors.primary,
  borderRadius: tokens.effects.borderRadius.lg
});

await callTool('penpot_create_text', {
  x: 16,
  y: 16,
  content: 'Heading',
  fontFamily: tokens.typography.headingFont,
  fontSize: tokens.typography.scale['2xl'],
  fontWeight: tokens.typography.weights.bold,
  fill: tokens.colors.onSurface
});
```

---

## Canvas State Querying

### Getting Detailed State

```javascript
const state = await callTool('penpot_get_canvas_state_detailed', {});

// Response structure:
{
  success: true,
  state: {
    canvasId: 'canvas-1',
    currentPage: {
      id: 'page-1',
      name: 'Main Page',
      width: 1920,
      height: 1080
    },
    elements: [
      {
        id: 'elem-1',
        name: 'My Rectangle',
        type: 'rectangle',
        bounds: { x: 100, y: 100, width: 200, height: 150 },
        styles: { fill: '#4ECDC4' },
        children: []
      },
      // ... more elements
    ],
    statistics: {
      totalElements: 15,
      elementsByType: {
        rectangle: 8,
        text: 5,
        frame: 2
      },
      totalLayers: 2,
      styleUsage: {
        fill: 10,
        stroke: 3
      }
    },
    timestamp: '2025-11-15T10:30:00Z'
  }
}
```

### Querying by Type

```javascript
// Get all text elements
const texts = await callTool('penpot_query_elements_by_type', {
  elementType: 'text'
});

console.log(`Found ${texts.count} text elements`);
for (const element of texts.elements) {
  console.log(`- ${element.name} at (${element.bounds.x}, ${element.bounds.y})`);
}
```

---

## Best Practices

### 1. Always Use Design Tokens

```javascript
// ✅ GOOD: Use design tokens
const tokens = await callTool('penpot_get_design_tokens', {});
await callTool('penpot_create_rectangle', {
  fill: tokens.colors.primary
});

// ❌ BAD: Hardcode values
await callTool('penpot_create_rectangle', {
  fill: '#4ECDC4'
});
```

### 2. Check Canvas State Before Modifying

```javascript
// ✅ GOOD: Check state first
const state = await callTool('penpot_get_canvas_state_detailed', {});
if (state.statistics.totalElements > 50) {
  console.log('Canvas has many elements, consider clearing first');
}

// Proceed with creation
await callTool('penpot_create_rectangle', { ... });
```

### 3. Use Frames for Organization

```javascript
// ✅ GOOD: Organize with frames
const frame = await callTool('penpot_create_frame', {
  x: 0,
  y: 0,
  width: 400,
  height: 600,
  name: 'Card Container'
});

// Add elements inside frame
await callTool('penpot_create_rectangle', {
  x: 20,
  y: 20,
  width: 360,
  height: 80,
  name: 'Header (inside Card)'
});
```

### 4. Track History for Complex Operations

```javascript
// ✅ GOOD: Check history before and after
const beforeHistory = await callTool('penpot_get_history', {});

// Perform complex operation
await callTool('penpot_build_design_from_spec', { ... });

const afterHistory = await callTool('penpot_get_history', {});
console.log(`Added ${afterHistory.summary.totalEntries - beforeHistory.summary.totalEntries} actions`);

// Undo if needed
if (somethingWentWrong) {
  await callTool('penpot_undo', {});
}
```

### 5. Export Appropriately

```javascript
// ✅ GOOD: Choose right format
// For web → SVG (scalable)
const svg = await callTool('penpot_export_svg', {});

// For presentations → PNG at 2x (retina)
const png = await callTool('penpot_export_png', { scale: 2.0 });

// For print → PDF
const pdf = await callTool('penpot_export_pdf', {});
```

---

## Error Handling

All tools return error information in the response:

```javascript
const result = await callTool('penpot_create_rectangle', {
  x: 'invalid',  // Invalid type
  y: 100,
  width: 200,
  height: 150
});

if (!result.success) {
  console.error(`Tool failed: ${result.error}`);
  // Handle error appropriately
} else {
  console.log(`Success: ${result.elementId}`);
}
```

Common error scenarios:
- **Canvas not ready**: Plugin not loaded yet
- **Invalid arguments**: Missing required parameters or wrong types
- **Element not found**: Querying non-existent element
- **History limits**: Undo when no previous actions

---

## Future Enhancements

Potential Week 4+ features:
- **Element updates**: Modify existing elements (move, resize, restyle)
- **Selection management**: Select/deselect elements
- **Layer operations**: Reorder, group, ungroup
- **Advanced layouts**: Grid systems, responsive breakpoints
- **Animation**: Define transitions and interactions
- **Collaboration**: Multi-user canvas state sync

---

## References

- **MCP Server Implementation**: [mcp_penpot_server.dart](../apps/desktop/lib/core/services/mcp_penpot_server.dart)
- **Canvas Widget**: [penpot_canvas.dart](../apps/desktop/lib/core/widgets/penpot_canvas.dart)
- **Design Tokens Service**: [design_tokens_service.dart](../apps/desktop/lib/core/services/design_tokens_service.dart)
- **Week 1 & 2 Progress**: [PENPOT_WEEK1_COMPLETE.md](PENPOT_WEEK1_COMPLETE.md)
- **Week 3 Progress**: [PENPOT_WEEK3_PROGRESS.md](PENPOT_WEEK3_PROGRESS.md)

---

## Summary

The Penpot MCP integration provides **23 production-ready tools** for AI agents to programmatically create, query, and export professional designs. With design tokens, canvas state visibility, history tracking, and multi-format export, agents can build sophisticated design workflows that maintain brand consistency and enable iterative design processes.

**Week 3 Integration Status**: ✅ **Complete**
- Design tokens integration functional
- Canvas state querying operational
- History tracking with undo/redo working
- Export capabilities (PNG, SVG, PDF) ready
- Canvas Library UI dashboard complete
- Agent integration documented

The Penpot MCP server is ready for production use by AI agents!
