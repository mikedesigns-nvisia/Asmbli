/**
 * PenPOT Plugin Entry Point (Headless Mode)
 * Main plugin file that initializes MCP tools and bridge communication
 * This plugin runs headless - no UI panel, just a communication bridge
 * between PenPot canvas and Flutter app.
 *
 * All AI processing and user interaction happens in the Flutter app.
 * This plugin only executes MCP tool commands on the canvas.
 */

import { MCPToolRegistry } from './mcp/tool-registry';
import { BridgeClient } from './bridge/client';

console.log('🚀 Asmbli Design Agent Plugin initializing (headless mode)...');

// Initialize MCP tool registry
const toolRegistry = new MCPToolRegistry();

// Initialize bridge client for Flutter app communication (HTTP only)
const bridgeClient = new BridgeClient('http://localhost:3000');

// NO UI - Plugin runs headless as a bridge between Flutter and PenPot
// All user interaction happens in Flutter's Design Agent sidebar

// Send connection signal to Flutter app via HTTP when plugin initializes
async function notifyFlutterConnection() {
  const connectionTime = new Date().toISOString();
  const status = {
    connected: true,
    timestamp: connectionTime,
    message: `Plugin connected at ${new Date().toLocaleTimeString()}`,
  };

  console.log(`🔌 Sending connection status to Flutter:`, status);

  try {
    await bridgeClient.httpPost('/plugin-connection', status);
    console.log('✅ Connection status sent to Flutter successfully');
  } catch (error) {
    console.warn('⚠️ Could not send connection status to Flutter:', error);
    console.log('💡 Make sure Flutter app is running on localhost:3000');
  }
}

// Send initial connection notification
notifyFlutterConnection();

// Send connection status periodically in case Flutter app starts after plugin
// This ensures the connection is established even if timing is off
let connectionAttempts = 0;
const maxAttempts = 10; // Try for about 30 seconds
const connectionInterval = setInterval(() => {
  connectionAttempts++;

  if (connectionAttempts >= maxAttempts) {
    clearInterval(connectionInterval);
    console.log('🔌 Connection retry limit reached. Plugin ready for manual reconnection.');
    return;
  }

  console.log(`🔄 Sending connection status (attempt ${connectionAttempts}/${maxAttempts})...`);
  notifyFlutterConnection();
}, 3000);

// Handle MCP tool calls from the bridge/agent (headless - no UI)
async function handleMCPToolCall(toolName: string, parameters: any) {
  try {
    const result = await toolRegistry.executeTool(toolName, parameters);

    // Send result back to Flutter app via bridge
    bridgeClient.sendToolResult({
      success: true,
      data: result,
    });

    console.log(`✅ Tool executed successfully: ${toolName}`);
  } catch (error) {
    console.error('Tool execution error:', error);

    bridgeClient.sendToolResult({
      success: false,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

// Listen for tool calls from Flutter app via bridge
bridgeClient.onToolCall((toolName: string, parameters: any) => {
  handleMCPToolCall(toolName, parameters);
});

// Send ready message to Flutter app
bridgeClient.sendReady();

// Send periodic health status to Flutter app (every 10 seconds)
function sendHealthStatus() {
  const healthStatus = {
    version: '0.1.0',
    toolCount: toolRegistry.getToolCount(),
    capabilities: ['canvas_manipulation', 'mcp_tools', 'browser_execution'],
    status: 'healthy',
    timestamp: new Date().toISOString(),
  };

  bridgeClient.sendHealthStatus(healthStatus);
  console.log('💚 Health status sent to Flutter');
}

// Send initial health status
sendHealthStatus();

// Send health status every 10 seconds for monitoring
setInterval(sendHealthStatus, 10000);

console.log('✅ Asmbli Design Agent Plugin initialized (headless mode)');
