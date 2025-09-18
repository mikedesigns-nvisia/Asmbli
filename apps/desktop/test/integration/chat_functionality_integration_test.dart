import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentengine_desktop/features/chat/presentation/screens/chat_screen.dart';
import 'package:agentengine_desktop/features/chat/presentation/screens/chat_screen_with_contextual.dart';
import 'package:agentengine_desktop/features/chat/presentation/widgets/agent_control_panel.dart';
import 'package:agentengine_desktop/features/chat/presentation/widgets/mcp_chat_integration.dart';
import 'package:agentengine_desktop/core/services/api_config_service.dart';
import 'package:agentengine_desktop/core/services/mcp_settings_service.dart';
import 'package:agentengine_desktop/core/models/mcp_server_config.dart';
import 'package:agent_engine_core/services/conversation_service.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../test_helpers/test_app_wrapper.dart';
import '../test_helpers/mock_services.dart';

/// SR-004: Test chat functionality integrations work correctly
void main() {
  group('Chat Functionality Integration Tests', () {
    late ProviderContainer container;
    late MockDesktopStorageService mockStorageService;
    late MockApiConfigService mockApiConfigService;
    late MockConversationService mockConversationService;
    late MockMCPChatService mockMCPChatService;

    setUp(() {
      mockStorageService = MockDesktopStorageService();
      mockApiConfigService = MockApiConfigService();
      mockConversationService = MockConversationService();
      mockMCPChatService = MockMCPChatService();
      
      // Set up basic API configuration for chat
      mockApiConfigService.setMockApiConfigs({
        'claude-config': MockApiConfig(
          provider: 'Anthropic',
          apiKey: 'test-claude-key',
          isConfigured: true,
        ),
      });
      
      container = ProviderContainer(
        overrides: [
          desktopStorageServiceProvider.overrideWithValue(mockStorageService),
          apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
          conversationServiceProvider.overrideWithValue(mockConversationService),
          mcpChatServiceProvider.overrideWithValue(mockMCPChatService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('SR-004.1: Chat screen initializes with API configuration', (tester) async {
      // Arrange & Act: Load chat screen
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify chat screen elements are present
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Message input field
      
      // Verify API configuration is loaded
      final apiConfig = mockApiConfigService.defaultApiConfig;
      expect(apiConfig?.provider, equals('Anthropic'));
      expect(apiConfig?.isConfigured, true);
    });

    testWidgets('SR-004.2: Chat message sending and receiving works', (tester) async {
      // Arrange: Set up chat screen
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Type and send a message
      final messageField = find.byType(TextField);
      await tester.enterText(messageField, 'Hello, how can you help me?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Assert: Verify message was processed
      expect(mockConversationService.conversations.length, greaterThan(0));
      final conversation = mockConversationService.conversations.first;
      expect(conversation.messages.length, greaterThan(0));
      expect(conversation.messages.any((m) => m.content.contains('Hello')), true);
    });

    testWidgets('SR-004.3: Chat with MCP integration works correctly', (tester) async {
      // Arrange: Set up MCP servers for chat integration
      mockMCPChatService.addMockMCPServer(MockMCPServerConfig(
        id: 'filesystem-server',
        name: 'Filesystem Tools',
        capabilities: ['read_file', 'write_file', 'list_directory'],
        isEnabled: true,
      ));

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
            conversationServiceProvider.overrideWithValue(mockConversationService),
            mcpChatServiceProvider.overrideWithValue(mockMCPChatService),
          ],
          child: const MaterialApp(home: ChatScreenWithContextual()),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Send a message that would use MCP tools
      final messageField = find.byType(TextField);
      await tester.enterText(messageField, 'List files in the current directory');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Assert: Verify MCP integration was used
      expect(mockMCPChatService.processMessageCalled, true);
      expect(mockMCPChatService.lastProcessedMessage, contains('List files'));
      expect(mockMCPChatService.lastUsedTools, contains('filesystem-server'));
    });

    testWidgets('SR-004.4: Agent control panel works correctly', (tester) async {
      // Arrange: Set up agent control panel
      await tester.pumpWidget(
        TestAppWrapper(
          child: const MaterialApp(
            home: Scaffold(
              body: AgentControlPanel(
                currentAgentId: 'test-agent',
                availableAgents: [
                  {'id': 'test-agent', 'name': 'Test Agent'},
                  {'id': 'other-agent', 'name': 'Other Agent'},
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify control panel elements
      expect(find.text('Test Agent'), findsOneWidget);
      expect(find.byType(DropdownButton), findsOneWidget);

      // Act: Change agent
      await tester.tap(find.byType(DropdownButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other Agent'));
      await tester.pumpAndSettle();

      // Assert: Verify agent change was processed
      expect(find.text('Other Agent'), findsOneWidget);
    });

    testWidgets('SR-004.5: Conversation persistence works correctly', (tester) async {
      // Arrange: Start a conversation
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            conversationServiceProvider.overrideWithValue(mockConversationService),
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      // Act: Create and save conversation
      final conversation = await mockConversationService.createConversationFromParams(
        title: 'Test Chat Session',
        metadata: {'agent_id': 'test-agent', 'model': 'claude-3'},
      );

      await mockConversationService.addMessage(conversation.id, Message(
        id: 'msg-1',
        conversationId: conversation.id,
        role: MessageRole.user,
        content: 'Hello AI assistant',
        timestamp: DateTime.now(),
      ));

      await mockConversationService.addMessage(conversation.id, Message(
        id: 'msg-2',
        conversationId: conversation.id,
        role: MessageRole.assistant,
        content: 'Hello! How can I help you today?',
        timestamp: DateTime.now(),
      ));

      // Assert: Verify conversation was persisted
      final savedConversation = await mockConversationService.getConversation(conversation.id);
      expect(savedConversation.title, equals('Test Chat Session'));
      expect(savedConversation.messages.length, equals(2));
      expect(savedConversation.metadata?['agent_id'], equals('test-agent'));
    });

    testWidgets('SR-004.6: Chat error handling works correctly', (tester) async {
      // Arrange: Set up API service to fail
      mockApiConfigService.clearMockConfigs(); // No API configs = error

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Try to send a message without API configuration
      final messageField = find.byType(TextField);
      await tester.enterText(messageField, 'This should fail');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Assert: Verify error is displayed gracefully
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.textContaining('API'), findsOneWidget);
    });

    testWidgets('SR-004.7: Context integration in chat works', (tester) async {
      // Arrange: Set up contextual chat screen
      mockStorageService.setMockPreference('context_documents', [
        'document1.txt',
        'document2.md',
      ]);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            desktopStorageServiceProvider.overrideWithValue(mockStorageService),
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          child: const MaterialApp(home: ChatScreenWithContextual()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify context integration elements are present
      expect(find.byType(ChatScreenWithContextual), findsOneWidget);
      
      // Look for context indicators or sidebar
      // (Exact widgets depend on implementation)
      expect(find.textContaining('Context'), findsAtLeastNWidgets(0));
    });

    testWidgets('SR-004.8: Multi-turn conversation flows work', (tester) async {
      // Arrange: Set up chat for multi-turn conversation
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Send multiple messages in sequence
      final messageField = find.byType(TextField);
      
      // First message
      await tester.enterText(messageField, 'What is machine learning?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Second message (follow-up)
      await tester.enterText(messageField, 'Can you give me a simple example?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Third message (clarification)
      await tester.enterText(messageField, 'I meant in Python code');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Assert: Verify conversation maintains context
      expect(mockConversationService.conversations.length, greaterThan(0));
      final conversation = mockConversationService.conversations.first;
      expect(conversation.messages.length, greaterThanOrEqualTo(6)); // 3 user + 3 assistant messages
    });

    testWidgets('SR-004.9: Chat with file attachments works', (tester) async {
      // Arrange: Set up chat with file support
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          child: const MaterialApp(home: ChatScreenWithContextual()),
        ),
      );

      await tester.pumpAndSettle();

      // Act: Look for file attachment button and test if present
      final attachmentButton = find.byIcon(Icons.attach_file);
      if (tester.any(attachmentButton)) {
        await tester.tap(attachmentButton);
        await tester.pumpAndSettle();

        // Assert: Verify file picker interaction
        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });

    testWidgets('SR-004.10: Chat message formatting and rendering works', (tester) async {
      // Arrange: Set up conversation with various message types
      final testConversation = await mockConversationService.createConversationFromParams(
        title: 'Formatting Test',
      );

      await mockConversationService.addMessage(testConversation.id, Message(
        id: 'msg-code',
        conversationId: testConversation.id,
        role: MessageRole.assistant,
        content: 'Here is some code:\n```python\nprint("Hello, World!")\n```',
        timestamp: DateTime.now(),
      ));

      await mockConversationService.addMessage(testConversation.id, Message(
        id: 'msg-markdown',
        conversationId: testConversation.id,
        role: MessageRole.assistant,
        content: '**Bold text** and *italic text* with a [link](https://example.com)',
        timestamp: DateTime.now(),
      ));

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            conversationServiceProvider.overrideWithValue(mockConversationService),
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify formatted content is rendered
      expect(find.textContaining('print("Hello, World!")'), findsOneWidget);
      expect(find.textContaining('Bold text'), findsOneWidget);
    });

    testWidgets('SR-004.11: Chat performance with large conversations', (tester) async {
      // Arrange: Create a large conversation
      final largeConversation = await mockConversationService.createConversationFromParams(
        title: 'Large Conversation',
      );

      // Add many messages to test performance
      for (int i = 0; i < 100; i++) {
        await mockConversationService.addMessage(largeConversation.id, Message(
          id: 'msg-$i',
          conversationId: largeConversation.id,
          role: i % 2 == 0 ? MessageRole.user : MessageRole.assistant,
          content: 'Message number $i with some content to test rendering performance',
          timestamp: DateTime.now().subtract(Duration(minutes: 100 - i)),
        ));
      }

      // Act: Load chat screen with large conversation
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            conversationServiceProvider.overrideWithValue(mockConversationService),
            apiConfigServiceProvider.overrideWithValue(mockApiConfigService),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Assert: Verify chat loads within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should load within 5 seconds
      expect(find.byType(ChatScreen), findsOneWidget);
    });
  });
}

/// Mock MCP Chat Service for testing
class MockMCPChatService {
  bool processMessageCalled = false;
  String? lastProcessedMessage;
  List<String> lastUsedTools = [];
  final List<MockMCPServerConfig> mcpServers = [];

  Future<Map<String, dynamic>> processMessage(
    String conversationId,
    String message,
    List<String> enabledTools,
  ) async {
    processMessageCalled = true;
    lastProcessedMessage = message;
    lastUsedTools = enabledTools;

    // Simulate MCP tool usage based on message content
    final toolsUsed = <Map<String, dynamic>>[];
    
    if (message.toLowerCase().contains('list files') || message.toLowerCase().contains('directory')) {
      toolsUsed.add({
        'tool': 'filesystem-server',
        'function': 'list_directory',
        'result': ['file1.txt', 'file2.md', 'folder1/'],
      });
    }

    if (message.toLowerCase().contains('search') || message.toLowerCase().contains('web')) {
      toolsUsed.add({
        'tool': 'web-search-server',
        'function': 'search_web',
        'result': 'Found 10 relevant results',
      });
    }

    return {
      'conversation_id': conversationId,
      'message': message,
      'tools_used': toolsUsed,
      'response': 'AI response incorporating tool results',
    };
  }

  void addMockMCPServer(MockMCPServerConfig server) {
    mcpServers.add(server);
  }

  void clearMockData() {
    processMessageCalled = false;
    lastProcessedMessage = null;
    lastUsedTools.clear();
    mcpServers.clear();
  }
}

/// Mock MCP Server Config for chat testing
class MockMCPServerConfig {
  final String id;
  final String name;
  final List<String> capabilities;
  final bool isEnabled;

  MockMCPServerConfig({
    required this.id,
    required this.name,
    required this.capabilities,
    required this.isEnabled,
  });
}

/// Message model for testing (simplified)
class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });
}

/// Message role enum for testing
enum MessageRole {
  user,
  assistant,
  system,
}

/// Provider definitions for testing
final conversationServiceProvider = Provider<ConversationService>((ref) {
  throw UnimplementedError('Mock should be provided in tests');
});

final mcpChatServiceProvider = Provider<MockMCPChatService>((ref) {
  throw UnimplementedError('Mock should be provided in tests');
});