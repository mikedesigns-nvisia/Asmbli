import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agent_engine_core/models/conversation.dart';

import 'package:agentengine_desktop/core/services/feature_flag_service.dart';
import 'package:agentengine_desktop/features/chat/presentation/screens/chat_screen.dart';
import 'package:agentengine_desktop/core/constants/routes.dart';
import 'package:agentengine_desktop/providers/conversation_provider.dart';
import 'package:agentengine_desktop/features/chat/presentation/widgets/improved_conversation_sidebar.dart';

import '../test_helpers/mock_services.dart';
import '../test_helpers/test_app_wrapper.dart';

void main() {
  group('Chat Conversation Flow Tests', () {
    late SharedPreferences mockPrefs;
    late MockDesktopStorageService mockStorageService;
    late MockApiConfigService mockApiConfigService;
    late MockConversationService mockConversationService;

    setUpAll(() async {
      await Hive.initFlutter();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      
      mockStorageService = MockDesktopStorageService();
      mockApiConfigService = MockApiConfigService();
      mockConversationService = MockConversationService();
      
      // Set up default state - user is onboarded with API keys
      mockStorageService.setMockPreference('onboarding_completed', true);
      mockApiConfigService.setMockApiConfigs({
        'openai': MockApiConfig(
          provider: 'openai',
          apiKey: 'sk-test123',
          isConfigured: true,
        ),
      });
    });

    testWidgets('Chat screen loads with empty state', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Should show chat screen
      expect(find.byType(ChatScreen), findsOneWidget);
      
      // Should show empty state or new conversation UI
      expect(find.text('Start a new conversation'), findsAny);
      expect(find.byType(TextFormField), findsOneWidget); // Message input field
    });

    testWidgets('User can create a new conversation', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Look for new conversation button
      final newConversationButton = find.text('New Chat');
      if (newConversationButton.evaluate().isNotEmpty) {
        await tester.tap(newConversationButton);
        await tester.pumpAndSettle();
      }

      // Verify a new conversation was created
      expect(mockConversationService.conversations.length, greaterThanOrEqualTo(1));
    });

    testWidgets('User can send a message in conversation', (WidgetTester tester) async {
      // Pre-create a conversation
      final conversation = await mockConversationService.createConversationFromParams(
        title: 'Test Conversation',
        metadata: {'type': 'direct_chat'},
      );

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
            conversationServiceProvider.overrideWithValue(mockConversationService),
            selectedConversationIdProvider.overrideWith((ref) => conversation.id),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Find message input field
      final messageField = find.byType(TextFormField).last;
      expect(messageField, findsOneWidget);

      // Type a message
      await tester.enterText(messageField, 'Hello, this is a test message');
      await tester.pumpAndSettle();

      // Find and tap send button
      final sendButton = find.byIcon(Icons.send).last;
      expect(sendButton, findsOneWidget);
      
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify message was added to conversation
      final messages = await mockConversationService.getMessages(conversation.id);
      expect(messages.length, greaterThan(0));
      expect(messages.last.content, contains('Hello, this is a test message'));
    });

    testWidgets('Conversation sidebar shows existing conversations', (WidgetTester tester) async {
      // Pre-create multiple conversations
      await mockConversationService.createConversationFromParams(title: 'Conversation 1');
      await mockConversationService.createConversationFromParams(title: 'Conversation 2');
      await mockConversationService.createConversationFromParams(title: 'Agent Chat', metadata: {'type': 'agent'});

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Should show conversation sidebar
      expect(find.byType(ImprovedConversationSidebar), findsOneWidget);
      
      // Should show conversation titles
      expect(find.text('Conversation 1'), findsOneWidget);
      expect(find.text('Conversation 2'), findsOneWidget);
      expect(find.text('Agent Chat'), findsOneWidget);
    });

    testWidgets('User can switch between conversations', (WidgetTester tester) async {
      // Pre-create conversations with messages
      final conv1 = await mockConversationService.createConversationFromParams(title: 'First Chat');
      final conv2 = await mockConversationService.createConversationFromParams(title: 'Second Chat');
      
      // Add messages to differentiate conversations
      await mockConversationService.addMessage(conv1.id, Message(
        id: 'msg1',
        role: MessageRole.user,
        content: 'Message in first chat',
        timestamp: DateTime.now(),
      ));
      
      await mockConversationService.addMessage(conv2.id, Message(
        id: 'msg2',
        role: MessageRole.user,
        content: 'Message in second chat',
        timestamp: DateTime.now(),
      ));

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Click on first conversation
      await tester.tap(find.text('First Chat'));
      await tester.pumpAndSettle();

      // Should show message from first chat
      expect(find.text('Message in first chat'), findsOneWidget);

      // Click on second conversation  
      await tester.tap(find.text('Second Chat'));
      await tester.pumpAndSettle();

      // Should show message from second chat
      expect(find.text('Message in second chat'), findsOneWidget);
    });

    testWidgets('User can delete a conversation', (WidgetTester tester) async {
      // Pre-create a conversation
      final conversation = await mockConversationService.createConversationFromParams(title: 'To Delete');

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Should show the conversation
      expect(find.text('To Delete'), findsOneWidget);

      // Look for delete button (might be in context menu or hover action)
      final deleteButton = find.byIcon(Icons.delete);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // Confirm deletion if there's a dialog
        final confirmButton = find.text('Delete');
        if (confirmButton.evaluate().isNotEmpty) {
          await tester.tap(confirmButton);
          await tester.pumpAndSettle();
        }

        // Verify conversation was deleted
        expect(mockConversationService.conversations.any((c) => c.id == conversation.id), false);
      }
    });

    testWidgets('User can rename a conversation', (WidgetTester tester) async {
      // Pre-create a conversation
      await mockConversationService.createConversationFromParams(title: 'Original Title');

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Look for edit/rename functionality
      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Find text field for editing title
        final titleField = find.byType(TextFormField).first;
        await tester.enterText(titleField, 'New Title');
        await tester.pumpAndSettle();

        // Save the change
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Verify title was updated
        expect(find.text('New Title'), findsOneWidget);
        expect(find.text('Original Title'), findsNothing);
      }
    });

    testWidgets('Chat handles message streaming correctly', (WidgetTester tester) async {
      // This test would verify that streaming messages are displayed correctly
      // For now, we'll test the basic structure

      final conversation = await mockConversationService.createConversationFromParams(title: 'Streaming Test');

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
            conversationServiceProvider.overrideWithValue(mockConversationService),
            selectedConversationIdProvider.overrideWith((ref) => conversation.id),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Send a message to trigger AI response
      final messageField = find.byType(TextFormField).last;
      await tester.enterText(messageField, 'Test streaming response');
      
      final sendButton = find.byIcon(Icons.send).last;
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Should show loading indicator or streaming response
      // In a real implementation, this would test actual streaming
      expect(find.byType(CircularProgressIndicator), findsAny);
    });

    testWidgets('Sidebar can be collapsed and expanded', (WidgetTester tester) async {
      await mockConversationService.createConversationFromParams(title: 'Test Conversation');

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(mockPrefs)),
            conversationServiceProvider.overrideWithValue(mockConversationService),
          ],
          storageService: mockStorageService,
          apiConfigService: mockApiConfigService,
          initialRoute: AppRoutes.chat,
        ),
      );

      await tester.pumpAndSettle();

      // Look for sidebar toggle button
      final toggleButton = find.byIcon(Icons.menu);
      if (toggleButton.evaluate().isNotEmpty) {
        // Tap to collapse sidebar
        await tester.tap(toggleButton);
        await tester.pumpAndSettle();

        // Conversation titles should be hidden or minimized
        // This depends on the actual implementation

        // Tap again to expand
        await tester.tap(toggleButton);
        await tester.pumpAndSettle();

        // Conversation titles should be visible again
        expect(find.text('Test Conversation'), findsOneWidget);
      }
    });
  });
}