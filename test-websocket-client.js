/**
 * Test WebSocket Client
 * Simulates the PenPot plugin connecting to Flutter's PluginBridgeServer
 */

const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:3000/plugin-bridge');

ws.on('open', function open() {
  console.log('✅ WebSocket connected to Flutter server!');

  // Send plugin-ready message
  const readyMessage = JSON.stringify({
    type: 'plugin-ready',
    timestamp: Date.now(),
  });

  ws.send(readyMessage);
  console.log('📤 Sent plugin-ready message');

  // Send connection status
  setTimeout(() => {
    const statusMessage = JSON.stringify({
      type: 'connection-status',
      connected: true,
      timestamp: new Date().toISOString(),
      message: 'Test plugin connected',
    });

    ws.send(statusMessage);
    console.log('📤 Sent connection-status message');
  }, 1000);
});

ws.on('message', function incoming(data) {
  console.log('📥 Received from Flutter:', data.toString());

  try {
    const message = JSON.parse(data.toString());

    if (message.type === 'tool-call') {
      console.log(`🛠️  Tool call request: ${message.tool}`);
      console.log('   Parameters:', message.parameters);

      // Send mock tool result
      const result = JSON.stringify({
        type: 'tool-result',
        success: true,
        data: {
          message: `Mock result for ${message.tool}`,
          executed: true,
        },
      });

      ws.send(result);
      console.log('📤 Sent tool-result');
    }
  } catch (e) {
    console.error('Error parsing message:', e);
  }
});

ws.on('error', function error(err) {
  console.error('❌ WebSocket error:', err.message);
});

ws.on('close', function close() {
  console.log('🔌 WebSocket connection closed');
});

console.log('🔄 Connecting to ws://localhost:3000/plugin-bridge...');
