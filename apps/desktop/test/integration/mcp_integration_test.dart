import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentengine_desktop/core/services/mcp_settings_service.dart';
import 'package:agentengine_desktop/core/services/mcp_process_manager.dart';
import 'package:agentengine_desktop/core/services/mcp_conversation_bridge_service.dart';
import 'package:agentengine_desktop/core/services/mcp_protocol_handler.dart';
import 'package:agentengine_desktop/core/models/mcp_server_config.dart';
import 'package:agentengine_desktop/features/tools/presentation/providers/simple_real_execution_provider.dart';
import 'package:agentengine_desktop/features/tools/presentation/widgets/catalogue_tab.dart';
import '../test_helpers/test_app_wrapper.dart';
import '../test_helpers/mock_services.dart';

/// SR-003: Test MCP integration flows work correctly
void main() {
  group('MCP Integration Tests', () {
    late ProviderContainer container;
    late MockDesktopStorageService mockStorageService;
    late MockMCPSettingsService mockMCPSettingsService;
    late MockMCPProcessManager mockProcessManager;
    late MockMCPConversationBridge mockConversationBridge;

    setUp(() {
      mockStorageService = MockDesktopStorageService();
      mockMCPSettingsService = MockMCPSettingsService();
      mockProcessManager = MockMCPProcessManager();
      mockConversationBridge = MockMCPConversationBridge();
      
      container = ProviderContainer(
        overrides: [
          desktopStorageServiceProvider.overrideWithValue(mockStorageService),
          mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
          mcpProcessManagerProvider.overrideWithValue(mockProcessManager),
          mcpConversationBridgeProvider.overrideWithValue(mockConversationBridge),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('SR-003.1: MCP settings service initializes correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
          ],
        ),
      );

      // Act: Initialize MCP settings service
      final mcpService = container.read(mcpSettingsServiceProvider);
      await mcpService.initialize();

      // Assert: Service should be initialized
      expect(mcpService.isInitialized, true);
      expect(mockMCPSettingsService.initializeCalled, true);
    });

    testWidgets('SR-003.2: MCP server configuration and storage works', (tester) async {
      // Arrange: Create test server config
      final serverConfig = MCPServerConfig(
        id: 'test-filesystem-server',
        name: 'Test Filesystem Server',
        url: '',
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
        protocol: 'stdio',
        description: 'Test filesystem access server',
        enabled: true,
        capabilities: ['files', 'directories'],
      );

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
          ],
        ),
      );

      // Act: Set MCP server configuration
      final mcpService = container.read(mcpSettingsServiceProvider);
      await mcpService.setMCPServer(serverConfig.id, serverConfig);

      // Assert: Verify server was stored
      expect(mockMCPSettingsService.setMCPServerCalled, true);
      expect(mockMCPSettingsService.storedServers.containsKey(serverConfig.id), true);
      
      // Verify we can retrieve the server
      final retrievedServer = await mcpService.getMCPServer(serverConfig.id);
      expect(retrievedServer?.name, equals('Test Filesystem Server'));
      expect(retrievedServer?.protocol, equals('stdio'));
    });

    testWidgets('SR-003.3: MCP server process management works', (tester) async {
      // Arrange: Set up server config
      final serverConfig = MCPServerConfig(
        id: 'test-server',
        name: 'Test Server',
        url: '',
        command: 'python',
        args: ['-m', 'test_server'],
        protocol: 'stdio',
        enabled: true,
      );

      mockMCPSettingsService.addMockServer(serverConfig);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
            mcpProcessManagerProvider.overrideWithValue(mockProcessManager),
          ],
        ),
      );

      // Act: Start MCP server process
      final processManager = container.read(mcpProcessManagerProvider);
      await processManager.startServer(serverConfig.id, serverConfig);

      // Assert: Verify process was started
      expect(mockProcessManager.startServerCalled[serverConfig.id], true);
      expect(mockProcessManager.isServerRunning(serverConfig.id), true);
    });

    testWidgets('SR-003.4: MCP protocol communication works', (tester) async {
      // Arrange: Set up running server
      final serverConfig = MCPServerConfig(
        id: 'test-protocol-server',
        name: 'Test Protocol Server',
        url: '',
        command: 'test-command',
        protocol: 'stdio',
        enabled: true,
      );

      mockMCPSettingsService.addMockServer(serverConfig);
      mockProcessManager.setMockServerRunning(serverConfig.id, true);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
            mcpProcessManagerProvider.overrideWithValue(mockProcessManager),
          ],
        ),
      );

      // Act: Send protocol message
      final processManager = container.read(mcpProcessManagerProvider);
      final response = await processManager.sendMessage(serverConfig.id, {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'tools/list',
        'params': {},
      });

      // Assert: Verify message was sent and response received
      expect(mockProcessManager.sendMessageCalled[serverConfig.id], true);
      expect(response, isA<Map<String, dynamic>>());
      expect(response['result'], isNotNull);
    });

    testWidgets('SR-003.5: MCP conversation bridge integration works', (tester) async {
      // Arrange: Set up conversation context
      mockConversationBridge.setMockConversationContext('test-conversation', {
        'messages': [
          {'role': 'user', 'content': 'List files in current directory'},
        ],
        'agent_id': 'test-agent',
      });

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpConversationBridgeProvider.overrideWithValue(mockConversationBridge),
          ],
        ),
      );

      // Act: Process message through bridge
      final bridge = container.read(mcpConversationBridgeProvider);
      final result = await bridge.processMessage(
        'test-conversation',
        'List files in current directory',
        ['test-filesystem-server'],
      );

      // Assert: Verify bridge processed the message
      expect(mockConversationBridge.processMessageCalled, true);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['tools_used'], isA<List>());
    });

    testWidgets('SR-003.6: MCP server health monitoring works', (tester) async {
      // Arrange: Set up multiple servers
      final servers = [
        MCPServerConfig(
          id: 'healthy-server',
          name: 'Healthy Server',
          url: '',
          command: 'test-healthy',
          protocol: 'stdio',
          enabled: true,
        ),
        MCPServerConfig(
          id: 'unhealthy-server',
          name: 'Unhealthy Server',
          url: '',
          command: 'test-broken',
          protocol: 'stdio',
          enabled: true,
        ),
      ];

      for (final server in servers) {
        mockMCPSettingsService.addMockServer(server);
      }

      mockProcessManager.setMockServerRunning('healthy-server', true);
      mockProcessManager.setMockServerRunning('unhealthy-server', false);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
            mcpProcessManagerProvider.overrideWithValue(mockProcessManager),
          ],
        ),
      );

      // Act: Check server health
      final mcpService = container.read(mcpSettingsServiceProvider);
      final healthyStatus = await mcpService.testMCPServerConnection('healthy-server');
      final unhealthyStatus = await mcpService.testMCPServerConnection('unhealthy-server');

      // Assert: Verify health statuses
      expect(healthyStatus.isConnected, true);
      expect(healthyStatus.status, equals(ConnectionStatus.connected));
      expect(unhealthyStatus.isConnected, false);
      expect(unhealthyStatus.status, equals(ConnectionStatus.error));
    });

    testWidgets('SR-003.7: MCP tools catalogue integration works', (tester) async {
      // Arrange: Set up catalogue with mock servers
      mockMCPSettingsService.addMockCatalogueEntry(MockMCPCatalogueEntry(
        id: 'filesystem-tools',
        name: 'Filesystem Tools',
        description: 'File system operations',
        command: 'npx @modelcontextprotocol/server-filesystem',
        protocol: 'stdio',
        capabilities: ['files', 'directories'],
      ));

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
          ],
          child: const MaterialApp(home: CatalogueTab()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify catalogue displays available tools
      expect(find.text('Filesystem Tools'), findsOneWidget);
      expect(find.text('File system operations'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('SR-003.8: MCP server installation works', (tester) async {
      // Arrange: Set up catalogue entry for installation
      final catalogueEntry = MockMCPCatalogueEntry(
        id: 'web-search-tools',
        name: 'Web Search Tools',
        description: 'Internet search capabilities',
        command: 'npx @modelcontextprotocol/server-web-search',
        protocol: 'stdio',
        capabilities: ['web_search'],
        installationCommand: 'npm install -g @modelcontextprotocol/server-web-search',
      );

      mockMCPSettingsService.addMockCatalogueEntry(catalogueEntry);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
          ],
        ),
      );

      // Act: Install MCP server
      final toolsProvider = container.read(simpleRealExecutionProvider.notifier);
      await toolsProvider.installServer('web-search-tools');

      // Assert: Verify installation was attempted
      expect(mockMCPSettingsService.installServerCalled['web-search-tools'], true);
      
      // Verify server was added to configuration
      final installedServer = await mockMCPSettingsService.getMCPServer('web-search-tools');
      expect(installedServer?.name, equals('Web Search Tools'));
    });

    testWidgets('SR-003.9: MCP error handling and recovery works', (tester) async {
      // Arrange: Set up server that will fail
      final problematicServer = MCPServerConfig(
        id: 'failing-server',
        name: 'Failing Server',
        url: '',
        command: 'non-existent-command',
        protocol: 'stdio',
        enabled: true,
      );

      mockMCPSettingsService.addMockServer(problematicServer);
      mockProcessManager.setShouldFailStart('failing-server', true);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
            mcpProcessManagerProvider.overrideWithValue(mockProcessManager),
          ],
        ),
      );

      // Act: Try to start failing server
      final processManager = container.read(mcpProcessManagerProvider);
      
      // Assert: Verify error is handled gracefully
      expect(
        () => processManager.startServer(problematicServer.id, problematicServer),
        throwsA(isA<MCPServerException>()),
      );

      // Verify error status is recorded
      final status = await mockMCPSettingsService.testMCPServerConnection('failing-server');
      expect(status.status, equals(ConnectionStatus.error));
      expect(status.message, contains('failed'));
    });

    testWidgets('SR-003.10: MCP capability discovery works', (tester) async {
      // Arrange: Set up server with capabilities
      final capableServer = MCPServerConfig(
        id: 'capable-server',
        name: 'Capable Server',
        url: '',
        command: 'test-capable-server',
        protocol: 'stdio',
        enabled: true,
        capabilities: ['files', 'web_search', 'database'],
      );

      mockMCPSettingsService.addMockServer(capableServer);
      mockProcessManager.setMockCapabilities('capable-server', [
        {'name': 'list_files', 'description': 'List files in directory'},
        {'name': 'search_web', 'description': 'Search the internet'},
        {'name': 'query_db', 'description': 'Query database'},
      ]);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
            mcpProcessManagerProvider.overrideWithValue(mockProcessManager),
          ],
        ),
      );

      // Act: Discover server capabilities
      final processManager = container.read(mcpProcessManagerProvider);
      final capabilities = await processManager.discoverCapabilities('capable-server');

      // Assert: Verify capabilities were discovered
      expect(capabilities.length, equals(3));
      expect(capabilities.any((c) => c['name'] == 'list_files'), true);
      expect(capabilities.any((c) => c['name'] == 'search_web'), true);
      expect(capabilities.any((c) => c['name'] == 'query_db'), true);
    });

    testWidgets('SR-003.11: MCP agent deployment configuration works', (tester) async {
      // Arrange: Set up agent with MCP servers
      final agentId = 'test-agent';
      final mcpServers = [
        MCPServerConfig(
          id: 'fs-server',
          name: 'Filesystem Server',
          url: '',
          command: 'fs-server',
          protocol: 'stdio',
          enabled: true,
        ),
        MCPServerConfig(
          id: 'web-server',
          name: 'Web Server',
          url: '',
          command: 'web-server',
          protocol: 'stdio',
          enabled: true,
        ),
      ];

      for (final server in mcpServers) {
        mockMCPSettingsService.addMockServer(server);
      }

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            mcpSettingsServiceProvider.overrideWithValue(mockMCPSettingsService),
          ],
        ),
      );

      // Act: Get agent deployment configuration
      final mcpService = container.read(mcpSettingsServiceProvider);
      final deploymentConfig = await mcpService.getAgentDeploymentConfig(agentId);

      // Assert: Verify deployment configuration
      expect(deploymentConfig.agentId, equals(agentId));
      expect(deploymentConfig.mcpServerConfigs.length, equals(2));
      expect(deploymentConfig.mcpServerConfigs.containsKey('fs-server'), true);
      expect(deploymentConfig.mcpServerConfigs.containsKey('web-server'), true);
    });
  });
}

/// Mock MCP Settings Service for testing
class MockMCPSettingsService implements MCPSettingsService {
  bool _isInitialized = false;
  bool initializeCalled = false;
  bool setMCPServerCalled = false;
  final Map<String, bool> installServerCalled = {};
  final Map<String, MCPServerConfig> storedServers = {};
  final List<MockMCPCatalogueEntry> catalogueEntries = [];

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    initializeCalled = true;
  }

  @override
  Future<void> setMCPServer(String serverId, MCPServerConfig config) async {
    setMCPServerCalled = true;
    storedServers[serverId] = config;
  }

  @override
  Future<MCPServerConfig?> getMCPServer(String serverId) async {
    return storedServers[serverId];
  }

  @override
  Future<List<MCPServerConfig>> getAllMCPServers() async {
    return storedServers.values.toList();
  }

  @override
  Future<MCPServerStatus> testMCPServerConnection(String serverId) async {
    final server = storedServers[serverId];
    if (server == null) {
      return MCPServerStatus(
        serverId: serverId,
        isConnected: false,
        lastChecked: DateTime.now(),
        status: ConnectionStatus.error,
        message: 'Server not found',
      );
    }

    // Simulate health check based on server name
    final isHealthy = !server.name.toLowerCase().contains('unhealthy') && 
                     !server.name.toLowerCase().contains('failing');

    return MCPServerStatus(
      serverId: serverId,
      isConnected: isHealthy,
      lastChecked: DateTime.now(),
      status: isHealthy ? ConnectionStatus.connected : ConnectionStatus.error,
      message: isHealthy ? 'Connected successfully' : 'Connection failed',
    );
  }

  @override
  Future<AgentDeploymentConfig> getAgentDeploymentConfig(String agentId) async {
    final serverConfigs = <String, Map<String, dynamic>>{};
    
    for (final entry in storedServers.entries) {
      if (entry.value.enabled) {
        serverConfigs[entry.key] = entry.value.toJson();
      }
    }

    return AgentDeploymentConfig(
      agentId: agentId,
      mcpServerConfigs: serverConfigs,
      contextDocuments: [],
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> removeMCPServer(String serverId) async {
    storedServers.remove(serverId);
  }

  @override
  Future<void> resetToDefaults() async {
    storedServers.clear();
  }

  // Test helper methods
  void addMockServer(MCPServerConfig server) {
    storedServers[server.id] = server;
  }

  void addMockCatalogueEntry(MockMCPCatalogueEntry entry) {
    catalogueEntries.add(entry);
  }

  Future<void> installServer(String serverId) async {
    installServerCalled[serverId] = true;
    
    final catalogueEntry = catalogueEntries.firstWhere((e) => e.id == serverId);
    final serverConfig = MCPServerConfig(
      id: serverId,
      name: catalogueEntry.name,
      url: '',
      command: catalogueEntry.command,
      protocol: catalogueEntry.protocol,
      description: catalogueEntry.description,
      capabilities: catalogueEntry.capabilities,
      enabled: true,
    );
    
    storedServers[serverId] = serverConfig;
  }

  void clearMockData() {
    storedServers.clear();
    catalogueEntries.clear();
    installServerCalled.clear();
    initializeCalled = false;
    setMCPServerCalled = false;
  }
}

/// Mock MCP Process Manager for testing
class MockMCPProcessManager implements MCPProcessManager {
  final Map<String, bool> startServerCalled = {};
  final Map<String, bool> sendMessageCalled = {};
  final Map<String, bool> runningServers = {};
  final Map<String, bool> shouldFailStart = {};
  final Map<String, List<Map<String, dynamic>>> serverCapabilities = {};

  @override
  Future<void> startServer(String serverId, MCPServerConfig config) async {
    startServerCalled[serverId] = true;
    
    if (shouldFailStart[serverId] == true) {
      throw MCPServerException('Failed to start server $serverId');
    }
    
    runningServers[serverId] = true;
  }

  @override
  Future<void> stopServer(String serverId) async {
    runningServers[serverId] = false;
  }

  @override
  bool isServerRunning(String serverId) {
    return runningServers[serverId] ?? false;
  }

  @override
  Future<Map<String, dynamic>> sendMessage(String serverId, Map<String, dynamic> message) async {
    sendMessageCalled[serverId] = true;
    
    // Simulate response based on message method
    final method = message['method'] as String?;
    switch (method) {
      case 'tools/list':
        return {
          'jsonrpc': '2.0',
          'id': message['id'],
          'result': {'tools': serverCapabilities[serverId] ?? []},
        };
      default:
        return {
          'jsonrpc': '2.0',
          'id': message['id'],
          'result': {},
        };
    }
  }

  @override
  Future<List<Map<String, dynamic>>> discoverCapabilities(String serverId) async {
    return serverCapabilities[serverId] ?? [];
  }

  // Test helper methods
  void setMockServerRunning(String serverId, bool isRunning) {
    runningServers[serverId] = isRunning;
  }

  void setShouldFailStart(String serverId, bool shouldFail) {
    shouldFailStart[serverId] = shouldFail;
  }

  void setMockCapabilities(String serverId, List<Map<String, dynamic>> capabilities) {
    serverCapabilities[serverId] = capabilities;
  }

  void clearMockData() {
    startServerCalled.clear();
    sendMessageCalled.clear();
    runningServers.clear();
    shouldFailStart.clear();
    serverCapabilities.clear();
  }
}

/// Mock MCP Conversation Bridge for testing
class MockMCPConversationBridge implements MCPConversationBridgeService {
  bool processMessageCalled = false;
  final Map<String, Map<String, dynamic>> conversationContexts = {};

  @override
  Future<Map<String, dynamic>> processMessage(
    String conversationId,
    String message,
    List<String> enabledServerIds,
  ) async {
    processMessageCalled = true;
    
    return {
      'conversation_id': conversationId,
      'processed_message': message,
      'tools_used': enabledServerIds,
      'results': [
        {'tool': 'filesystem', 'output': 'Listed 5 files'},
        {'tool': 'web_search', 'output': 'Found 10 results'},
      ],
    };
  }

  // Test helper methods
  void setMockConversationContext(String conversationId, Map<String, dynamic> context) {
    conversationContexts[conversationId] = context;
  }

  void clearMockData() {
    processMessageCalled = false;
    conversationContexts.clear();
  }
}

/// Mock MCP Catalogue Entry for testing
class MockMCPCatalogueEntry {
  final String id;
  final String name;
  final String description;
  final String command;
  final String protocol;
  final List<String> capabilities;
  final String? installationCommand;

  MockMCPCatalogueEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.command,
    required this.protocol,
    required this.capabilities,
    this.installationCommand,
  });
}

/// MCP Server Exception for testing
class MCPServerException implements Exception {
  final String message;
  MCPServerException(this.message);
  
  @override
  String toString() => 'MCPServerException: $message';
}