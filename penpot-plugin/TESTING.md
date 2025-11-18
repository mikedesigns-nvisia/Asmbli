# PenPot Plugin Testing Guide

## Automated Test Suite

The plugin includes a comprehensive automated test suite that validates all components before deployment.

## Quick Start

```bash
# Run full automated test suite
npm test
# or
./test-plugin.sh
```

## What Gets Tested

### 1. Ollama Service Check
- ✓ Verifies Ollama is running on `localhost:11434`
- ✓ Confirms llama3.2 model is available
- ✓ Tests Ollama API with a sample request

### 2. Build Validation
- ✓ Compiles TypeScript (`tsc -b`)
- ✓ Builds UI with Vite
- ✓ Validates output files exist:
  - `dist/plugin.js` (~26 KB)
  - `dist/index.js` (~200 KB)
  - `dist/index.html`

### 3. Type Checking
- ✓ Runs TypeScript compiler in check-only mode
- ✓ Ensures no type errors in codebase

### 4. Manifest Generation
- ✓ Creates `manifest.json` for PenPot
- ✓ Defines plugin permissions and metadata

## Test Output

The test script provides color-coded output:
- 🟢 Green = Test passed
- 🟡 Yellow = Warning or info
- 🔴 Red = Test failed

## Manual Testing in PenPot

After automated tests pass, follow these steps to test in PenPot:

### 1. Start Ollama (if not already running)
```bash
ollama serve
```

### 2. Load Plugin in PenPot
1. Open PenPot in your browser
2. Navigate to **Plugins → Manage Plugins**
3. Click **Install from filesystem**
4. Select: `/Users/marce/Documents/GitHub/Asmbli/penpot-plugin/dist`

### 3. Test UI Features

**Status Indicators:**
- AI status should show "AI Ready" (green)
- Canvas info should display element count

**Quick Actions:**
Try each quick action button:
- 🎨 Create Hero Section
- 📐 Add Grid Layout
- 🎯 Navigation Bar
- ✨ Improve Spacing

**Chat Interface:**
1. Type a design request in the input field
2. Press Enter or click Send
3. Watch the AI process your request
4. Verify suggestions and tool calls appear
5. Check that canvas updates reflect the AI's actions

### 4. Test MCP Tools

The plugin implements 34 MCP tools across 10 categories. Test key tools:

**CREATE:**
```
"Create a blue rectangle at position 100, 100"
"Add a text element that says 'Hello World'"
```

**QUERY:**
```
"What elements are on the canvas?"
"Show me all rectangles"
```

**TRANSFORM:**
```
"Rotate the selected element 45 degrees"
"Scale the rectangle by 2x"
```

**LAYOUT:**
```
"Align all elements to the left"
"Distribute elements evenly"
```

## Development Workflow

### Development Mode (Auto-rebuild)
```bash
./dev.sh
```

This will:
1. Check Ollama status
2. Build the plugin
3. Watch for file changes
4. Auto-rebuild on save

### Type Checking Only
```bash
npm run type-check
```

### Linting
```bash
npm run lint
```

## Troubleshooting

### "Ollama is not running"
```bash
# Start Ollama service
ollama serve
```

### "llama3.2 model not found"
```bash
# Pull the model
ollama pull llama3.2
```

### "TypeScript errors found"
Check the error output and fix type issues in the code.

### "Plugin build failed"
1. Check for syntax errors in source files
2. Ensure all dependencies are installed: `npm install`
3. Clear build cache: `rm -rf dist && npm run build`

## Performance Benchmarks

**Build Times:**
- Initial build: ~400-500ms
- Incremental rebuild: ~200-300ms

**Bundle Sizes:**
- plugin.js: 26.32 KB (gzipped: 7.39 KB)
- index.js: 200.82 KB (gzipped: 62.91 KB)
- Total: 227.14 KB (gzipped: 70.30 KB)

**AI Response Times:**
- Simple requests (create rectangle): ~1-2 seconds
- Complex requests (hero section): ~3-5 seconds
- Design analysis: ~2-4 seconds

## Continuous Integration

The test script can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Test PenPot Plugin
  run: |
    cd penpot-plugin
    npm install
    npm test
```

## Next Steps

After testing, consider:
1. Testing with different Ollama models (llama3.1, mistral, etc.)
2. Stress testing with large canvases (100+ elements)
3. Testing design token integration with Flutter app
4. Performance profiling with Chrome DevTools
5. User acceptance testing with real design workflows
