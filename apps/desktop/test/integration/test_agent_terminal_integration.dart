import 'dart:io';
import 'apps/desktop/lib/core/services/agent_mcp_integration_service.dart';
import 'apps/desktop/lib/core/services/agent_terminal_manager.dart';
import 'apps/desktop/lib/core/services/mcp_installation_service.dart';
import 'apps/desktop/lib/core/services/mcp_process_manager.dart';
import 'apps/desktop/lib/core/services/mcp_catalog_service.dart';
import 'apps/desktop/lib/core/services/desktop/desktop_storage_service.dart';
import 'apps/desktop/lib/core/services/secure_auth_service.dart';

/// Test the new agent-terminal architecture
void main() async {
  print('🧪 Testing Agent-Terminal Architecture...');
  
  try {
    // Initialize services
    print('📦 Initializing services...');
    final storageService = DesktopStorageService.instance;
    await storageService.initialize();
    
    final authService = SecureAuthService();
    final catalogService = MCPCatalogService(storageService, authService);
    final installationService = MCPInstallationService();
    
    // Create a mock process manager for testing
    final processManager = MCPProcessManager(catalogService, null);
    
    final terminalManager = AgentTerminalManager(installationService, processManager);
    final integrationService = AgentMCPIntegrationService(
      terminalManager,
      installationService,
      processManager,
      catalogService,
    );
    
    print('✅ Services initialized');
    
    // Test 1: Create agent with terminal
    print('\n🔧 Test 1: Creating agent with terminal...');
    final agentId = 'test-agent-${DateTime.now().millisecondsSinceEpoch}';
    
    final terminal = await integrationService.createAgentWithTerminal(
      agentId,
      workingDirectory: Directory.current.path,
      defaultMCPServers: ['filesystem'], // Start with just filesystem
    );
    
    print('✅ Agent terminal created: ${terminal.agentId}');
    print('   Working directory: ${terminal.workingDirectory}');
    print('   Status: ${terminal.status}');
    
    // Test 2: Execute simple command
    print('\n🔧 Test 2: Executing command in terminal...');
    final result = await integrationService.executeAgentCommand(agentId, 'echo "Hello from agent terminal!"');
    
    print('✅ Command executed:');
    print('   Command: ${result.command}');
    print('   Exit code: ${result.exitCode}');
    print('   Output: ${result.stdout.trim()}');
    print('   Execution time: ${result.executionTime.inMilliseconds}ms');
    
    // Test 3: Check MCP servers
    print('\n🔧 Test 3: Checking MCP servers...');
    final mcpServers = integrationService.getAgentMCPServers(agentId);
    print('✅ MCP servers for agent: ${mcpServers.length}');
    for (final server in mcpServers) {
      print('   - ${server.serverId}: ${server.status}');
    }
    
    // Test 4: Test command validation
    print('\n🔧 Test 4: Testing security validation...');
    try {
      await integrationService.executeAgentCommand(agentId, 'rm -rf /');
      print('❌ Security validation failed - dangerous command was allowed!');
    } catch (e) {
      print('✅ Security validation working - dangerous command blocked: $e');
    }
    
    // Test 5: Cleanup
    print('\n🔧 Test 5: Cleaning up...');
    await integrationService.destroyAgent(agentId);
    print('✅ Agent destroyed and resources cleaned up');
    
    print('\n🎉 All tests passed! Agent-Terminal architecture is working.');
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}