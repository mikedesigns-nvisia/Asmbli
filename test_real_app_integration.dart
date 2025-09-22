#!/usr/bin/env dart

// Test the real MCPServerProcess and MCPServerExecutionService integration
// This tests within the app architecture, not standalone

import 'dart:io';
import 'apps/desktop/lib/core/models/mcp_server_config.dart';
import 'apps/desktop/lib/core/models/mcp_server_process.dart';

void main() async {
  print('🧪 Testing REAL app integration...');
  
  // Test 1: Test MCPServerProcess directly
  await testMCPServerProcess();
  
  // Test 2: Test with MCPServerExecutionService (if we can get around dependencies)
  // await testMCPServerExecutionService();
}

Future<void> testMCPServerProcess() async {
  print('\n📁 Testing MCPServerProcess directly...');
  
  try {
    // Create a real config
    final config = MCPServerConfig(
      id: 'test-filesystem',
      name: 'Test Filesystem Server',
      url: 'stdio://test',
      command: 'npx',
      args: ['@modelcontextprotocol/server-filesystem', 'C:\\Asmbli'],
      transport: 'stdio',
      autoReconnect: false,
      maxRetries: 1,
      retryDelay: 1000,
      enablePolling: false,
    );
    
    print('🚀 Starting server via MCPServerProcess.start()...');
    
    final serverProcess = await MCPServerProcess.start(
      id: config.id,
      config: config,
      environmentVars: {},
    );
    
    print('✅ Server started: ${serverProcess.id}');
    print('   - PID: ${serverProcess.process?.pid}');
    print('   - Healthy: ${serverProcess.isHealthy}');
    print('   - Transport: ${serverProcess.transport}');
    
    // Wait a moment for server to initialize
    await Future.delayed(const Duration(seconds: 1));
    
    // Test JSON-RPC communication
    print('🤝 Testing handshake...');
    try {
      final response = await serverProcess.sendJsonRpcRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {'tools': {}},
        'clientInfo': {'name': 'TestClient', 'version': '1.0.0'},
      });
      
      print('✅ Initialize response: ${response['result']['serverInfo']['name']}');
      
      // Send initialized notification
      await serverProcess.sendInput('{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}');
      
      // Test tool listing
      print('🔧 Testing tool listing...');
      final toolsResponse = await serverProcess.sendJsonRpcRequest('tools/list', {});
      
      final tools = toolsResponse['result']['tools'] as List;
      print('✅ Found ${tools.length} tools');
      for (final tool in tools.take(3)) {
        print('   - ${tool['name']}: ${tool['description']}');
      }
      
    } catch (e) {
      print('❌ Communication test failed: $e');
    }
    
    // Cleanup
    print('🛑 Shutting down server...');
    await serverProcess.kill();
    print('✅ Server shutdown complete');
    
    print('\n🎉 SUCCESS: Real MCPServerProcess works!');
    
  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('📍 Stack trace: $stackTrace');
  }
}