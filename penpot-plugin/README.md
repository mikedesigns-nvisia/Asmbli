# Asmbli PenPOT Plugin

Native PenPOT plugin for Asmbli Design Agent with MCP tools integration.

## Overview

This plugin provides a native PenPOT integration for the Asmbli design agent system. It implements MCP (Model Context Protocol) tools directly within PenPOT using the official Plugin API.

## What We Built

### Phase 1 Complete - Plugin Foundation (Week 4)

✅ **Project Structure**: Vite + React + TypeScript plugin with PenPOT Plugin API integration
✅ **5 Core MCP Tools**: createRectangle, createEllipse, createText, createFrame, clearCanvas
✅ **Bridge Communication**: WebSocket client for Flutter app integration
✅ **UI Panel**: Test interface with connection status and tool execution feedback
✅ **Build System**: TypeScript compilation with dual entry points (plugin + UI)

### Phase 2 Complete - 20+ Additional MCP Tools

✅ **UPDATE**: updateElement - modify element properties, position, size, colors, text
✅ **QUERY**: queryElements, getCanvasState, getElementDetails - inspect canvas and elements
✅ **TRANSFORM**: rotateElement, scaleElement, flipHorizontal, flipVertical
✅ **DELETE**: deleteElement - remove elements from canvas
✅ **DUPLICATE**: duplicateElement - clone elements with optional offset
✅ **GROUP**: groupElements, ungroupElements - organize elements
✅ **REORDER**: bringToFront, sendToBack, bringForward, sendBackward - layer management
✅ **HISTORY**: undo, redo - canvas history navigation

### Phase 3 Complete - LAYOUT, COMPONENT, and EXPORT Tools (Week 6)

✅ **LAYOUT**: alignElements, distributeElements, setConstraints - align and distribute elements
✅ **COMPONENT**: createComponent, detachComponent, createComponentInstance - component management
✅ **EXPORT**: exportElement, exportPage, exportSelection - export to PNG/SVG/PDF formats

### Phase 4 Complete - Ollama Integration (Week 7)

✅ **Ollama Client**: HTTP client for local Ollama LLM instances
✅ **Design Agent**: AI-powered design assistant with contextual awareness
✅ **Tool Orchestration**: AI can analyze canvas and execute MCP tools automatically
✅ **Design Suggestions**: AI provides layout, color, typography, and spacing recommendations
✅ **Conversation Context**: Agent maintains conversation history for iterative design

### Phase 5 Complete - Design Token Integration (Week 8)

✅ **Design Token Types**: Comprehensive type definitions for colors, spacing, typography, border radius, shadows, and animation
✅ **Token Client**: HTTP client for fetching design tokens from Flutter app with caching
✅ **AI Token Awareness**: Design agent automatically uses brand design tokens in suggestions
✅ **Token Application**: Helper methods for applying tokens to element properties
✅ **Fallback Defaults**: Default design tokens based on Asmbli brand system

### Phase 6 Complete - Full AI Chat Interface (Week 9)

✅ **Chat Interface**: Complete AI conversation UI with message history
✅ **Status Indicators**: Real-time Ollama availability and canvas state display
✅ **Quick Actions**: Pre-defined prompts for common design tasks
✅ **Rich Messages**: Display AI suggestions, tool calls, and reasoning
✅ **Auto-Scroll**: Automatic scrolling to newest messages
✅ **Loading States**: Spinner animation while AI processes requests

**Build Output**:
- `dist/plugin.js` - 26.32 KB (gzipped: 7.39 KB) - **34 MCP tools + AI + Design Tokens**
- `dist/index.js` - 200.82 KB (gzipped: 62.91 KB) - **Full AI Chat UI**
- `dist/index.html` - 0.37 KB

## Quick Start

```bash
# Install dependencies
npm install

# Build plugin
npm run build

# Development mode with auto-rebuild
./dev.sh

# Run automated tests
./test-plugin.sh
```

### Automated Testing

The plugin includes comprehensive test automation:

```bash
# Run full test suite (checks Ollama, builds, validates output)
./test-plugin.sh
```

The test script will:
- ✓ Check if Ollama is running and llama3.2 model is available
- ✓ Build the plugin with TypeScript compilation
- ✓ Validate build output (plugin.js, index.js, index.html)
- ✓ Run TypeScript type checking
- ✓ Test Ollama API connectivity
- ✓ Create manifest.json for PenPot
- ✓ Display installation instructions

## Testing the Plugin

Use the UI panel test buttons to verify MCP tools:
- **Create Rectangle**: Draws a 200x150 teal rectangle at (100, 100)
- **Create Text**: Adds "Hello from Asmbli!" text at (100, 300)
- **Clear Canvas**: Removes all elements from the canvas

## Implemented MCP Tools (34 total)

### CREATE (5 tools)
- `createRectangle` - Create rectangles with fill, stroke, border radius
- `createEllipse` - Create ellipses and circles
- `createText` - Create text with typography control
- `createFrame` - Create frames/artboards
- `clearCanvas` - Clear all elements

### UPDATE (1 tool)
- `updateElement` - Modify any element property (position, size, colors, text, etc.)

### QUERY (3 tools)
- `queryElements` - Search elements by type and name
- `getCanvasState` - Get complete canvas state with all elements
- `getElementDetails` - Get detailed properties of specific element

### TRANSFORM (4 tools)
- `rotateElement` - Rotate element by degrees
- `scaleElement` - Scale element (uniform or non-uniform)
- `flipHorizontal` - Flip element horizontally
- `flipVertical` - Flip element vertically

### DELETE (1 tool)
- `deleteElement` - Remove element from canvas

### DUPLICATE (1 tool)
- `duplicateElement` - Clone element with optional offset

### GROUP (2 tools)
- `groupElements` - Group multiple elements
- `ungroupElements` - Ungroup elements

### REORDER (4 tools)
- `bringToFront` - Move element to front layer
- `sendToBack` - Move element to back layer
- `bringForward` - Move element one layer forward
- `sendBackward` - Move element one layer backward

### HISTORY (2 tools)
- `undo` - Undo last action
- `redo` - Redo last undone action

### LAYOUT (3 tools)
- `alignElements` - Align multiple elements (left, center, right, top, middle, bottom)
- `distributeElements` - Distribute elements evenly or with fixed spacing
- `setConstraints` - Set layout constraints for responsive behavior

### COMPONENT (3 tools)
- `createComponent` - Convert elements into a reusable component
- `detachComponent` - Detach component instance from its main component
- `createComponentInstance` - Create instance of an existing component

### EXPORT (3 tools)
- `exportElement` - Export specific element to PNG, SVG, or PDF
- `exportPage` - Export entire page to PNG, SVG, or PDF
- `exportSelection` - Export selected elements to PNG, SVG, or PDF

## Ollama Setup

To use the AI design features, you need Ollama running locally:

```bash
# Install Ollama (macOS/Linux)
curl -fsSL https://ollama.com/install.sh | sh

# Pull the llama3.2 model (or your preferred model)
ollama pull llama3.2

# Start Ollama server (runs on localhost:11434)
ollama serve
```

The plugin will automatically connect to Ollama and enable AI-powered design suggestions.

## Next Steps

### Week 10 - Advanced AI Features
- Streaming responses from Ollama for real-time feedback
- Multi-step design workflows with AI planning
- Canvas state analysis and optimization suggestions
- Design pattern recognition and recommendations
- Image generation integration (Stable Diffusion/DALL-E)
- Component library suggestions based on design patterns

## Architecture

```
penpot-plugin/
├── src/
│   ├── plugin.ts         # Main entry point
│   ├── agent/            # Ollama AI integration
│   │   ├── ollama-client.ts    # Ollama HTTP client
│   │   └── design-agent.ts     # AI design assistant
│   ├── tokens/           # Design token integration
│   │   └── design-token-client.ts  # Token fetching and caching
│   ├── mcp/              # MCP tool implementations
│   ├── bridge/           # WebSocket bridge
│   ├── types/            # TypeScript definitions
│   │   ├── mcp.ts             # MCP tool types
│   │   ├── ollama.ts          # Ollama/AI types
│   │   └── design-tokens.ts   # Design token types
│   └── ui/               # React UI panel
├── manifest.json         # Plugin metadata
└── dist/                 # Build output
```

### AI Design Agent Flow

1. **User Request** → Design agent receives prompt + canvas context
2. **Token Fetching** → Design token client fetches brand tokens from Flutter app (cached for 5 minutes)
3. **AI Analysis** → Ollama LLM analyzes request with full design token awareness
4. **Token-Based Suggestions** → Agent generates suggestions using brand colors, spacing, typography
5. **Tool Calls** → Agent generates MCP tool calls with token values applied
6. **Execution** → Plugin executes tool calls on PenPOT canvas
7. **Feedback** → Results sent back to user with design rationale and token references

## License

MIT
