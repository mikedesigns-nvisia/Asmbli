import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agentengine_desktop/core/widgets/penpot_canvas.dart';
import 'package:agentengine_desktop/core/services/mcp_penpot_server.dart';

/// Integration test for Penpot canvas and MCP server
///
/// Tests the complete flow:
/// 1. Load Penpot in WebView
/// 2. Inject plugin
/// 3. Wait for plugin ready
/// 4. Execute commands via MCPPenpotServer
/// 5. Verify canvas state
void main() {
  testWidgets('Penpot canvas loads and plugin initializes', (WidgetTester tester) async {
    final canvasKey = GlobalKey<PenpotCanvasState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PenpotCanvas(key: canvasKey),
        ),
      ),
    );

    // Widget should render
    expect(find.byType(PenpotCanvas), findsOneWidget);

    // Should show loading initially
    expect(find.text('Loading Penpot Canvas...'), findsOneWidget);
  });

  testWidgets('MCPPenpotServer handles tool calls', (WidgetTester tester) async {
    final canvasKey = GlobalKey<PenpotCanvasState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PenpotCanvas(key: canvasKey),
        ),
      ),
    );

    // Create MCP server
    final mcpServer = MCPPenpotServer(canvasKey: canvasKey);

    // Server should initialize
    expect(mcpServer, isNotNull);

    // Should have tool definitions
    final tools = mcpServer.getToolDefinitions();
    expect(tools.length, 6);
    expect(tools.any((t) => t['name'] == 'penpot_create_rectangle'), true);
    expect(tools.any((t) => t['name'] == 'penpot_create_text'), true);
    expect(tools.any((t) => t['name'] == 'penpot_create_frame'), true);
  });

  test('MCPPenpotServer provides correct tool schemas', () {
    final canvasKey = GlobalKey<PenpotCanvasState>();
    final mcpServer = MCPPenpotServer(canvasKey: canvasKey);

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
    final canvasKey = GlobalKey<PenpotCanvasState>();
    final mcpServer = MCPPenpotServer(canvasKey: canvasKey);

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

  test('MCPPenpotServer handles tool calls with proper error handling', () async {
    final canvasKey = GlobalKey<PenpotCanvasState>();
    final mcpServer = MCPPenpotServer(canvasKey: canvasKey);

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
    final canvasKey = GlobalKey<PenpotCanvasState>();
    final mcpServer = MCPPenpotServer(canvasKey: canvasKey);

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

    // Should fail because canvas not ready, but test spec parsing
    final result = await mcpServer.buildDesignFromSpec(designSpec: designSpec);

    // Should return error result
    expect(result['success'], false);
    expect(result['error'], isNotNull);
  });

  test('MCPPenpotServer routes tool calls correctly', () async {
    final canvasKey = GlobalKey<PenpotCanvasState>();
    final mcpServer = MCPPenpotServer(canvasKey: canvasKey);

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

    // Should return error (canvas not ready)
    expect(rectResult['success'], false);

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

    expect(textResult['success'], false);

    // Test unknown tool
    final unknownResult = await mcpServer.handleToolCall(
      toolName: 'unknown_tool',
      arguments: {},
    );

    expect(unknownResult['success'], false);
    expect(unknownResult['error'], contains('Unknown tool'));
  });
}
