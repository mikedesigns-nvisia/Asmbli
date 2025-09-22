#!/usr/bin/env dart

// Test what happens when I actually try to use the MCPServerExecutionService
import 'dart:io';
import 'apps/desktop/lib/core/models/mcp_server_config.dart';
import 'apps/desktop/lib/core/services/mcp_server_execution_service.dart';

void main() async {
  print('🧪 Testing REAL integration with MCPServerExecutionService...');
  
  final executionService = MCPServerExecutionService();
  
  // Create a real config for the filesystem server
  final config = MCPServerConfig(
    id: 'filesystem-test',
    name: 'Filesystem Server Test',
    url: 'stdio://filesystem',
    command: 'npx',
    args: ['@modelcontextprotocol/server-filesystem', 'C:\\Asmbli'],
    transport: 'stdio',
    autoReconnect: true,
    maxRetries: 3,
    retryDelay: 5000,
    enablePolling: false,
  );
  
  try {
    print('🚀 Attempting to start MCP server via MCPServerExecutionService...');
    
    final serverProcess = await executionService.startMCPServer(config, {});
    
    print('✅ Server process created: ${serverProcess.id}');
    print('✅ Process PID: ${serverProcess.process?.pid}');
    print('✅ Is healthy: ${serverProcess.isHealthy}');
    print('✅ Is initialized: ${serverProcess.isInitialized}');
    
    // Wait a moment and check if it's still working
    await Future.delayed(const Duration(seconds: 3));
    
    print('⏳ After 3 seconds:');
    print('   - Is healthy: ${serverProcess.isHealthy}');
    print('   - Is initialized: ${serverProcess.isInitialized}');
    
    // Try to send an MCP request
    print('📨 Attempting to send MCP request...');
    final response = await executionService.sendMCPRequest(
      config.id,
      'tools/list',
      {},
    );
    
    print('✅ Got MCP response: $response');
    
    // Clean shutdown
    print('🛑 Shutting down...');
    await executionService.stopMCPServer(config.id);
    print('✅ Shutdown complete');
    
  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('📍 Stack trace:');
    print(stackTrace);
    
    print('\n🤔 This likely proves that:');
    print('1. The MCPServerExecutionService expects functionality my minimal class lacks');
    print('2. The handshake/communication logic is broken');  
    print('3. My "proof" was just running servers outside the app architecture');
  }
}