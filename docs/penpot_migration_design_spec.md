# Penpot Migration Design Specification

**Date**: 2025-11-15
**Project**: Excalidraw → Penpot Canvas Migration
**Phase**: 2 - Design Specification
**Based On**: [penpot_migration_requirements.md](penpot_migration_requirements.md)

---

## Executive Summary

This document defines the technical architecture for migrating from Excalidraw to Penpot. The design uses a hybrid approach (WebView + Plugin API) with a layered architecture that integrates seamlessly with Asmbli's existing MCP infrastructure.

**Core Approach**: Flutter WebView embeds Penpot → TypeScript Plugin bridges agent commands → Dart MCP Server translates agent requests → Spec-driven workflow prevents "vibe designing"

---

## System Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Asmbli Desktop App                       │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │           Canvas Library Screen                     │    │
│  │  ┌──────────────────────────────────────────────┐  │    │
│  │  │        PenpotCanvas (Flutter Widget)          │  │    │
│  │  │  ┌────────────────────────────────────────┐  │  │    │
│  │  │  │    WebView (webview_flutter)           │  │  │    │
│  │  │  │  ┌──────────────────────────────────┐  │  │  │    │
│  │  │  │  │   Penpot Web App                 │  │  │  │    │
│  │  │  │  │   (design.penpot.app)            │  │  │  │    │
│  │  │  │  │                                  │  │  │  │    │
│  │  │  │  │  ┌────────────────────────────┐ │  │  │  │    │
│  │  │  │  │  │  Asmbli Agent Bridge       │ │  │  │  │    │
│  │  │  │  │  │  (Penpot Plugin)           │ │  │  │  │    │
│  │  │  │  │  │  - TypeScript              │ │  │  │  │    │
│  │  │  │  │  │  - Penpot Plugin API       │ │  │  │  │    │
│  │  │  │  │  └────────────────────────────┘ │  │  │  │    │
│  │  │  │  └──────────────────────────────────┘  │  │  │    │
│  │  │  │           ↕ JavaScript Bridge          │  │  │    │
│  │  │  └────────────────────────────────────────┘  │  │    │
│  │  └──────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────┘    │
│                         ↕                                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │         MCPPenpotServer (Dart Service)             │    │
│  │  - Translates MCP requests to plugin commands      │    │
│  │  - Manages JavaScript bridge communication         │    │
│  │  - Implements spec-driven workflow                 │    │
│  └────────────────────────────────────────────────────┘    │
│                         ↕                                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │        AgentMCPIntegrationService                  │    │
│  │  - Registers Penpot MCP tools with agent           │    │
│  │  - Provides canvas context to agent                │    │
│  └────────────────────────────────────────────────────┘    │
│                         ↕                                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Design Agent Chat                      │    │
│  │  - Follows spec-driven workflow                    │    │
│  │  - Calls MCP tools to create designs               │    │
│  │  - Reads session context for design tokens         │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Specifications

### 1. PenpotCanvas Widget (Flutter)

**Purpose**: Embed Penpot web app in Flutter with JavaScript bridge for bidirectional communication

**Location**: `apps/desktop/lib/core/widgets/penpot_canvas.dart`

**Dependencies**:
- `webview_flutter: ^4.0.0`
- `dart:convert` (JSON encoding)
- `dart:async` (StreamController)

**State Management**:
```dart
class PenpotCanvasState extends State<PenpotCanvas> {
  late WebViewController _controller;
  late StreamController<Map<String, dynamic>> _pluginResponseController;

  String? _currentProjectId;
  bool _isPluginLoaded = false;

  Stream<Map<String, dynamic>> get pluginResponses =>
    _pluginResponseController.stream;
}
```

**Initialization Flow**:
```dart
@override
void initState() {
  super.initState();

  _pluginResponseController = StreamController.broadcast();

  _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) => _onPenpotLoaded(),
      ),
    )
    ..addJavaScriptChannel(
      'asmbli_bridge',
      onMessageReceived: (JavaScriptMessage message) {
        _handlePluginMessage(message.message);
      },
    )
    ..loadRequest(Uri.parse(_getPenpotUrl()));
}
```

**JavaScript Bridge - Flutter → Plugin**:
```dart
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
```

**JavaScript Bridge - Plugin → Flutter**:
```dart
void _handlePluginMessage(String message) {
  try {
    final data = jsonDecode(message) as Map<String, dynamic>;

    if (data['source'] == 'asmbli-plugin') {
      debugPrint('📥 RECEIVED FROM PLUGIN: ${data['type']}');
      _pluginResponseController.add(data);
    }
  } catch (e) {
    debugPrint('❌ Error parsing plugin message: $e');
  }
}
```

**Public Methods**:
```dart
class PenpotCanvasState {
  // Send command and wait for response
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

  // Check if plugin is loaded
  bool get isPluginLoaded => _isPluginLoaded;

  // Get current project ID
  String? get currentProjectId => _currentProjectId;
}
```

**Widget Build**:
```dart
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

          // Loading overlay
          if (!_isPluginLoaded)
            Container(
              color: colors.surface.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: colors.primary),
                    SizedBox(height: SpacingTokens.md),
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
```

---

### 2. Penpot Plugin (TypeScript)

**Purpose**: Bridge between agent commands and Penpot Plugin API

**Location**: `apps/desktop/assets/penpot_plugin/` (embedded in app)

**Project Structure**:
```
apps/desktop/assets/penpot_plugin/
├── manifest.json           # Plugin metadata
├── plugin.ts               # Main plugin logic
├── commands/               # Command handlers
│   ├── createBoard.ts
│   ├── createElement.ts
│   ├── createTemplate.ts
│   └── getCanvasState.ts
├── templates/              # Template generators
│   ├── dashboard.ts
│   ├── form.ts
│   ├── wireframe.ts
│   └── mobile.ts
└── utils/                  # Helpers
    ├── designTokens.ts
    └── layout.ts
```

**manifest.json**:
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
  "host": "penpot.app"
}
```

**plugin.ts - Main Entry Point**:
```typescript
import type { PluginMessageEvent } from '@penpot/plugin-types';

// Initialize plugin
penpot.on('ready', () => {
  console.log('🎨 Asmbli Agent Bridge loaded');

  // Listen for messages from Flutter
  window.addEventListener('message', handleFlutterMessage);

  // Notify Flutter that plugin is ready
  sendToFlutter({
    type: 'plugin_ready',
    success: true,
  });
});

// Handle messages from Flutter WebView
function handleFlutterMessage(event: MessageEvent) {
  const data = event.data;

  // Verify message source
  if (data.source !== 'asmbli-agent') {
    return;
  }

  console.log(`📥 RECEIVED FROM FLUTTER: ${data.type}`);

  // Route to appropriate handler
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
      case 'create_board':
        result = await createBoard(params);
        break;
      case 'create_element':
        result = await createElement(params);
        break;
      case 'create_component':
        result = await createComponent(params);
        break;
      case 'create_template':
        result = await createTemplate(params);
        break;
      case 'get_canvas_state':
        result = await getCanvasState(params);
        break;
      case 'apply_design_tokens':
        result = await applyDesignTokens(params);
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
    });

  } catch (error) {
    // Send error response to Flutter
    sendToFlutter({
      type: `${type}_response`,
      success: false,
      error: error.message,
      requestId,
    });
  }
}

// Send message to Flutter
function sendToFlutter(data: any) {
  // Use JavaScript channel registered by Flutter
  if (window.asmbli_bridge) {
    window.asmbli_bridge.postMessage(JSON.stringify({
      source: 'asmbli-plugin',
      ...data,
    }));
  }
}
```

**commands/createElement.ts**:
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

  // Set position
  element.x = params.x;
  element.y = params.y;

  // Set size (if provided)
  if (params.width) element.width = params.width;
  if (params.height) element.height = params.height;

  // Set fills
  if (params.fills) {
    element.fills = params.fills;
  }

  // Set strokes
  if (params.strokes) {
    element.strokes = params.strokes;
  }

  // Set name
  if (params.name) {
    element.name = params.name;
  }

  // Add to board (if specified)
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

**templates/dashboard.ts**:
```typescript
import { applyDesignTokens } from '../utils/designTokens';

export async function createDashboard(params: {
  name?: string;
  designTokens?: any;
}) {
  const tokens = params.designTokens || getDefaultTokens();

  // Create board
  const board = penpot.createBoard();
  board.name = params.name || 'Dashboard';
  board.width = 1440;
  board.height = 900;
  board.fills = [{ fillColor: tokens.colors.background }];

  // Create header (1440x80px)
  const header = penpot.createRectangle();
  header.name = 'Header';
  header.x = 0;
  header.y = 0;
  header.width = 1440;
  header.height = 80;
  header.fills = [{ fillColor: tokens.colors.surface }];
  board.appendChild(header);

  // Create header title
  const title = penpot.createText('Analytics Dashboard');
  title.name = 'Title';
  title.x = 24;
  title.y = 28;
  title.fontFamily = tokens.typography.headingFamily;
  title.fontSize = '24';
  title.fontWeight = '600';
  title.fills = [{ fillColor: tokens.colors.onSurface }];
  board.appendChild(title);

  // Create metric cards (2x2 grid)
  const cardWidth = 280;
  const cardHeight = 160;
  const gap = 16;
  const startX = 24;
  const startY = 100;

  const metrics = [
    { label: 'Total Users', value: '12,453', trend: '+12%' },
    { label: 'Active Sessions', value: '2,341', trend: '+8%' },
    { label: 'Conversion Rate', value: '3.2%', trend: '+0.4%' },
    { label: 'Revenue', value: '$45.2K', trend: '+15%' },
  ];

  metrics.forEach((metric, index) => {
    const row = Math.floor(index / 2);
    const col = index % 2;
    const x = startX + col * (cardWidth + gap);
    const y = startY + row * (cardHeight + gap);

    const card = createMetricCard({
      x,
      y,
      width: cardWidth,
      height: cardHeight,
      label: metric.label,
      value: metric.value,
      trend: metric.trend,
      tokens,
    });

    board.appendChild(card);
  });

  return {
    boardId: board.id,
    elementCount: board.children.length,
  };
}

function createMetricCard(params: any) {
  const group = penpot.createGroup();

  // Card background
  const bg = penpot.createRectangle();
  bg.x = params.x;
  bg.y = params.y;
  bg.width = params.width;
  bg.height = params.height;
  bg.fills = [{ fillColor: params.tokens.colors.surface }];
  bg.strokes = [{
    strokeColor: params.tokens.colors.border,
    strokeWidth: 1,
    strokeAlignment: 'inner',
  }];
  bg.borderRadius = 8;
  group.appendChild(bg);

  // Label text
  const label = penpot.createText(params.label);
  label.x = params.x + 16;
  label.y = params.y + 16;
  label.fontFamily = params.tokens.typography.bodyFamily;
  label.fontSize = '14';
  label.fills = [{ fillColor: params.tokens.colors.onSurfaceVariant }];
  group.appendChild(label);

  // Value text
  const value = penpot.createText(params.value);
  value.x = params.x + 16;
  value.y = params.y + 50;
  value.fontFamily = params.tokens.typography.headingFamily;
  value.fontSize = '28';
  value.fontWeight = '600';
  value.fills = [{ fillColor: params.tokens.colors.onSurface }];
  group.appendChild(value);

  // Trend text
  const trend = penpot.createText(params.trend);
  trend.x = params.x + 16;
  trend.y = params.y + 100;
  trend.fontFamily = params.tokens.typography.bodyFamily;
  trend.fontSize = '12';
  trend.fills = [{ fillColor: params.tokens.colors.success }];
  group.appendChild(trend);

  return group;
}

function getDefaultTokens() {
  return {
    colors: {
      background: '#13161f',
      surface: '#1a1d29',
      onSurface: '#e8e9ed',
      onSurfaceVariant: '#9ca3af',
      border: '#2d3139',
      success: '#4ecdc4',
    },
    typography: {
      headingFamily: 'Space Grotesk',
      bodyFamily: 'Inter',
    },
  };
}
```

---

### 3. MCPPenpotServer (Dart Service)

**Purpose**: MCP server that translates agent requests into Penpot plugin commands

**Location**: `apps/desktop/lib/core/services/mcp_penpot_server.dart`

**Dependencies**:
- `PenpotCanvasState` (for JavaScript bridge)
- `ChatSessionService` (for session context)
- `ServiceLocator` (for dependency injection)

**Class Structure**:
```dart
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
    _tools['create_board'] = createBoard;
    _tools['create_element'] = createElement;
    _tools['create_component'] = createComponent;
    _tools['create_template'] = createTemplate;
    _tools['get_canvas_state'] = getCanvasState;
    _tools['apply_design_tokens'] = applyDesignTokens;
    _tools['get_session_context'] = getSessionContext;
    _tools['get_design_tokens'] = getDesignTokens;
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
    Map<String, dynamic> request
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

  // Tool implementations

  Future<Map<String, dynamic>> createBoard(Map<String, dynamic> args) async {
    final response = await _canvasState!.executeCommand(
      type: 'create_board',
      params: args,
    );

    if (response['success'] == true) {
      return response['data'];
    } else {
      throw Exception(response['error']);
    }
  }

  Future<Map<String, dynamic>> createElement(Map<String, dynamic> args) async {
    final response = await _canvasState!.executeCommand(
      type: 'create_element',
      params: args,
    );

    if (response['success'] == true) {
      return response['data'];
    } else {
      throw Exception(response['error']);
    }
  }

  Future<Map<String, dynamic>> createTemplate(Map<String, dynamic> args) async {
    // Get design tokens from session context
    final tokens = await getDesignTokens({});

    // Send to plugin with tokens
    final response = await _canvasState!.executeCommand(
      type: 'create_template',
      params: {
        ...args,
        'designTokens': tokens,
      },
    );

    if (response['success'] == true) {
      return response['data'];
    } else {
      throw Exception(response['error']);
    }
  }

  Future<Map<String, dynamic>> getCanvasState(Map<String, dynamic> args) async {
    final response = await _canvasState!.executeCommand(
      type: 'get_canvas_state',
      params: args,
    );

    if (response['success'] == true) {
      return response['data'];
    } else {
      throw Exception(response['error']);
    }
  }

  Future<Map<String, dynamic>> getSessionContext(Map<String, dynamic> args) async {
    final sessionService = ServiceLocator.instance.get<ChatSessionService>();
    final sessionContext = await sessionService.getAttachedContext();

    return {
      'documents': sessionContext.map((doc) => {
        'title': doc.title,
        'category': doc.category,
        'content': doc.content,
        'added_at': doc.addedAt.toIso8601String(),
      }).toList(),
      'total': sessionContext.length,
    };
  }

  Future<Map<String, dynamic>> getDesignTokens(Map<String, dynamic> args) async {
    // Try to get from session context first
    final sessionContext = await getSessionContext({});
    final documents = sessionContext['documents'] as List;

    final tokensDoc = documents.firstWhere(
      (doc) => doc['title'] == 'design_tokens.json' ||
               doc['category'] == 'design_tokens',
      orElse: () => null,
    );

    if (tokensDoc != null) {
      return jsonDecode(tokensDoc['content']);
    }

    // Fallback to app design tokens
    return _getAppDesignTokens();
  }

  Map<String, dynamic> _getAppDesignTokens() {
    // Read from Asmbli design system
    return {
      'colors': {
        'primary': '#4ecdc4',
        'accent': '#ffd700',
        'background': '#13161f',
        'surface': '#1a1d29',
        'onSurface': '#e8e9ed',
        'onSurfaceVariant': '#9ca3af',
        'border': '#2d3139',
        'success': '#4ecdc4',
        'warning': '#ffd700',
        'error': '#ff6b6b',
      },
      'spacing': {
        'xs': 4,
        'sm': 8,
        'md': 13,
        'lg': 16,
        'xl': 21,
        'xxl': 24,
      },
      'typography': {
        'headingFamily': 'Space Grotesk',
        'bodyFamily': 'Inter',
        'sizes': {
          'xs': 12,
          'sm': 14,
          'md': 16,
          'lg': 20,
          'xl': 24,
          'xxl': 28,
        },
      },
      'borderRadius': {
        'sm': 2,
        'md': 6,
        'lg': 8,
        'xl': 12,
      },
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
}
```

---

### 4. Spec-Driven Workflow Integration

**Purpose**: Implement 4-phase spec-driven design workflow in agent system prompt

**Location**: Update `apps/desktop/lib/core/agents/design_agent_system_prompt.md`

**System Prompt Additions**:

````markdown
## Spec-Driven Design Workflow (MANDATORY)

You MUST follow this 4-phase workflow for ALL design requests. NEVER skip directly to implementation.

### Phase 1: Requirements Gathering

When a user requests a design:

1. **Ask Clarifying Questions** (3-5 questions):
   - Who is the target user?
   - What specific data/content should be displayed?
   - Are there any visual style preferences?
   - What are the key functional requirements?
   - What is the success criteria?

2. **Check Session Context**:
   ```
   Call: get_session_context()
   Review: Brand guidelines, design tokens, component libraries
   Note: Which context documents will inform this design
   ```

3. **Generate requirements.md**:
   ```markdown
   ## R1: [Requirement Name]
   **As a** [user type]
   **I want** [functionality]
   **So that** [benefit]

   **Acceptance Criteria:**
   - GIVEN [context]
   - WHEN [action]
   - THEN [expected result]

   **Visual Requirements:**
   - [Specific sizes, colors, layouts]
   ```

4. **Present to User**:
   > "I've documented the requirements based on your needs and the brand guidelines you provided. Please review and let me know if I should adjust anything before moving to design."

5. **Iterate**: Update requirements based on user feedback

6. **Get Approval**: Do not proceed to Phase 2 without user approval

### Phase 2: Design Specification

After requirements approval:

1. **Research Current Trends**:
   ```
   Identify design type (dashboard, form, landing page, etc.)
   Web search: "2025 [design_type] design patterns best practices"
   Extract: Layout patterns, color trends, typography styles
   ```

2. **Read Design Tokens**:
   ```
   Call: get_design_tokens()
   Match: Brand colors, spacing, typography
   Apply: Exact values (no approximations)
   ```

3. **Analyze Existing Canvas** (if applicable):
   ```
   Call: get_canvas_state()
   Identify: Existing patterns to match
   Ensure: New design integrates with existing elements
   ```

4. **Generate design_spec.md**:
   ```markdown
   # Design Specification: [Project Name]

   ## Component Architecture
   [ASCII diagram showing layout structure]

   ## Design Token Mappings
   - Primary Color: #4ecdc4 (from brand guidelines)
   - Spacing: 8pt grid (xs:4, sm:8, md:13, lg:16)
   - Typography: Space Grotesk (headings), Inter (body)

   ## Component Specifications
   ### [Component Name]
   **Structure:** [Layout description]
   **States:** Default, Hover, Active
   **Variants:** [List variants]

   ## Implementation Approach
   1. Create board
   2. Build header component
   3. Create metric card component
   4. Apply auto-layout
   5. Add interactive states
   ```

5. **Present to User**:
   > "I've created a design specification that follows 2025 dashboard patterns and uses your brand colors. The spec defines 4 components with auto-layout. Should I proceed with this approach?"

6. **Iterate**: Update spec based on feedback

7. **Get Approval**: Do not proceed to Phase 3 without approval

### Phase 3: Implementation Tasks

After design spec approval:

1. **Break Spec into Tasks** (5-10 atomic tasks):
   - Each task should be completable independently
   - Each task maps to specific requirements (R1, R2, etc.)
   - Each task has clear validation criteria

2. **Generate design_tasks.md**:
   ```markdown
   # Implementation Tasks: [Project Name]

   ## Task 1: Setup Canvas Board
   **Requirement:** R1 (Foundation)

   - [ ] Create Penpot board "[Project Name]"
   - [ ] Set dimensions: 1440x900px
   - [ ] Set background: #13161f

   **MCP Commands:**
   \`\`\`json
   create_board({
     "name": "[Project Name]",
     "width": 1440,
     "height": 900,
     "fills": [{ "fillColor": "#13161f" }]
   })
   \`\`\`

   **Validates:** Board exists and is correct size

   ---

   ## Task 2: Create Header Component
   **Requirement:** R2 (Navigation)

   - [ ] Create rectangle: 1440x80px at (0, 0)
   - [ ] Fill: #1a1d29
   - [ ] Add title text: "[Project Name]"
   - [ ] Convert to component

   **MCP Commands:**
   \`\`\`json
   create_element({
     "type": "rectangle",
     "x": 0,
     "y": 0,
     "width": 1440,
     "height": 80,
     "fills": [{ "fillColor": "#1a1d29" }],
     "name": "Header"
   })

   create_element({
     "type": "text",
     "text": "[Project Name]",
     "x": 24,
     "y": 28,
     "fontFamily": "Space Grotesk",
     "fontSize": "24"
   })
   \`\`\`

   **Validates:** Header matches R2 acceptance criteria
   ```

3. **Present to User**:
   > "I've broken the design into 7 sequential tasks. Each task maps to your requirements and includes the MCP commands I'll execute. Should I proceed with implementation?"

4. **Get Approval**: Do not proceed to Phase 4 without approval

### Phase 4: Execution

After task approval:

1. **Execute Tasks Sequentially**:
   ```
   For each task:
     - Announce: "Executing Task [N]: [Task Name]"
     - Execute MCP commands
     - Validate against acceptance criteria
     - Report: "✅ Task [N] complete"
   ```

2. **Progress Tracking**:
   - Update user after each task completion
   - Report any issues immediately
   - Ask for guidance if task cannot be completed as specified

3. **Final Validation**:
   ```
   Call: get_canvas_state()
   Verify: All requirements met
   Check: Accessibility (contrast ≥ 4.5:1)
   Confirm: Design matches spec
   ```

4. **Completion Report**:
   > "All 7 tasks complete! Validating against requirements:
   > ✅ R1: Metric cards visible in 2x2 grid
   > ✅ R2: Header with branding
   > ✅ R3: Chart area with data visualization
   >
   > Design is complete and matches your brand guidelines. Would you like me to export to Flutter code?"

### Workflow Rules (CRITICAL)

**NEVER skip phases** - Always complete 1 → 2 → 3 → 4 in order

**NEVER "vibe design"** - No random shapes hoping they work

**ALWAYS trace to requirements** - Every element must map to an R# requirement

**ALWAYS wait for approval** - Get user confirmation between phases

**ALWAYS use exact values** - Apply design tokens precisely (no approximations)

**ALWAYS validate** - Check acceptance criteria after each task

### Example Conversation

```
User: "Create a dashboard for our analytics platform"

Agent: "I'll create this using a spec-driven approach. First, let me ask a few questions:

1. Who will use this dashboard (developers, PMs, executives)?
2. What specific metrics should it display?
3. What time ranges for data (daily, weekly, monthly)?
4. Any specific visualizations needed (charts, graphs, tables)?

I also see you've added 'Brand Guidelines v2.1' and 'Design Tokens 2024' to this session. I'll use those for colors and typography."

User: "Product managers. Show total users, active sessions, conversion rate, and revenue. Monthly data. Include a trend chart."

Agent: "Perfect. Let me document the requirements..."

[Generates requirements.md]

Agent: "Review these requirements. Do they capture your needs?"

User: "Yes, add hover tooltips on the trend chart"

Agent: "Updated R2 with tooltip requirement. Now generating design specification..."

[Generates design_spec.md using web search for 2025 trends + user's design tokens]

Agent: "This spec follows 2025 dashboard patterns and uses your primary color #4ecdc4. Does this approach work?"

User: "Looks great"

Agent: "Breaking into implementation tasks..."

[Generates design_tasks.md with 7 sequential tasks]

Agent: "Here's the execution plan. Should I proceed?"

User: "Yes, execute"

Agent: "Executing Task 1: Setup Canvas Board..."
✅ Task 1 complete

Agent: "Executing Task 2: Create Header Component..."
✅ Task 2 complete

[... continues through all tasks ...]

Agent: "All tasks complete! Dashboard ready. Export to code?"
```
````

---

## Implementation Timeline

### Week 1: Setup and Proof of Concept (R1, R2 basics, R3 skeleton)

**Objective**: Validate the hybrid approach works

**Tasks**:
1. User creates Penpot account at design.penpot.app
2. User generates API token
3. Create PenpotCanvas widget (basic WebView)
4. Create Penpot plugin project
5. Implement single command (create_rectangle)
6. Test JavaScript bridge bidirectionally
7. Create MCPPenpotServer skeleton

**Success Criteria**:
- Penpot loads in WebView
- Plugin receives command from Flutter
- Rectangle appears on Penpot canvas
- Plugin sends confirmation back to Flutter

**Deliverables**:
- `penpot_canvas.dart` (basic implementation)
- `plugin.ts` (minimal plugin)
- `mcp_penpot_server.dart` (skeleton)

---

### Week 2: Plugin Development (R2, R6, R7)

**Objective**: Complete Penpot plugin with all commands and templates

**Tasks**:
1. Implement all create commands (board, element, component)
2. Implement template generators (dashboard, form, wireframe, mobile)
3. Implement getCanvasState command
4. Add error handling and logging
5. Test all commands in Penpot UI
6. Optimize template layouts

**Success Criteria**:
- All MCP commands work
- Templates create professional layouts
- Canvas state readable
- Error messages returned to Flutter

**Deliverables**:
- Complete plugin.ts
- All template generators
- Command handlers

---

### Week 3: Flutter Integration (R3, R5, R7)

**Objective**: Complete MCPPenpotServer and integrate with existing architecture

**Tasks**:
1. Implement all MCP tool handlers
2. Add getSessionContext integration
3. Add getDesignTokens with fallback
4. Register with ServiceLocator
5. Update AgentMCPIntegrationService
6. Test end-to-end agent → MCP → plugin flow

**Success Criteria**:
- MCPPenpotServer fully functional
- Agent can call all MCP tools
- Design tokens applied from session context
- Canvas state readable by agent

**Deliverables**:
- Complete `mcp_penpot_server.dart`
- ServiceLocator registration
- Integration with agent system

---

### Week 4: Agent Integration (R4, R8)

**Objective**: Implement spec-driven workflow and ensure production quality

**Tasks**:
1. Update design_agent_system_prompt.md with 4-phase workflow
2. Test Phase 1: Requirements generation
3. Test Phase 2: Design spec with web search
4. Test Phase 3: Task breakdown
5. Test Phase 4: Sequential execution
6. Validate production-quality output
7. Test accessibility (contrast ratios)

**Success Criteria**:
- Agent follows 4-phase workflow
- Agent generates structured specs
- Agent waits for approval between phases
- Designs match modern aesthetics
- Accessibility standards met

**Deliverables**:
- Updated system prompt
- Example spec files (dashboard, form)
- Validated designs

---

### Week 5: Migration and Cleanup (R9, R10)

**Objective**: Remove Excalidraw, test thoroughly, finalize migration

**Tasks**:
1. Remove Excalidraw services
2. Remove Excalidraw widgets
3. Remove Excalidraw assets
4. Update ServiceLocator
5. Write unit tests (MCPPenpotServer)
6. Write widget tests (PenpotCanvas)
7. Write integration tests (end-to-end workflows)
8. Run flutter analyze (fix all warnings)
9. Update documentation

**Success Criteria**:
- No Excalidraw code remains
- Test coverage ≥40% for new code
- flutter analyze passes
- All integration tests pass
- Documentation updated

**Deliverables**:
- Clean codebase
- Test suites
- Updated docs

---

## Design Token Format

User-provided design tokens should follow this JSON format:

```json
{
  "colors": {
    "primary": "#4ecdc4",
    "accent": "#ffd700",
    "background": "#13161f",
    "surface": "#1a1d29",
    "onSurface": "#e8e9ed",
    "onSurfaceVariant": "#9ca3af",
    "border": "#2d3139",
    "success": "#4ecdc4",
    "warning": "#ffd700",
    "error": "#ff6b6b"
  },
  "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 13,
    "lg": 16,
    "xl": 21,
    "xxl": 24
  },
  "typography": {
    "headingFamily": "Space Grotesk",
    "bodyFamily": "Inter",
    "sizes": {
      "xs": 12,
      "sm": 14,
      "md": 16,
      "lg": 20,
      "xl": 24,
      "xxl": 28
    },
    "weights": {
      "regular": "400",
      "medium": "500",
      "semibold": "600",
      "bold": "700"
    }
  },
  "borderRadius": {
    "sm": 2,
    "md": 6,
    "lg": 8,
    "xl": 12
  },
  "shadows": {
    "sm": "0 1px 2px rgba(0,0,0,0.05)",
    "md": "0 4px 6px rgba(0,0,0,0.1)",
    "lg": "0 10px 15px rgba(0,0,0,0.1)"
  }
}
```

---

## Testing Strategy

### Unit Tests

**Test File**: `apps/desktop/test/unit/services/mcp_penpot_server_test.dart`

**Test Cases**:
```dart
group('MCPPenpotServer', () {
  late MCPPenpotServer server;
  late MockPenpotCanvasState mockCanvas;

  setUp(() {
    mockCanvas = MockPenpotCanvasState();
    server = MCPPenpotServer();
    await server.initialize(mockCanvas);
  });

  test('creates board with correct parameters', () async {
    final args = {
      'name': 'Test Board',
      'width': 1440,
      'height': 900,
    };

    when(mockCanvas.executeCommand(any)).thenAnswer((_) async => {
      'success': true,
      'data': {'boardId': 'board-123'},
    });

    final result = await server.createBoard(args);

    expect(result['boardId'], 'board-123');
  });

  test('applies design tokens from session context', () async {
    // Mock session service with design tokens
    final mockSession = MockChatSessionService();
    ServiceLocator.instance.register<ChatSessionService>(mockSession);

    when(mockSession.getAttachedContext()).thenAnswer((_) async => [
      ContextDocument(
        title: 'design_tokens.json',
        content: jsonEncode({'colors': {'primary': '#4ecdc4'}}),
      ),
    ]);

    final tokens = await server.getDesignTokens({});

    expect(tokens['colors']['primary'], '#4ecdc4');
  });

  test('falls back to app design tokens when none in session', () async {
    final mockSession = MockChatSessionService();
    ServiceLocator.instance.register<ChatSessionService>(mockSession);

    when(mockSession.getAttachedContext()).thenAnswer((_) async => []);

    final tokens = await server.getDesignTokens({});

    expect(tokens['colors']['primary'], '#4ecdc4'); // App default
  });
});
```

### Widget Tests

**Test File**: `apps/desktop/test/widget/penpot_canvas_test.dart`

**Test Cases**:
```dart
testWidgets('PenpotCanvas loads WebView', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PenpotCanvas(),
    ),
  );

  expect(find.byType(WebViewWidget), findsOneWidget);
});

testWidgets('Shows loading state while plugin initializes', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PenpotCanvas(),
    ),
  );

  expect(find.text('Loading Penpot Canvas...'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### Integration Tests

**Test File**: `apps/desktop/test/integration/penpot_workflow_test.dart`

**Test Cases**:
```dart
testWidgets('Agent creates dashboard end-to-end', (tester) async {
  // Initialize services
  await setupServiceLocator();

  // Open canvas
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('Canvas Library'));
  await tester.pumpAndSettle();

  // Wait for Penpot to load
  await tester.pump(Duration(seconds: 5));

  // Send agent command
  final mcpServer = ServiceLocator.instance.get<MCPPenpotServer>();
  final result = await mcpServer.createTemplate({
    'template': 'dashboard',
  });

  expect(result['boardId'], isNotNull);
  expect(result['elementCount'], greaterThan(0));
});
```

---

## Success Metrics

After implementation, validate:

✅ **Functional**:
- [ ] Penpot loads in WebView
- [ ] Plugin receives all command types
- [ ] All templates create correct layouts
- [ ] Canvas state readable
- [ ] Design tokens applied correctly

✅ **Quality**:
- [ ] Designs match 2025 aesthetic standards
- [ ] Accessibility contrast ≥4.5:1
- [ ] Components reusable
- [ ] Auto-layout applied

✅ **Technical**:
- [ ] Test coverage ≥40%
- [ ] flutter analyze passes
- [ ] No Excalidraw code remains
- [ ] Performance: <500ms command execution

✅ **User Experience**:
- [ ] Spec-driven workflow functions
- [ ] User approval required between phases
- [ ] Context library integration works
- [ ] Code export generates usable Flutter widgets

---

## Risk Mitigation

### Risk 1: Penpot Plugin API Changes
**Mitigation**: Pin Penpot version, monitor changelog, create abstraction layer

### Risk 2: WebView Performance
**Mitigation**: Optimize plugin code, use requestAnimationFrame, debounce updates

### Risk 3: JavaScript Bridge Reliability
**Mitigation**: Add retries, timeouts, error recovery, request/response tracking

### Risk 4: Context Token Parsing
**Mitigation**: Validate JSON schema, provide clear error messages, fallback to defaults

---

**Status**: ✅ READY FOR IMPLEMENTATION

**Dependencies Met**: Requirements approved (Phase 1 complete)

**Next Phase**: Phase 3 (Implementation Tasks) - Break into week-by-week checklist
