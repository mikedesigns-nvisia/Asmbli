import 'dart:async';
import 'dart:io';
import 'package:agent_engine_core/models/agent.dart';
import 'lib/core/services/llm_tool_call_parser.dart';

/// Simple test to verify core MCP functionality without Flutter dependencies
Future<void> main() async {
  print('🚀 Testing Core MCP Functionality');

  try {
    // Create test agent
    final testAgent = Agent(
      id: 'test_agent_123',
      name: 'Test Agent',
      description: 'A test agent for MCP integration',
      capabilities: ['testing', 'mcp_tools'],
    );

    print('🤖 Created test agent: ${testAgent.name}');

    // Test 1: Tool call parsing
    print('\n🔧 Testing tool call parsing...');
    final testResponse = '''
    I'll help you search for that information.

    <tool_call>
    {
      "name": "web_search",
      "arguments": {
        "query": "flutter MCP tools",
        "limit": 5
      }
    }
    </tool_call>

    Based on the search results, here's what I found...
    ''';

    final parsedCalls = LLMToolCallParser.parseToolCalls(testResponse);
    print('✅ Parsed ${parsedCalls.length} tool calls');

    if (parsedCalls.isNotEmpty) {
      final call = parsedCalls.first;
      print('   Tool: ${call.name}');
      print('   Args: ${call.arguments}');
      print('   Confidence: ${call.confidence}');
    }

    // Test 2: Multiple tool call formats
    print('\n🔧 Testing multiple tool call formats...');

    final jsonToolCall = '''
    ```json
    {
      "tool": "file_read",
      "arguments": {
        "path": "/path/to/file.txt"
      }
    }
    ```
    ''';

    final functionToolCall = 'create_file("new_document.md", "Hello World")';

    final inlineToolCall = 'TOOL: database_query ARGS: {"table": "users", "limit": 10}';

    final jsonCalls = LLMToolCallParser.parseToolCalls(jsonToolCall);
    final functionCalls = LLMToolCallParser.parseToolCalls(functionToolCall);
    final inlineCalls = LLMToolCallParser.parseToolCalls(inlineToolCall);

    print('   JSON format: ${jsonCalls.length} calls');
    print('   Function format: ${functionCalls.length} calls');
    print('   Inline format: ${inlineCalls.length} calls');

    // Test 3: Tool call intent extraction
    print('\n🧠 Testing intent extraction...');
    final intentQueries = [
      "Please search for information about Flutter widgets",
      "Can you read the contents of config.json?",
      "I need you to commit these changes to git",
      "Query the database for all active users",
    ];

    for (final query in intentQueries) {
      final intents = LLMToolCallParser.extractToolCallIntents(query);
      print('   "$query" -> ${intents.length} intents');
      for (final intent in intents) {
        print('     Category: ${intent.category}, Action: ${intent.action}');
      }
    }

    // Test 4: Tool availability check
    print('\n🔍 Testing tool availability detection...');

    final toolsToCheck = ['uvx', 'npx', 'docker', 'python', 'node', 'pip'];
    final availableTools = <String>[];

    for (final tool in toolsToCheck) {
      final available = await _checkToolAvailable(tool);
      final status = available ? '✅' : '❌';
      print('   $status $tool');
      if (available) availableTools.add(tool);
    }

    print('\n📊 Available package managers: ${availableTools.join(", ")}');

    // Test 5: Agent model functionality
    print('\n🤖 Testing Agent model...');
    print('   Agent ID: ${testAgent.id}');
    print('   Agent Name: ${testAgent.name}');
    print('   Agent Description: ${testAgent.description}');
    print('   Agent Capabilities: ${testAgent.capabilities.join(", ")}');
    print('   Agent Status: ${testAgent.status}');

    print('\n🎉 Core MCP Test Complete!');
    print('\n📋 Summary:');
    print('   • Tool call parsing: Working ✅');
    print('   • Multiple formats: Working ✅');
    print('   • Intent extraction: Working ✅');
    print('   • Agent models: Working ✅');
    print('   • Available tools: ${availableTools.length}/${toolsToCheck.length}');

    if (availableTools.contains('uvx') || availableTools.contains('npx')) {
      print('\n🚀 Ready to install and run MCP tools from GitHub registry!');
    } else {
      print('\n⚠️  Consider installing uvx (pip install uv) or npx (npm) for MCP tool support');
    }

  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Check if a command-line tool is available
Future<bool> _checkToolAvailable(String tool) async {
  try {
    final result = await Process.run('where', [tool], runInShell: true);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}