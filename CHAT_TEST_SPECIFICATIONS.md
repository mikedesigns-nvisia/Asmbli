# Chat Functionality Test Specifications

## Overview
This document provides detailed test specifications for chat functionality integration testing. These tests ensure that all chat-related services, state management, and UI components work together correctly.

## Chat Service Integration Tests

### Test File: `test/integration/chat_services_integration_test.dart`

#### Test Group: Conversation Service Integration
```dart
group('ConversationService Integration', () {
  test('conversation service connects to real storage', () async {
    final service = DesktopConversationService();
    await service.initialize();
    
    // Test conversation CRUD operations
    final conversation = await service.createConversation(
      title: 'Test Conversation',
      agentId: 'test-agent',
    );
    
    expect(conversation.id, isNotNull);
    expect(conversation.title, equals('Test Conversation'));
    
    // Verify persistence
    final retrieved = await service.getConversation(conversation.id);
    expect(retrieved.title, equals(conversation.title));
  });

  test('message service persists and retrieves correctly', () async {
    final service = DesktopConversationService();
    final conversationId = 'test-conv-123';
    
    // Send a message
    final message = await service.sendMessage(
      conversationId: conversationId,
      content: 'Hello, world!',
      role: MessageRole.user,
    );
    
    expect(message.content, equals('Hello, world!'));
    expect(message.role, equals(MessageRole.user));
    
    // Retrieve messages
    final messages = await service.getMessages(conversationId);
    expect(messages, contains(message));
  });
});
```

#### Test Group: LLM Service Integration
```dart
group('UnifiedLLMService Integration', () {
  test('LLM service routes to correct provider', () async {
    final modelConfigService = MockModelConfigService();
    final claudeService = MockClaudeApiService();
    final ollamaService = MockOllamaService();
    
    final llmService = UnifiedLLMService(
      modelConfigService,
      claudeService,
      ollamaService,
    );
    
    await llmService.initialize();
    
    // Test API provider routing
    final apiResponse = await llmService.sendMessage(
      modelId: 'claude-3-sonnet',
      messages: [Message(content: 'Test', role: MessageRole.user)],
    );
    
    expect(apiResponse, isNotNull);
    verify(() => claudeService.sendMessage(any())).called(1);
  });

  test('LLM service handles streaming correctly', () async {
    final llmService = UnifiedLLMService(/*...*/);
    
    final stream = llmService.sendStreamingMessage(
      modelId: 'claude-3-sonnet',
      messages: [Message(content: 'Stream test', role: MessageRole.user)],
    );
    
    final responses = await stream.take(3).toList();
    expect(responses.length, equals(3));
    expect(responses.every((r) => r.content.isNotEmpty), isTrue);
  });
});
```

#### Test Group: MCP Bridge Integration
```dart
group('MCPBridgeService Integration', () {
  test('MCP bridge initializes with real servers', () async {
    final settingsService = MCPSettingsService();
    final healthService = IntegrationHealthMonitoringService();
    
    final bridgeService = MCPBridgeService(settingsService, healthService);
    
    // Should initialize without errors
    await expectLater(
      () => bridgeService.initialize(),
      returnsNormally,
    );
    
    expect(bridgeService.isInitialized, isTrue);
  });

  test('MCP bridge processes messages with tools', () async {
    final bridgeService = MCPBridgeService(/*...*/);
    await bridgeService.initialize();
    
    final response = await bridgeService.processMessage(
      'List files in the current directory',
      conversationId: 'test-conv',
      availableTools: ['filesystem'],
    );
    
    expect(response.content, isNotEmpty);
    expect(response.toolCalls, isNotEmpty);
  });
});
```

## Chat Flow Integration Tests

### Test File: `test/integration/chat_flow_integration_test.dart`

#### Test Group: Complete Message Flow
```dart
group('Complete Message Flow', () {
  testWidgets('end-to-end message sending flow', (tester) async {
    // Set up providers with real services
    final container = ProviderContainer(overrides: [
      conversationServiceProvider.overrideWithValue(DesktopConversationService()),
      // ... other real service overrides
    ]);
    
    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );
    
    // Wait for initialization
    await tester.pumpAndSettle();
    
    // Find message input and enter text
    final messageInput = find.byType(TextField);
    await tester.enterText(messageInput, 'Test message');
    
    // Find and tap send button
    final sendButton = find.byIcon(Icons.send);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();
    
    // Verify message appears in UI
    expect(find.text('Test message'), findsOneWidget);
    
    // Verify message was persisted (check via provider)
    final conversationState = container.read(activeConversationProvider);
    final messages = await container.read(
      messagesProvider(conversationState!.id).future
    );
    
    expect(messages.any((m) => m.content == 'Test message'), isTrue);
  });

  test('message flow with MCP tool usage', () async {
    final conversationService = DesktopConversationService();
    final mcpBridge = MCPBridgeService(/*...*/);
    final llmService = UnifiedLLMService(/*...*/);
    
    // Initialize services
    await Future.wait([
      conversationService.initialize(),
      mcpBridge.initialize(),
      llmService.initialize(),
    ]);
    
    // Create conversation
    final conversation = await conversationService.createConversation(
      title: 'Tool Test',
      agentId: 'test-agent',
    );
    
    // Send message that should trigger tool use
    final userMessage = await conversationService.sendMessage(
      conversationId: conversation.id,
      content: 'List files in /tmp directory',
      role: MessageRole.user,
    );
    
    // Process with LLM (should detect need for file system tool)
    final llmResponse = await llmService.sendMessage(
      modelId: 'claude-3-sonnet',
      messages: [userMessage],
      availableTools: ['filesystem'],
    );
    
    // Verify tool was used
    expect(llmResponse.toolCalls, isNotEmpty);
    expect(llmResponse.toolCalls.first.toolName, equals('list_files'));
    
    // Process tool calls through MCP bridge
    final toolResults = <ToolResult>[];
    for (final toolCall in llmResponse.toolCalls) {
      final result = await mcpBridge.executeTool(
        toolCall.toolName,
        toolCall.parameters,
      );
      toolResults.add(result);
    }
    
    // Verify tool results
    expect(toolResults, isNotEmpty);
    expect(toolResults.first.content, contains('/tmp'));
  });
});
```

## Chat State Management Tests

### Test File: `test/integration/chat_state_integration_test.dart`

#### Test Group: Provider Integration
```dart
group('Chat Provider Integration', () {
  test('conversationProvider connects to real service', () async {
    final container = ProviderContainer(overrides: [
      conversationServiceProvider.overrideWithValue(DesktopConversationService()),
    ]);
    
    // Read conversations (should trigger service call)
    final conversations = await container.read(conversationsProvider.future);
    
    expect(conversations, isA<List<Conversation>>());
    
    // Verify service was called
    final service = container.read(conversationServiceProvider);
    verify(() => service.listConversations()).called(1);
  });

  test('messagesProvider streams real data', () async {
    final container = ProviderContainer();
    const conversationId = 'test-conv-123';
    
    // Set up test data
    final service = container.read(conversationServiceProvider);
    when(() => service.getMessages(conversationId))
        .thenAnswer((_) async => [
          Message(
            id: 'msg-1',
            conversationId: conversationId,
            content: 'Test message',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
        ]);
    
    // Read messages
    final messages = await container.read(
      messagesProvider(conversationId).future
    );
    
    expect(messages.length, equals(1));
    expect(messages.first.content, equals('Test message'));
  });

  test('conversation business service integration', () async {
    final container = ProviderContainer();
    final businessService = container.read(conversationBusinessServiceProvider);
    
    // Test business logic method
    final result = await businessService.createConversationWithAgent(
      agentId: 'test-agent',
      initialMessage: 'Hello',
    );
    
    expect(result.conversation, isNotNull);
    expect(result.initialMessage, isNotNull);
    expect(result.initialMessage.content, equals('Hello'));
  });
});
```

## Chat UI Integration Tests

### Test File: `test/integration/chat_ui_integration_test.dart`

#### Test Group: Chat Screen Integration
```dart
group('ChatScreen Integration', () {
  testWidgets('chat screen loads with real data', (tester) async {
    final container = ProviderContainer(overrides: [
      conversationServiceProvider.overrideWithValue(MockConversationService()),
      // Set up mock to return test conversations
    ]);
    
    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify UI elements loaded
    expect(find.byType(ConversationSidebar), findsOneWidget);
    expect(find.byType(MessageDisplayArea), findsOneWidget);
    expect(find.byType(ConversationInput), findsOneWidget);
  });

  testWidgets('message input triggers real service calls', (tester) async {
    final mockService = MockConversationService();
    final container = ProviderContainer(overrides: [
      conversationServiceProvider.overrideWithValue(mockService),
    ]);
    
    when(() => mockService.sendMessage(
      conversationId: any(named: 'conversationId'),
      content: any(named: 'content'),
      role: any(named: 'role'),
    )).thenAnswer((_) async => Message(
      id: 'test-msg',
      conversationId: 'test-conv',
      content: 'Test response',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    ));
    
    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );
    
    // Enter message
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    
    // Verify service was called
    verify(() => mockService.sendMessage(
      conversationId: any(named: 'conversationId'),
      content: 'Hello',
      role: MessageRole.user,
    )).called(1);
  });
});
```

## Streaming and Real-time Tests

### Test Group: Streaming Message Integration
```dart
group('Streaming Message Integration', () {
  test('streaming messages update UI correctly', () async {
    final streamController = StreamController<String>();
    final mockLLMService = MockUnifiedLLMService();
    
    when(() => mockLLMService.sendStreamingMessage(any()))
        .thenAnswer((_) => streamController.stream);
    
    // Set up widget test with streaming
    await tester.pumpWidget(/*... widget setup ...*/);
    
    // Start streaming
    streamController.add('Hello ');
    await tester.pump();
    expect(find.text('Hello '), findsOneWidget);
    
    streamController.add('world!');
    await tester.pump();
    expect(find.text('Hello world!'), findsOneWidget);
    
    streamController.close();
  });

  test('context updates during conversation persist', () async {
    final conversationService = DesktopConversationService();
    const conversationId = 'test-conv';
    
    // Send initial message
    await conversationService.sendMessage(
      conversationId: conversationId,
      content: 'My name is John',
      role: MessageRole.user,
    );
    
    // Add context
    await conversationService.addContext(
      conversationId: conversationId,
      context: ConversationContext(
        type: ContextType.userInfo,
        data: {'name': 'John'},
      ),
    );
    
    // Send follow-up message
    await conversationService.sendMessage(
      conversationId: conversationId,
      content: 'What is my name?',
      role: MessageRole.user,
    );
    
    // Verify context persisted
    final context = await conversationService.getConversationContext(conversationId);
    expect(context.any((c) => c.data['name'] == 'John'), isTrue);
  });
});
```

## Performance Tests

### Test Group: Chat Performance
```dart
group('Chat Performance Tests', () {
  test('message sending completes within 3 seconds', () async {
    final service = DesktopConversationService();
    final stopwatch = Stopwatch()..start();
    
    await service.sendMessage(
      conversationId: 'test-conv',
      content: 'Performance test message',
      role: MessageRole.user,
    );
    
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(3000));
  });

  test('conversation loading completes within 2 seconds', () async {
    final service = DesktopConversationService();
    final stopwatch = Stopwatch()..start();
    
    await service.listConversations();
    
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  });

  test('streaming response starts within 100ms', () async {
    final llmService = UnifiedLLMService(/*...*/);
    final stopwatch = Stopwatch()..start();
    
    final stream = llmService.sendStreamingMessage(/*...*/);
    await stream.first;
    
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
  });
});
```

## Error Handling Tests

### Test Group: Chat Error Scenarios
```dart
group('Chat Error Handling', () {
  test('handles conversation service failures gracefully', () async {
    final mockService = MockConversationService();
    when(() => mockService.sendMessage(any()))
        .thenThrow(ConversationServiceException('Service unavailable'));
    
    final container = ProviderContainer(overrides: [
      conversationServiceProvider.overrideWithValue(mockService),
    ]);
    
    // Attempt to send message
    final result = await container.read(
      sendMessageProvider('test-conv', 'Test message').future
    );
    
    expect(result.isError, isTrue);
    expect(result.error, contains('Service unavailable'));
  });

  test('handles MCP bridge failures during chat', () async {
    final mockBridge = MockMCPBridgeService();
    when(() => mockBridge.processMessage(any()))
        .thenThrow(MCPBridgeException('Bridge connection failed'));
    
    // Test that chat continues without MCP features
    final response = await processChatMessage(
      message: 'List files',
      mcpBridge: mockBridge,
    );
    
    expect(response.content, isNotEmpty);
    expect(response.error, contains('Bridge connection failed'));
  });
});
```

## Test Execution Requirements

### Setup Requirements
1. **Real Service Integration**: Use actual service instances where possible
2. **Database Isolation**: Each test gets isolated data storage
3. **Network Mocking**: Mock external API calls (Claude API, OAuth providers)
4. **Time Control**: Use controlled time for timestamp testing

### Performance Monitoring
- Monitor memory usage during streaming tests
- Track response times for all service calls
- Verify no memory leaks in long-running tests
- Test with realistic message volumes

### Success Criteria
- All service integration tests pass
- UI responds correctly to service changes
- Error handling prevents crashes
- Performance requirements are met
- State persistence works correctly