# Penpot Migration Implementation Tasks

**Date**: 2025-11-15
**Project**: Excalidraw → Penpot Canvas Migration
**Phase**: 3 - Implementation Tasks
**Based On**:
- [penpot_migration_requirements.md](penpot_migration_requirements.md)
- [penpot_migration_design_spec.md](penpot_migration_design_spec.md)

---

## Executive Summary

This document breaks the 5-week Penpot migration into 42 atomic, sequential tasks. Each task maps to specific requirements (R1-R10), includes validation criteria, and defines clear MCP commands or code changes needed.

**Total Tasks**: 42 tasks across 5 weeks
**Estimated Effort**: 5 weeks full-time
**Dependencies**: User must create Penpot account (Week 1, Task 1)

---

## Week 1: Setup and Proof of Concept

**Objective**: Validate hybrid approach works (Penpot loads, plugin communicates, basic shape creation)

**Requirements**: R1 (WebView), R2 (Plugin basics), R3 (MCP skeleton)

---

### Task 1: User Creates Penpot Account
**Requirement**: All (foundation)

**User Actions**:
- [ ] Navigate to https://design.penpot.app
- [ ] Create account or sign in
- [ ] Verify account via email

**Validates**: Account exists and is accessible

**Owner**: User

---

### Task 2: User Generates Penpot API Token
**Requirement**: R2 (Plugin authentication)

**User Actions**:
- [ ] Log in to Penpot
- [ ] Navigate to Profile → Access Tokens
- [ ] Click "Generate New Token"
- [ ] Name: "Asmbli Agent Bridge"
- [ ] Permissions: Select `content:write`, `content:read`, `library:read`
- [ ] Copy token and store securely

**Validates**: Token generated with correct permissions

**Owner**: User

**Developer Note**: Token will be used in plugin configuration (Week 2)

---

### Task 3: Create PenpotCanvas Widget (Basic Structure)
**Requirement**: R1 (WebView Integration)

**File**: `apps/desktop/lib/core/widgets/penpot_canvas.dart`

**Code Changes**:
```dart
// Create new file: penpot_canvas.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../design_system/design_system.dart';

class PenpotCanvas extends StatefulWidget {
  const PenpotCanvas({super.key});

  @override
  PenpotCanvasState createState() => PenpotCanvasState();
}

class PenpotCanvasState extends State<PenpotCanvas> {
  late WebViewController _controller;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => _isLoaded = true);
            debugPrint('✅ Penpot loaded: $url');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://design.penpot.app'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),

            if (!_isLoaded)
              Container(
                color: colors.surface.withOpacity(0.9),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colors.primary),
                      const SizedBox(height: SpacingTokens.md),
                      Text(
                        'Loading Penpot Canvas...',
                        style: TextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
```

**Dependencies**:
- Add to `pubspec.yaml`: `webview_flutter: ^4.0.0`

**Commands**:
```bash
cd apps/desktop
flutter pub add webview_flutter
flutter pub get
```

**Validates**:
- [ ] Penpot loads in WebView
- [ ] Loading indicator shows/hides correctly
- [ ] No console errors

**Testing**:
```bash
flutter test test/widget/penpot_canvas_test.dart
```

---

### Task 4: Integrate PenpotCanvas into Canvas Library Screen
**Requirement**: R1 (WebView Integration)

**File**: `apps/desktop/lib/features/canvas/presentation/canvas_library_screen.dart`

**Code Changes**:
```dart
// Add import
import '../../../core/widgets/penpot_canvas.dart';

// In _buildCanvasArea(), replace ExcalidrawCanvas with:
Widget _buildCanvasArea() {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: PenpotCanvas(), // Changed from ExcalidrawCanvas
    ),
  );
}
```

**Validates**:
- [ ] Canvas Library screen shows Penpot
- [ ] Penpot UI is interactive (can click, navigate)
- [ ] No layout issues

**Testing**: Manual testing in app

---

### Task 5: Create Penpot Plugin Project Structure
**Requirement**: R2 (Plugin Bridge)

**Directory**: `apps/desktop/assets/penpot_plugin/`

**Commands**:
```bash
mkdir -p apps/desktop/assets/penpot_plugin
cd apps/desktop/assets/penpot_plugin

# Initialize npm project
npm init -y

# Install dependencies
npm install --save-dev typescript @types/node
npm install @penpot/plugin-types

# Create TypeScript config
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
EOF

# Create directory structure
mkdir -p src/commands src/templates src/utils

# Update package.json scripts
npm pkg set scripts.build="tsc"
npm pkg set scripts.watch="tsc --watch"
```

**File Structure**:
```
apps/desktop/assets/penpot_plugin/
├── package.json
├── tsconfig.json
├── manifest.json
└── src/
    ├── plugin.ts           # Main entry
    ├── commands/           # Command handlers
    ├── templates/          # Template generators
    └── utils/              # Helpers
```

**Validates**:
- [ ] npm project initialized
- [ ] TypeScript configured
- [ ] Directory structure created

---

### Task 6: Create Penpot Plugin Manifest
**Requirement**: R2 (Plugin Bridge)

**File**: `apps/desktop/assets/penpot_plugin/manifest.json`

**Code**:
```json
{
  "name": "Asmbli Agent Bridge",
  "description": "Connects Asmbli AI agent to Penpot for programmatic design creation",
  "version": "1.0.0",
  "permissions": [
    "content:write",
    "content:read",
    "library:read"
  ],
  "host": "penpot.app",
  "main": "dist/plugin.js"
}
```

**Validates**:
- [ ] Manifest has required fields
- [ ] Permissions are correct
- [ ] Points to compiled output

---

### Task 7: Implement Basic Plugin (Create Rectangle Only)
**Requirement**: R2 (Plugin Bridge - proof of concept)

**File**: `apps/desktop/assets/penpot_plugin/src/plugin.ts`

**Code**:
```typescript
/// <reference types="@penpot/plugin-types" />

console.log('🎨 Asmbli Agent Bridge initializing...');

// Initialize plugin
penpot.on('ready', () => {
  console.log('✅ Asmbli Agent Bridge loaded');

  // Listen for messages from Flutter
  window.addEventListener('message', handleFlutterMessage);

  // Notify Flutter that plugin is ready
  sendToFlutter({
    type: 'plugin_ready',
    success: true,
    timestamp: new Date().toISOString(),
  });
});

// Handle messages from Flutter WebView
function handleFlutterMessage(event: MessageEvent) {
  const data = event.data;

  // Verify message source
  if (data.source !== 'asmbli-agent') {
    return;
  }

  console.log(`📥 RECEIVED FROM FLUTTER: ${data.type}`, data);

  // Execute command
  executeCommand(data.type, data.params, data.requestId);
}

// Execute Penpot command
async function executeCommand(
  type: string,
  params: any,
  requestId: string
) {
  try {
    let result: any;

    switch (type) {
      case 'create_rectangle':
        result = await createRectangle(params);
        break;
      default:
        throw new Error(`Unknown command: ${type}`);
    }

    // Send success response to Flutter
    sendToFlutter({
      type: `${type}_response`,
      success: true,
      data: result,
      requestId,
      timestamp: new Date().toISOString(),
    });

  } catch (error: any) {
    console.error(`❌ Command failed: ${type}`, error);

    // Send error response to Flutter
    sendToFlutter({
      type: `${type}_response`,
      success: false,
      error: error.message,
      requestId,
      timestamp: new Date().toISOString(),
    });
  }
}

// Create rectangle command
async function createRectangle(params: {
  x: number;
  y: number;
  width: number;
  height: number;
  fillColor?: string;
  name?: string;
}) {
  console.log('📐 Creating rectangle:', params);

  const rect = penpot.createRectangle();

  rect.x = params.x;
  rect.y = params.y;
  rect.width = params.width;
  rect.height = params.height;

  if (params.fillColor) {
    rect.fills = [{ fillColor: params.fillColor, fillOpacity: 1 }];
  }

  if (params.name) {
    rect.name = params.name;
  }

  console.log('✅ Rectangle created:', rect.id);

  return {
    id: rect.id,
    type: 'rectangle',
    x: rect.x,
    y: rect.y,
    width: rect.width,
    height: rect.height,
    name: rect.name,
  };
}

// Send message to Flutter via JavaScript channel
function sendToFlutter(data: any) {
  const message = {
    source: 'asmbli-plugin',
    ...data,
  };

  // Use JavaScript channel registered by Flutter
  if ((window as any).asmbli_bridge) {
    (window as any).asmbli_bridge.postMessage(JSON.stringify(message));
    console.log('📤 SENT TO FLUTTER:', message.type);
  } else {
    console.warn('⚠️ asmbli_bridge not found - Flutter not connected');
  }
}
```

**Commands**:
```bash
cd apps/desktop/assets/penpot_plugin
npm run build
```

**Validates**:
- [ ] TypeScript compiles without errors
- [ ] dist/plugin.js exists
- [ ] Console logs appear in browser DevTools

---

### Task 8: Add JavaScript Bridge to PenpotCanvas
**Requirement**: R2 (Plugin Bridge - bidirectional communication)

**File**: `apps/desktop/lib/core/widgets/penpot_canvas.dart`

**Code Changes**:
```dart
// Add to PenpotCanvasState class:

final StreamController<Map<String, dynamic>> _pluginResponseController =
    StreamController.broadcast();

Stream<Map<String, dynamic>> get pluginResponses =>
    _pluginResponseController.stream;

bool _isPluginLoaded = false;

bool get isPluginLoaded => _isPluginLoaded;

void _initializeWebView() {
  _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..addJavaScriptChannel(
      'asmbli_bridge',
      onMessageReceived: (JavaScriptMessage message) {
        _handlePluginMessage(message.message);
      },
    )
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          setState(() => _isLoaded = true);
          debugPrint('✅ Penpot loaded: $url');
          _injectPlugin();
        },
      ),
    )
    ..loadRequest(Uri.parse('https://design.penpot.app'));
}

// Inject plugin script into Penpot
Future<void> _injectPlugin() async {
  // TODO: Load plugin from assets and inject
  // For now, just mark as ready
  debugPrint('📦 Plugin injection placeholder');
}

// Handle messages from plugin
void _handlePluginMessage(String message) {
  try {
    final data = jsonDecode(message) as Map<String, dynamic>;

    if (data['source'] == 'asmbli-plugin') {
      debugPrint('📥 RECEIVED FROM PLUGIN: ${data['type']}');

      if (data['type'] == 'plugin_ready') {
        setState(() => _isPluginLoaded = true);
      }

      _pluginResponseController.add(data);
    }
  } catch (e) {
    debugPrint('❌ Error parsing plugin message: $e');
  }
}

// Send command to plugin
Future<void> sendCommandToPlugin({
  required String type,
  required Map<String, dynamic> params,
  String? requestId,
}) async {
  final command = {
    'source': 'asmbli-agent',
    'type': type,
    'params': params,
    'requestId': requestId ?? _generateRequestId(),
    'timestamp': DateTime.now().toIso8601String(),
  };

  final commandJson = jsonEncode(command);

  await _controller.runJavaScript('''
    window.postMessage($commandJson, '*');
  ''');

  debugPrint('📤 SENT TO PLUGIN: $type');
}

// Execute command and wait for response
Future<Map<String, dynamic>> executeCommand({
  required String type,
  required Map<String, dynamic> params,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final requestId = _generateRequestId();

  // Listen for response
  final responseFuture = pluginResponses
      .where((response) => response['requestId'] == requestId)
      .first
      .timeout(timeout);

  // Send command
  await sendCommandToPlugin(
    type: type,
    params: params,
    requestId: requestId,
  );

  // Wait for response
  return await responseFuture;
}

String _generateRequestId() {
  return 'req_${DateTime.now().millisecondsSinceEpoch}';
}

@override
void dispose() {
  _pluginResponseController.close();
  super.dispose();
}
```

**Validates**:
- [ ] JavaScript channel registered
- [ ] Plugin messages received in Flutter
- [ ] Commands sent to plugin
- [ ] Request/response matching works

---

### Task 9: Create MCPPenpotServer Skeleton
**Requirement**: R3 (MCP Server)

**File**: `apps/desktop/lib/core/services/mcp_penpot_server.dart`

**Code**:
```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../widgets/penpot_canvas.dart';

/// MCP server for Penpot canvas integration
/// Translates agent MCP requests into Penpot plugin commands
class MCPPenpotServer {
  PenpotCanvasState? _canvasState;
  bool _isInitialized = false;

  // MCP tool handlers
  final Map<String, Function> _tools = {};

  // Request tracking
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  MCPPenpotServer() {
    _registerTools();
  }

  void _registerTools() {
    _tools['create_rectangle'] = createRectangle;
    _tools['get_canvas_state'] = getCanvasState;
  }

  Future<void> initialize(PenpotCanvasState canvasState) async {
    _canvasState = canvasState;

    // Listen for plugin responses
    _canvasState!.pluginResponses.listen((response) {
      _handlePluginResponse(response);
    });

    _isInitialized = true;
    debugPrint('✅ MCPPenpotServer initialized');
  }

  // Process MCP request (called by agent)
  Future<Map<String, dynamic>> processMCPRequest(
    Map<String, dynamic> request,
  ) async {
    if (!_isInitialized) {
      throw Exception('MCPPenpotServer not initialized');
    }

    final method = request['method'] as String;
    final params = request['params'] as Map<String, dynamic>;

    if (method == 'tools/call') {
      final toolName = params['name'] as String;
      final args = params['arguments'] as Map<String, dynamic>;

      final handler = _tools[toolName];
      if (handler == null) {
        return {
          'jsonrpc': '2.0',
          'error': {
            'code': -32601,
            'message': 'Tool not found: $toolName',
          },
          'id': request['id'],
        };
      }

      try {
        final result = await handler(args);

        return {
          'jsonrpc': '2.0',
          'result': result,
          'id': request['id'],
        };
      } catch (e) {
        return {
          'jsonrpc': '2.0',
          'error': {
            'code': -32000,
            'message': e.toString(),
          },
          'id': request['id'],
        };
      }
    }

    return {
      'jsonrpc': '2.0',
      'error': {
        'code': -32601,
        'message': 'Method not supported: $method',
      },
      'id': request['id'],
    };
  }

  // Tool: Create Rectangle
  Future<Map<String, dynamic>> createRectangle(Map<String, dynamic> args) async {
    final response = await _canvasState!.executeCommand(
      type: 'create_rectangle',
      params: args,
    );

    if (response['success'] == true) {
      return response['data'];
    } else {
      throw Exception(response['error']);
    }
  }

  // Tool: Get Canvas State
  Future<Map<String, dynamic>> getCanvasState(Map<String, dynamic> args) async {
    // Placeholder - will implement in Week 2
    return {
      'boards': [],
      'totalElements': 0,
    };
  }

  void _handlePluginResponse(Map<String, dynamic> response) {
    final requestId = response['requestId'] as String?;
    if (requestId != null && _pendingRequests.containsKey(requestId)) {
      _pendingRequests[requestId]!.complete(response);
      _pendingRequests.remove(requestId);
    }
  }

  Map<String, dynamic> getServerInfo() {
    return {
      'name': 'Penpot Canvas Server',
      'version': '1.0.0',
      'tools': _tools.keys.toList(),
      'capabilities': ['tools', 'resources'],
    };
  }

  bool get isInitialized => _isInitialized;
}
```

**Validates**:
- [ ] MCPPenpotServer compiles
- [ ] Can be initialized with PenpotCanvasState
- [ ] Processes MCP requests
- [ ] Returns proper JSON-RPC responses

---

### Task 10: Register MCPPenpotServer with ServiceLocator
**Requirement**: R3 (MCP Server)

**File**: `apps/desktop/lib/core/di/service_locator.dart`

**Code Changes**:
```dart
// Add import
import '../services/mcp_penpot_server.dart';

// In registerServices() method, add:
final mcpPenpotServer = MCPPenpotServer();
_services[MCPPenpotServer] = mcpPenpotServer;
debugPrint('✅ Registered: MCPPenpotServer');
```

**Validates**:
- [ ] Service registered
- [ ] Can be retrieved via `ServiceLocator.instance.get<MCPPenpotServer>()`

---

### Task 11: Test End-to-End (Flutter → Plugin → Rectangle Creation)
**Requirement**: R1, R2, R3 (Proof of concept)

**Test File**: Create manual test in Canvas Library

**Test Scenario**:
1. Open Canvas Library screen
2. Wait for Penpot to load
3. Click test button that calls:
```dart
final canvas = // get PenpotCanvasState reference
final result = await canvas.executeCommand(
  type: 'create_rectangle',
  params: {
    'x': 100,
    'y': 100,
    'width': 200,
    'height': 150,
    'fillColor': '#4ecdc4',
    'name': 'Test Rectangle',
  },
);
print('Result: $result');
```

**Expected Outcome**:
- [ ] Blue-green rectangle appears on Penpot canvas at (100, 100)
- [ ] Rectangle is 200x150px
- [ ] Console shows success response with element ID

**Validates**: Entire integration chain works

---

## Week 2: Plugin Development

**Objective**: Complete Penpot plugin with all commands and templates

**Requirements**: R2 (Full plugin), R6 (Templates), R7 (Canvas state)

---

### Task 12: Implement create_board Command
**Requirement**: R2 (Plugin Bridge)

**File**: `apps/desktop/assets/penpot_plugin/src/commands/createBoard.ts`

**Code**:
```typescript
export async function createBoard(params: {
  name: string;
  width: number;
  height: number;
  fills?: any[];
}) {
  const board = penpot.createBoard();

  board.name = params.name;
  board.width = params.width;
  board.height = params.height;

  if (params.fills) {
    board.fills = params.fills;
  }

  return {
    boardId: board.id,
    name: board.name,
    width: board.width,
    height: board.height,
  };
}
```

**Update**: `src/plugin.ts` to import and use `createBoard`

**Validates**:
- [ ] Board created with correct dimensions
- [ ] Board name set correctly
- [ ] Fill color applied

---

### Task 13: Implement create_element Command (All Shapes)
**Requirement**: R2 (Plugin Bridge)

**File**: `apps/desktop/assets/penpot_plugin/src/commands/createElement.ts`

**Code**:
```typescript
export async function createElement(params: {
  type: string;
  x: number;
  y: number;
  width?: number;
  height?: number;
  text?: string;
  fills?: any[];
  strokes?: any[];
  name?: string;
  fontFamily?: string;
  fontSize?: string;
  fontWeight?: string;
  boardId?: string;
}) {
  let element: any;

  switch (params.type) {
    case 'rectangle':
      element = penpot.createRectangle();
      break;
    case 'ellipse':
      element = penpot.createEllipse();
      break;
    case 'text':
      element = penpot.createText(params.text || 'Text');
      break;
    default:
      throw new Error(`Unsupported element type: ${params.type}`);
  }

  element.x = params.x;
  element.y = params.y;

  if (params.width) element.width = params.width;
  if (params.height) element.height = params.height;

  if (params.fills) element.fills = params.fills;
  if (params.strokes) element.strokes = params.strokes;
  if (params.name) element.name = params.name;

  // Text-specific properties
  if (params.type === 'text') {
    if (params.fontFamily) element.fontFamily = params.fontFamily;
    if (params.fontSize) element.fontSize = params.fontSize;
    if (params.fontWeight) element.fontWeight = params.fontWeight;
  }

  // Add to board if specified
  if (params.boardId) {
    const board = penpot.currentPage?.getShapeById(params.boardId);
    if (board) {
      board.appendChild(element);
    }
  }

  return {
    id: element.id,
    type: params.type,
    x: element.x,
    y: element.y,
    width: element.width,
    height: element.height,
    name: element.name,
  };
}
```

**Validates**:
- [ ] Rectangles, ellipses, text all create correctly
- [ ] Elements positioned correctly
- [ ] Fills and strokes applied
- [ ] Elements added to board when boardId provided

---

### Task 14-17: Implement Template Generators
**Requirement**: R6 (Template System)

These tasks implement the 4 template types: dashboard, form, wireframe, mobile

**(Details omitted for brevity - each template follows similar pattern to dashboard example in design spec)**

**Files**:
- `src/templates/dashboard.ts`
- `src/templates/form.ts`
- `src/templates/wireframe.ts`
- `src/templates/mobile.ts`

**Validates**:
- [ ] Each template creates professional layout
- [ ] Design tokens applied correctly
- [ ] All elements positioned on 8pt grid
- [ ] Components nested properly

---

### Task 18: Implement get_canvas_state Command
**Requirement**: R7 (Canvas State Visibility)

**File**: `apps/desktop/assets/penpot_plugin/src/commands/getCanvasState.ts`

**Code**:
```typescript
export async function getCanvasState() {
  const page = penpot.currentPage;
  if (!page) {
    return {
      boards: [],
      totalElements: 0,
    };
  }

  const boards = page.getShapesByType('board');

  const boardsData = boards.map(board => ({
    id: board.id,
    name: board.name,
    width: board.width,
    height: board.height,
    x: board.x,
    y: board.y,
    elements: board.children.map(child => ({
      id: child.id,
      type: child.type,
      name: child.name,
      x: child.x,
      y: child.y,
      width: child.width,
      height: child.height,
    })),
  }));

  return {
    boards: boardsData,
    totalElements: boardsData.reduce((sum, b) => sum + b.elements.length, 0),
  };
}
```

**Validates**:
- [ ] Returns all boards
- [ ] Returns all elements within boards
- [ ] Element properties correct

---

## Week 3: Flutter Integration

**Objective**: Complete MCPPenpotServer and integrate with agent architecture

**Requirements**: R3 (Full MCP), R5 (Context), R7 (State)

---

### Task 19-24: Implement All MCP Tools

Implement complete tool handlers in `MCPPenpotServer`:

- **Task 19**: `create_board` tool
- **Task 20**: `create_element` tool
- **Task 21**: `create_template` tool
- **Task 22**: `get_canvas_state` tool
- **Task 23**: `get_session_context` tool
- **Task 24**: `get_design_tokens` tool

**(Code details follow design spec patterns)**

**Validates**:
- [ ] All tools callable via MCP protocol
- [ ] All tools return proper JSON-RPC responses
- [ ] Error handling works correctly

---

### Task 25: Integrate with AgentMCPIntegrationService
**Requirement**: R3 (MCP Integration)

**File**: `apps/desktop/lib/core/services/agent_mcp_integration_service.dart`

**Code Changes**:
```dart
// Add method to register Penpot tools with agent
Future<void> registerPenpotTools(String agentId) async {
  final penpotServer = ServiceLocator.instance.get<MCPPenpotServer>();
  final tools = penpotServer.getServerInfo()['tools'] as List<String>;

  for (final tool in tools) {
    await _registerToolWithAgent(agentId, 'penpot', tool);
  }

  debugPrint('✅ Registered ${tools.length} Penpot tools with agent $agentId');
}
```

**Validates**:
- [ ] Penpot tools appear in agent's available tools
- [ ] Agent can call Penpot tools

---

## Week 4: Agent Integration

**Objective**: Implement spec-driven workflow and validate production quality

**Requirements**: R4 (Spec-driven), R8 (Quality)

---

### Task 26: Update Design Agent System Prompt
**Requirement**: R4 (Spec-Driven Workflow)

**File**: `apps/desktop/lib/core/agents/design_agent_system_prompt.md`

**Changes**: Add complete spec-driven workflow section (see design spec for full content)

**Validates**:
- [ ] Agent follows 4-phase workflow
- [ ] Agent asks clarifying questions
- [ ] Agent generates requirements.md
- [ ] Agent waits for approval between phases

---

### Task 27-30: Test Spec-Driven Workflow Phases

- **Task 27**: Test Phase 1 (Requirements generation)
- **Task 28**: Test Phase 2 (Design spec with web search)
- **Task 29**: Test Phase 3 (Task breakdown)
- **Task 30**: Test Phase 4 (Sequential execution)

**Validates**: Complete workflow functions end-to-end

---

## Week 5: Migration and Cleanup

**Objective**: Remove Excalidraw, test thoroughly, finalize

**Requirements**: R9 (Migration), R10 (Testing)

---

### Task 31-35: Remove Excalidraw Code

- **Task 31**: Delete `mcp_excalidraw_server.dart`
- **Task 32**: Delete `mcp_excalidraw_bridge_service.dart`
- **Task 33**: Delete `excalidraw_canvas.dart`
- **Task 34**: Delete `assets/excalidraw/` directory
- **Task 35**: Update all imports and references

**Validates**:
- [ ] No Excalidraw code remains
- [ ] App compiles without errors

---

### Task 36-39: Write Tests

- **Task 36**: Unit tests for MCPPenpotServer
- **Task 37**: Widget tests for PenpotCanvas
- **Task 38**: Integration test (dashboard creation)
- **Task 39**: Integration test (form creation)

**Validates**: Test coverage ≥40%

---

### Task 40: Run flutter analyze
**Requirement**: R10 (Quality)

**Command**:
```bash
cd apps/desktop
flutter analyze
```

**Validates**: No warnings or errors

---

### Task 41: Update Documentation
**Requirement**: R9 (Migration completeness)

**Files to Update**:
- `README.md` - Update canvas section
- `CLAUDE.md` - Update architecture section
- `docs/README_CANVAS_MIGRATION.md` - Mark as complete

**Validates**: Documentation accurate

---

### Task 42: Final End-to-End Test
**Requirement**: All (complete validation)

**Test Scenario**:
1. User adds design_tokens.json to chat session
2. User: "Create a dashboard for our analytics platform"
3. Agent follows 4-phase workflow
4. Agent creates professional dashboard with user's tokens
5. User exports to Flutter code
6. Code compiles and matches design

**Validates**: Entire system works as specified

---

## Success Criteria Summary

After all 42 tasks:

✅ **Functional** (R1-R3, R6-R7):
- [ ] Penpot loads in WebView
- [ ] Plugin communicates bidirectionally
- [ ] All MCP tools work
- [ ] Templates create professional layouts
- [ ] Canvas state readable

✅ **Workflow** (R4-R5):
- [ ] Spec-driven workflow enforced
- [ ] Context library integration works
- [ ] Design tokens applied correctly

✅ **Quality** (R8, R10):
- [ ] Production-quality mockups
- [ ] Test coverage ≥40%
- [ ] flutter analyze passes

✅ **Migration** (R9):
- [ ] Excalidraw completely removed
- [ ] Documentation updated

---

## Task Dependencies Graph

```
Week 1: Setup
├─ Task 1-2 (User: Penpot account) → BLOCKS all others
├─ Task 3-4 (WebView) → ENABLES Task 8
├─ Task 5-7 (Plugin structure) → ENABLES Task 8
├─ Task 8 (JS Bridge) → ENABLES Task 9
├─ Task 9-10 (MCP skeleton) → ENABLES Task 11
└─ Task 11 (Test) → VALIDATES Week 1

Week 2: Plugin
├─ Task 12-13 (Commands) → ENABLES Task 14-17
├─ Task 14-17 (Templates) → ENABLES Week 3
└─ Task 18 (Canvas state) → ENABLES Task 22

Week 3: Flutter
├─ Task 19-24 (MCP tools) → REQUIRES Task 12-18
├─ Task 25 (Agent integration) → REQUIRES Task 19-24
└─ ENABLES Week 4

Week 4: Agent
├─ Task 26 (System prompt) → ENABLES Task 27-30
├─ Task 27-30 (Workflow tests) → VALIDATES workflow
└─ ENABLES Week 5

Week 5: Cleanup
├─ Task 31-35 (Remove Excalidraw) → REQUIRES Week 4 complete
├─ Task 36-39 (Tests) → PARALLEL with Task 31-35
├─ Task 40-41 (Quality/Docs) → REQUIRES Task 31-39
└─ Task 42 (Final test) → VALIDATES all
```

---

**Status**: ✅ READY FOR EXECUTION

**Next Action**: User completes Task 1-2 (Create Penpot account + API token)

**Developer Next Action**: Task 3 (Create PenpotCanvas widget)
