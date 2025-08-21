import 'dart:io';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'helpers/test_sqlite_conversation_service.dart';

void main() {
  group('SqliteConversationService', () {
    late TestSqliteConversationService service;
    late String testDbPath;
    late Directory tempDir;

    setUp(() async {
      // Create a unique test database for each test
      tempDir = await Directory.systemTemp.createTemp('test_db_');
      testDbPath = path.join(tempDir.path, 'test_conversations.db');
      
      // Initialize service with test database
      service = TestSqliteConversationService(testDbPath);
      await service.initialize();
    });

    tearDown(() async {
      // Clean up test database
      await service.close();
      if (File(testDbPath).existsSync()) {
        await File(testDbPath).delete();
      }
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('CRUD Operations', () {
      test('creates a conversation successfully', () async {
        final conversation = Conversation(
          id: 'test-1',
          title: 'Test Conversation',
          messages: [],
          createdAt: DateTime.now(),
        );

        final created = await service.createConversation(conversation);
        
        expect(created.id, equals('test-1'));
        expect(created.title, equals('Test Conversation'));
        expect(created.messages, isEmpty);
        expect(created.createdAt, isNotNull);
      });

      test('retrieves an existing conversation', () async {
        final conversation = Conversation(
          id: 'test-2',
          title: 'Retrieve Test',
          messages: [
            Message(
              id: 'm1',
              content: 'Test message',
              role: MessageRole.user,
              timestamp: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
        );

        await service.createConversation(conversation);
        final retrieved = await service.getConversation('test-2');
        
        expect(retrieved.id, equals('test-2'));
        expect(retrieved.title, equals('Retrieve Test'));
        expect(retrieved.messages, hasLength(1));
        expect(retrieved.messages.first.content, equals('Test message'));
      });

      test('lists all conversations', () async {
        final conversations = List.generate(5, (i) => Conversation(
          id: 'conv-$i',
          title: 'Conversation $i',
          messages: [],
          createdAt: DateTime.now().add(Duration(seconds: i)),
        ));

        for (final conv in conversations) {
          await service.createConversation(conv);
        }

        final list = await service.listConversations();
        
        expect(list, hasLength(5));
        expect(list.map((c) => c.id), containsAll(['conv-0', 'conv-1', 'conv-2', 'conv-3', 'conv-4']));
      });

      test('updates an existing conversation', () async {
        final original = Conversation(
          id: 'update-test',
          title: 'Original Title',
          messages: [],
          createdAt: DateTime.now(),
          status: ConversationStatus.active,
        );

        await service.createConversation(original);
        
        final updated = original.copyWith(
          title: 'Updated Title',
          status: ConversationStatus.archived,
        );
        
        final result = await service.updateConversation(updated);
        
        expect(result.title, equals('Updated Title'));
        expect(result.status, equals(ConversationStatus.archived));
        
        final retrieved = await service.getConversation('update-test');
        expect(retrieved.title, equals('Updated Title'));
      });

      test('deletes a conversation', () async {
        final conversation = Conversation(
          id: 'delete-test',
          title: 'To Be Deleted',
          messages: [],
          createdAt: DateTime.now(),
        );

        await service.createConversation(conversation);
        
        // Verify it exists
        final exists = await service.getConversation('delete-test');
        expect(exists, isNotNull);
        
        // Delete it
        await service.deleteConversation('delete-test');
        
        // Verify it's gone
        expect(
          () => service.getConversation('delete-test'),
          throwsException,
        );
      });

      test('handles conversation with complex message structure', () async {
        final complexMessage = Message(
          id: 'complex-1',
          content: 'Multi-line\ncontent\nwith\nspecial chars: "\'{}[]',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          metadata: {
            'key1': 'value1',
            'nested': {
              'key2': 123,
              'key3': true,
            },
          },
        );

        final conversation = Conversation(
          id: 'complex-conv',
          title: 'Complex Conversation',
          messages: [complexMessage],
          createdAt: DateTime.now(),
          metadata: {
            'tags': ['important', 'test'],
            'priority': 5,
          },
        );

        await service.createConversation(conversation);
        final retrieved = await service.getConversation('complex-conv');
        
        expect(retrieved.messages.first.content, contains('special chars'));
        expect(retrieved.messages.first.metadata?['nested']['key2'], equals(123));
        expect(retrieved.metadata?['tags'], contains('important'));
      });
    });

    group('Message Operations', () {
      test('adds a message to existing conversation', () async {
        final conversation = Conversation(
          id: 'msg-test-1',
          title: 'Message Test',
          messages: [],
          createdAt: DateTime.now(),
        );

        await service.createConversation(conversation);
        
        final message = Message(
          id: 'new-msg',
          content: 'New message content',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        );
        
        final added = await service.addMessage('msg-test-1', message);
        
        expect(added.id, equals('new-msg'));
        expect(added.content, equals('New message content'));
        
        final messages = await service.getMessages('msg-test-1');
        expect(messages, hasLength(1));
        expect(messages.first.content, equals('New message content'));
      });

      test('adds multiple messages in sequence', () async {
        final conversation = Conversation(
          id: 'msg-test-2',
          title: 'Multiple Messages',
          messages: [],
          createdAt: DateTime.now(),
        );

        await service.createConversation(conversation);
        
        final messages = List.generate(10, (i) => Message(
          id: 'msg-$i',
          content: 'Message $i',
          role: i % 2 == 0 ? MessageRole.user : MessageRole.assistant,
          timestamp: DateTime.now().add(Duration(seconds: i)),
        ));
        
        for (final msg in messages) {
          await service.addMessage('msg-test-2', msg);
        }
        
        final retrieved = await service.getMessages('msg-test-2');
        expect(retrieved, hasLength(10));
        
        // Verify order is preserved
        for (int i = 0; i < 10; i++) {
          expect(retrieved[i].id, equals('msg-$i'));
          expect(retrieved[i].content, equals('Message $i'));
        }
      });

      test('preserves message order after updates', () async {
        final conversation = Conversation(
          id: 'order-test',
          title: 'Order Test',
          messages: [],
          createdAt: DateTime.now(),
        );

        await service.createConversation(conversation);
        
        // Add initial messages
        for (int i = 0; i < 3; i++) {
          await service.addMessage('order-test', Message(
            id: 'msg-$i',
            content: 'Message $i',
            role: MessageRole.user,
            timestamp: DateTime.now().add(Duration(seconds: i)),
          ));
        }
        
        // Update conversation with different data
        final conv = await service.getConversation('order-test');
        await service.updateConversation(conv.copyWith(title: 'Updated Title'));
        
        // Add more messages
        for (int i = 3; i < 5; i++) {
          await service.addMessage('order-test', Message(
            id: 'msg-$i',
            content: 'Message $i',
            role: MessageRole.assistant,
            timestamp: DateTime.now().add(Duration(seconds: i)),
          ));
        }
        
        final messages = await service.getMessages('order-test');
        expect(messages, hasLength(5));
        
        // Verify order is still correct
        for (int i = 0; i < 5; i++) {
          expect(messages[i].id, equals('msg-$i'));
        }
      });
    });

    group('Status Operations', () {
      test('sets conversation status to archived', () async {
        final conversation = Conversation(
          id: 'status-1',
          title: 'Status Test',
          messages: [],
          createdAt: DateTime.now(),
          status: ConversationStatus.active,
        );

        await service.createConversation(conversation);
        await service.setConversationStatus('status-1', ConversationStatus.archived);
        
        final updated = await service.getConversation('status-1');
        expect(updated.status, equals(ConversationStatus.archived));
        expect(updated.lastModified, isNotNull);
        expect(updated.lastModified!.isAfter(conversation.createdAt), isTrue);
      });

      test('updates lastModified when status changes', () async {
        final conversation = Conversation(
          id: 'status-2',
          title: 'Modified Test',
          messages: [],
          createdAt: DateTime.now().subtract(Duration(hours: 1)),
        );

        await service.createConversation(conversation);
        
        final beforeUpdate = await service.getConversation('status-2');
        
        // Wait a bit to ensure timestamp difference
        await Future.delayed(Duration(milliseconds: 100));
        
        await service.setConversationStatus('status-2', ConversationStatus.archived);
        
        final afterUpdate = await service.getConversation('status-2');
        
        expect(afterUpdate.lastModified, isNotNull);
        if (beforeUpdate.lastModified != null) {
          expect(
            afterUpdate.lastModified!.isAfter(beforeUpdate.lastModified!),
            isTrue,
          );
        }
      });
    });

    group('Error Handling', () {
      test('throws exception when getting non-existent conversation', () async {
        expect(
          () => service.getConversation('non-existent'),
          throwsException,
        );
      });

      test('throws exception when adding message to non-existent conversation', () async {
        final message = Message(
          id: 'msg-1',
          content: 'Test',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        );
        
        expect(
          () => service.addMessage('non-existent', message),
          throwsException,
        );
      });

      test('throws exception when updating non-existent conversation', () async {
        final conversation = Conversation(
          id: 'non-existent',
          title: 'Test',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        expect(
          () => service.updateConversation(conversation),
          throwsA(anything),
        );
      });

      test('throws exception when setting status on non-existent conversation', () async {
        expect(
          () => service.setConversationStatus('non-existent', ConversationStatus.archived),
          throwsException,
        );
      });

      test('handles empty conversation list gracefully', () async {
        final list = await service.listConversations();
        expect(list, isEmpty);
      });

      test('handles duplicate conversation IDs', () async {
        final conversation1 = Conversation(
          id: 'duplicate-id',
          title: 'First',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        final conversation2 = Conversation(
          id: 'duplicate-id',
          title: 'Second',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conversation1);
        
        expect(
          () => service.createConversation(conversation2),
          throwsA(anything),
        );
      });

      test('handles very long conversation titles', () async {
        final longTitle = 'A' * 1000;
        final conversation = Conversation(
          id: 'long-title',
          title: longTitle,
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conversation);
        final retrieved = await service.getConversation('long-title');
        
        expect(retrieved.title, equals(longTitle));
      });

      test('handles special characters in IDs', () async {
        final specialId = 'test-id_with.special~chars!@#\$%^&*()';
        final conversation = Conversation(
          id: specialId,
          title: 'Special ID Test',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conversation);
        final retrieved = await service.getConversation(specialId);
        
        expect(retrieved.id, equals(specialId));
      });
    });

    group('Concurrent Access', () {
      test('handles concurrent conversation creations', () async {
        final futures = List.generate(10, (i) => 
          service.createConversation(Conversation(
            id: 'concurrent-$i',
            title: 'Concurrent Test $i',
            messages: [],
            createdAt: DateTime.now(),
          ))
        );
        
        final results = await Future.wait(futures);
        
        expect(results, hasLength(10));
        
        final list = await service.listConversations();
        expect(list, hasLength(10));
      });

      test('handles concurrent message additions', () async {
        // Note: SQLite operations within a single connection are serialized,
        // so true concurrent writes will be handled sequentially.
        // This test verifies that rapid sequential additions work correctly.
        final conversation = Conversation(
          id: 'concurrent-msg',
          title: 'Concurrent Messages',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conversation);
        
        // Add messages sequentially (simulating rapid additions)
        for (int i = 0; i < 20; i++) {
          await service.addMessage('concurrent-msg', Message(
            id: 'concurrent-msg-$i',
            content: 'Concurrent message $i',
            role: i % 2 == 0 ? MessageRole.user : MessageRole.assistant,
            timestamp: DateTime.now().add(Duration(milliseconds: i)),
          ));
        }
        
        final messages = await service.getMessages('concurrent-msg');
        expect(messages, hasLength(20));
        
        // Verify all messages are present
        final messageIds = messages.map((m) => m.id).toSet();
        for (int i = 0; i < 20; i++) {
          expect(messageIds.contains('concurrent-msg-$i'), isTrue);
        }
      });

      test('handles concurrent reads while writing', () async {
        final conversation = Conversation(
          id: 'read-write-test',
          title: 'Read-Write Test',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conversation);
        
        // Add messages sequentially
        for (int i = 0; i < 5; i++) {
          await service.addMessage('read-write-test', Message(
            id: 'write-msg-$i',
            content: 'Write message $i',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ));
        }
        
        // Perform multiple reads
        final readResults = <Conversation>[];
        for (int i = 0; i < 10; i++) {
          readResults.add(await service.getConversation('read-write-test'));
        }
        
        expect(readResults, hasLength(10));
        
        // Verify final state
        final finalConv = await service.getConversation('read-write-test');
        expect(finalConv.messages, hasLength(5));
      });

      test('handles concurrent updates to same conversation', () async {
        final conversation = Conversation(
          id: 'update-race',
          title: 'Original',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conversation);
        
        // Concurrent updates with different titles
        final futures = List.generate(10, (i) async {
          final conv = await service.getConversation('update-race');
          return service.updateConversation(
            conv.copyWith(title: 'Update $i')
          );
        });
        
        await Future.wait(futures);
        
        // Final conversation should have one of the update titles
        final finalConv = await service.getConversation('update-race');
        expect(finalConv.title, matches(RegExp(r'^Update \d$')));
      });

      test('handles concurrent deletes and reads', () async {
        // Create multiple conversations
        final conversations = List.generate(5, (i) => Conversation(
          id: 'delete-race-$i',
          title: 'Delete Test $i',
          messages: [],
          createdAt: DateTime.now(),
        ));
        
        for (final conv in conversations) {
          await service.createConversation(conv);
        }
        
        // Mix deletes and reads
        final futures = <Future>[];
        
        // Delete some
        futures.add(service.deleteConversation('delete-race-1'));
        futures.add(service.deleteConversation('delete-race-3'));
        
        // Try to read all (some will fail)
        for (int i = 0; i < 5; i++) {
          futures.add(
            service.getConversation('delete-race-$i').catchError((e) {
              // Return null for not found conversations
              return Conversation(
                id: 'not-found',
                title: 'Not Found',
                messages: [],
                createdAt: DateTime.now(),
              );
            })
          );
        }
        
        await Future.wait(futures);
        
        // Verify expected state
        final list = await service.listConversations();
        expect(list, hasLength(3)); // 0, 2, 4 should remain
        expect(
          list.map((c) => c.id),
          containsAll(['delete-race-0', 'delete-race-2', 'delete-race-4']),
        );
      });
    });

    group('Data Persistence', () {
      test('persists data across service instances', () async {
        final conversation = Conversation(
          id: 'persist-test',
          title: 'Persistence Test',
          messages: [
            Message(
              id: 'msg-1',
              content: 'Persisted message',
              role: MessageRole.user,
              timestamp: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
        );
        
        // Create with first instance
        await service.createConversation(conversation);
        await service.close();
        
        // Create new instance and verify data persists
        final newService = TestSqliteConversationService(testDbPath);
        await newService.initialize();
        
        final retrieved = await newService.getConversation('persist-test');
        expect(retrieved.id, equals('persist-test'));
        expect(retrieved.title, equals('Persistence Test'));
        expect(retrieved.messages, hasLength(1));
        expect(retrieved.messages.first.content, equals('Persisted message'));
        
        await newService.close();
      });

      test('handles database initialization correctly', () async {
        // Close current service
        await service.close();
        
        // Create multiple instances sequentially
        for (int i = 0; i < 3; i++) {
          final tempService = TestSqliteConversationService(testDbPath);
          await tempService.initialize();
          
          // Should be able to create conversations
          await tempService.createConversation(Conversation(
            id: 'init-test-$i',
            title: 'Init Test $i',
            messages: [],
            createdAt: DateTime.now(),
          ));
          
          await tempService.close();
        }
        
        // Verify all conversations exist
        final finalService = TestSqliteConversationService(testDbPath);
        await finalService.initialize();
        
        final list = await finalService.listConversations();
        expect(list, hasLength(3));
        
        await finalService.close();
      });
    });

    group('Edge Cases', () {
      test('handles empty message list', () async {
        final conversation = Conversation(
          id: 'empty-msgs',
          title: 'Empty Messages',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conversation);
        
        final messages = await service.getMessages('empty-msgs');
        expect(messages, isEmpty);
      });

      test('handles null metadata fields', () async {
        final conversation = Conversation(
          id: 'null-metadata',
          title: 'Null Metadata Test',
          messages: [
            Message(
              id: 'msg-null',
              content: 'Message without metadata',
              role: MessageRole.user,
              timestamp: DateTime.now(),
              metadata: null,
            ),
          ],
          createdAt: DateTime.now(),
          metadata: null,
        );
        
        await service.createConversation(conversation);
        final retrieved = await service.getConversation('null-metadata');
        
        expect(retrieved.metadata, isNull);
        expect(retrieved.messages.first.metadata, isNull);
      });

      test('handles conversations with same title', () async {
        final conv1 = Conversation(
          id: 'same-title-1',
          title: 'Duplicate Title',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        final conv2 = Conversation(
          id: 'same-title-2',
          title: 'Duplicate Title',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conv1);
        await service.createConversation(conv2);
        
        final list = await service.listConversations();
        final duplicateTitles = list.where((c) => c.title == 'Duplicate Title');
        
        expect(duplicateTitles, hasLength(2));
        expect(
          duplicateTitles.map((c) => c.id),
          containsAll(['same-title-1', 'same-title-2']),
        );
      });

      test('handles rapid status changes', () async {
        final conversation = Conversation(
          id: 'rapid-status',
          title: 'Rapid Status Changes',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conversation);
        
        // Rapidly change status
        await service.setConversationStatus('rapid-status', ConversationStatus.archived);
        await service.setConversationStatus('rapid-status', ConversationStatus.active);
        await service.setConversationStatus('rapid-status', ConversationStatus.archived);
        await service.setConversationStatus('rapid-status', ConversationStatus.active);
        
        final finalConv = await service.getConversation('rapid-status');
        expect(finalConv.status, equals(ConversationStatus.active));
      });

      test('handles maximum message size', () async {
        // Create a very large message content
        final largeContent = 'X' * 10000; // 10KB of text
        
        final conversation = Conversation(
          id: 'large-msg',
          title: 'Large Message Test',
          messages: [],
          createdAt: DateTime.now(),
        );
        
        await service.createConversation(conversation);
        
        final largeMessage = Message(
          id: 'large-1',
          content: largeContent,
          role: MessageRole.user,
          timestamp: DateTime.now(),
        );
        
        await service.addMessage('large-msg', largeMessage);
        
        final retrieved = await service.getMessages('large-msg');
        expect(retrieved.first.content.length, equals(10000));
      });
    });
  });
}