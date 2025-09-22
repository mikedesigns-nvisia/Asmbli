#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Test actual tool calling with MCP server
/// This proves the entire flow: spawn -> initialize -> list tools -> call tool
void main() async {
  print('🚀 Testing real MCP tool calling...');
  
  await testFullMCPFlow();
}

Future<void> testFullMCPFlow() async {
  print('\n📁 Testing complete MCP flow with filesystem server...');
  
  try {
    // Launch the server
    print('🔧 Launching MCP filesystem server...');
    final process = await Process.start(
      'npx',
      ['@modelcontextprotocol/server-filesystem', 'C:\\AgentEngine'],
      runInShell: true,
    );
    
    print('✅ Process started with PID: ${process.pid}');
    
    // Buffer for server responses
    final List<String> serverMessages = [];
    
    // Listen to stdout for responses
    process.stdout.transform(utf8.decoder).listen((data) {
      final lines = data.split('\n').where((line) => line.trim().isNotEmpty);
      for (final line in lines) {
        print('📤 Server response: $line');
        serverMessages.add(line.trim());
      }
    });
    
    process.stderr.transform(utf8.decoder).listen((data) {
      print('⚠️  Server stderr: $data');
    });
    
    // Give the server a moment to start
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Step 1: Initialize
    print('\n🤝 Step 1: Initialize...');
    await sendRequest(process, {
      'jsonrpc': '2.0',
      'id': '1',
      'method': 'initialize',
      'params': {
        'protocolVersion': '2024-11-05',
        'capabilities': {'tools': {}},
        'clientInfo': {'name': 'TestClient', 'version': '1.0.0'},
      },
    });
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Step 2: Send initialized notification
    print('\n📋 Step 2: Send initialized notification...');
    await sendNotification(process, {
      'jsonrpc': '2.0',
      'method': 'notifications/initialized',
      'params': {},
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Step 3: List available tools
    print('\n🔧 Step 3: List tools...');
    await sendRequest(process, {
      'jsonrpc': '2.0',
      'id': '2',
      'method': 'tools/list',
      'params': {},
    });
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Step 4: Try to call a tool (read_file)
    print('\n📖 Step 4: Call read_file tool...');
    await sendRequest(process, {
      'jsonrpc': '2.0',
      'id': '3',
      'method': 'tools/call',
      'params': {
        'name': 'read_file',
        'arguments': {
          'path': 'README.md'
        },
      },
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    // Clean shutdown
    print('\n🛑 Shutting down server...');
    process.kill();
    await process.exitCode;
    print('✅ Server shutdown complete');
    
    print('\n📊 Summary:');
    print('- Server messages received: ${serverMessages.length}');
    for (int i = 0; i < serverMessages.length; i++) {
      print('  ${i + 1}. ${serverMessages[i]}');
    }
    
  } catch (e) {
    print('❌ Error in MCP flow: $e');
  }
}

Future<void> sendRequest(Process process, Map<String, dynamic> request) async {
  final requestJson = json.encode(request);
  print('📨 Request: $requestJson');
  process.stdin.writeln(requestJson);
}

Future<void> sendNotification(Process process, Map<String, dynamic> notification) async {
  final notificationJson = json.encode(notification);
  print('📨 Notification: $notificationJson');
  process.stdin.writeln(notificationJson);
}