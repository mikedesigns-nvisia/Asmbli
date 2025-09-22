#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Minimal test to prove we can launch a real MCP server and communicate with it
/// This bypasses all the UI facades and tests the core concept
void main() async {
  print('🚀 Testing real MCP server launch...');
  
  // Test 1: Try to launch npx @modelcontextprotocol/server-filesystem
  await testFilesystemServer();
}

Future<void> testFilesystemServer() async {
  print('\n📁 Testing @modelcontextprotocol/server-filesystem...');
  
  try {
    // Check if npx is available
    final npxCheck = await Process.run('npx', ['--version'], runInShell: true);
    if (npxCheck.exitCode != 0) {
      print('❌ npx not available: ${npxCheck.stderr}');
      return;
    }
    print('✅ npx version: ${npxCheck.stdout}'.trim());
    
    // Try to launch the filesystem server
    print('🔧 Launching MCP filesystem server...');
    final process = await Process.start(
      'npx',
      ['@modelcontextprotocol/server-filesystem', 'C:\\AgentEngine'],
      runInShell: true,
    );
    
    print('✅ Process started with PID: ${process.pid}');
    
    // Set up stdout/stderr listeners
    process.stdout.transform(utf8.decoder).listen((data) {
      print('📤 Server stdout: $data');
    });
    
    process.stderr.transform(utf8.decoder).listen((data) {
      print('⚠️  Server stderr: $data');
    });
    
    // Send an MCP initialize request
    print('🤝 Sending initialize request...');
    final initRequest = {
      'jsonrpc': '2.0',
      'id': '1',
      'method': 'initialize',
      'params': {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'tools': {},
          'resources': {},
        },
        'clientInfo': {
          'name': 'TestClient',
          'version': '1.0.0',
        },
      },
    };
    
    final requestJson = json.encode(initRequest);
    print('📨 Sending: $requestJson');
    
    process.stdin.writeln(requestJson);
    
    // Wait for response or timeout
    print('⏳ Waiting for response...');
    await Future.delayed(const Duration(seconds: 5));
    
    // Clean shutdown
    print('🛑 Shutting down server...');
    process.kill();
    
    await process.exitCode;
    print('✅ Server shutdown complete');
    
  } catch (e) {
    print('❌ Error testing filesystem server: $e');
  }
}