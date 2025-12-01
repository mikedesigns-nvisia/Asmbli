import 'package:flutter_test/flutter_test.dart';
import 'package:agentengine_desktop/core/services/mcp_penpot_server.dart';
import 'package:agentengine_desktop/core/interfaces/penpot_canvas_interface.dart';

/// Mock implementation of PenpotCanvasInterface for testing
class MockPenpotCanvas implements PenpotCanvasInterface {
  bool _isPluginLoaded = true;
  final Map<String, dynamic> _lastCommand = {};

  @override
  bool get isPluginLoaded => _isPluginLoaded;

  void setPluginLoaded(bool loaded) {
    _isPluginLoaded = loaded;
  }

  Map<String, dynamic> get lastCommand => _lastCommand;

  @override
  Future<Map<String, dynamic>> executeCommand({
    required String type,
    required Map<String, dynamic> params,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _lastCommand['type'] = type;
    _lastCommand['params'] = params;

    // Simulate successful response
    return {
      'success': true,
      'data': {
        'id': 'mock-element-id',
        ...params,
      },
    };
  }
}

void main() {
  test('MCPPenpotServer initializes correctly', () {
    final mockCanvas = MockPenpotCanvas();
    final mcpServer = MCPPenpotServer(canvas: mockCanvas);

    expect(mcpServer, isNotNull);
    expect(mcpServer.isReady, true);
  });

  test('MCPPenpotServer provides correct tool schemas', () {
    final mockCanvas = MockPenpotCanvas();
    final mcpServer = MCPPenpotServer(canvas: mockCanvas);

    final tools = mcpServer.getToolDefinitions();

    // Rectangle tool schema
    final rectTool = tools.firstWhere((t) => t['name'] == 'penpot_create_rectangle');
    expect(rectTool['description'], isNotNull);
    expect(rectTool['inputSchema'], isNotNull);
    expect(rectTool['inputSchema']['type'], 'object');
    expect(rectTool['inputSchema']['properties'], isNotNull);
    expect(rectTool['inputSchema']['properties']['x'], isNotNull);
    expect(rectTool['inputSchema']['properties']['width'], isNotNull);
    expect(rectTool['inputSchema']['properties']['fill'], isNotNull);

    // Text tool schema
    final textTool = tools.firstWhere((t) => t['name'] == 'penpot_create_text');
    expect(textTool['inputSchema']['properties']['content'], isNotNull);
    expect(textTool['inputSchema']['properties']['fontSize'], isNotNull);
    expect(textTool['inputSchema']['required'], contains('content'));
  });

  test('MCPPenpotServer agent intelligence methods', () {
    final mockCanvas = MockPenpotCanvas();
    final mcpServer = MCPPenpotServer(canvas: mockCanvas);

    // Grid snapping
    expect(mcpServer.applyGridSnapping(17), 16); // Rounds to nearest 8px
    expect(mcpServer.applyGridSnapping(20), 24);
    expect(mcpServer.applyGridSnapping(8), 8);

    // Font size calculation (golden ratio)
    final primarySize = mcpServer.calculateFontSize(importance: 'primary', baseSize: 16);
    expect(primarySize, closeTo(25.9, 0.1)); // 16 * 1.618

    final secondarySize = mcpServer.calculateFontSize(importance: 'secondary', baseSize: 16);
    expect(secondarySize, 16); // Base size

    final tertiarySize = mcpServer.calculateFontSize(importance: 'tertiary', baseSize: 16);
    expect(tertiarySize, closeTo(9.9, 0.1)); // 16 / 1.618

    // Spacing calculation
    expect(mcpServer.calculateSpacing(context: 'tight'), 8);
    expect(mcpServer.calculateSpacing(context: 'normal'), 16);
    expect(mcpServer.calculateSpacing(context: 'loose'), 24);
  });

  test('MCPPenpotServer executes createRectangle correctly', () async {
    final mockCanvas = MockPenpotCanvas();
    final mcpServer = MCPPenpotServer(canvas: mockCanvas);

    await mcpServer.createRectangle(
      x: 100,
      y: 100,
      width: 200,
      height: 150,
      fill: '#4ECDC4',
    );

    expect(mockCanvas.lastCommand['type'], 'create_rectangle');
    expect(mockCanvas.lastCommand['params']['x'], 100);
    expect(mockCanvas.lastCommand['params']['fill'], '#4ECDC4');
  });

  test('MCPPenpotServer handles tool calls with proper error handling', () async {
    final mockCanvas = MockPenpotCanvas();
    mockCanvas.setPluginLoaded(false); // Simulate not ready
    final mcpServer = MCPPenpotServer(canvas: mockCanvas);

    // Should fail gracefully when canvas not ready
    try {
      await mcpServer.createRectangle(
        x: 100,
        y: 100,
        width: 200,
        height: 150,
        fill: '#4ECDC4',
      );
      fail('Should throw exception when canvas not ready');
    } catch (e) {
      expect(e.toString(), contains('Canvas not ready'));
    }
  });

  test('MCPPenpotServer buildDesignFromSpec parses spec correctly', () async {
    final mockCanvas = MockPenpotCanvas();
    final mcpServer = MCPPenpotServer(canvas: mockCanvas);

    final designSpec = {
      'elements': [
        {
          'type': 'rectangle',
          'name': 'Card Background',
          'x': 100.0,
          'y': 100.0,
          'width': 320.0,
          'height': 200.0,
          'fill': '#FFFFFF',
          'borderRadius': 8.0,
        },
        {
          'type': 'text',
          'name': 'Title',
          'content': 'Pricing Card',
          'x': 124.0,
          'y': 124.0,
          'fontSize': 24.0,
          'fontWeight': 600,
          'color': '#1A1A1A',
        },
      ],
    };

    final result = await mcpServer.buildDesignFromSpec(designSpec: designSpec);

    expect(result['success'], true);
    expect(result['elementsCreated'], 2);
    
    // Note: In a real test we would verify the sequence of calls, 
    // but our simple mock only stores the last one.
    expect(mockCanvas.lastCommand['type'], 'create_text'); // Last element
  });

  test('MCPPenpotServer routes tool calls correctly', () async {
    final mockCanvas = MockPenpotCanvas();
    final mcpServer = MCPPenpotServer(canvas: mockCanvas);

    // Test rectangle tool routing
    final rectResult = await mcpServer.handleToolCall(
      toolName: 'penpot_create_rectangle',
      arguments: {
        'x': 100.0,
        'y': 100.0,
        'width': 200.0,
        'height': 150.0,
        'fill': '#4ECDC4',
      },
    );

    expect(rectResult, isNotNull); // Should succeed now with mock
    expect(rectResult['id'], 'mock-element-id');
    expect(mockCanvas.lastCommand['type'], 'create_rectangle');

    // Test text tool routing
    final textResult = await mcpServer.handleToolCall(
      toolName: 'penpot_create_text',
      arguments: {
        'content': 'Hello World',
        'x': 100.0,
        'y': 100.0,
        'fontSize': 16.0,
      },
    );

    expect(textResult, isNotNull);
    expect(textResult['id'], 'mock-element-id');
    expect(mockCanvas.lastCommand['type'], 'create_text');

    // Test unknown tool
    final unknownResult = await mcpServer.handleToolCall(
      toolName: 'unknown_tool',
      arguments: {},
    );

    expect(unknownResult['success'], false);
    expect(unknownResult['error'], contains('Unknown tool'));
  });
}
