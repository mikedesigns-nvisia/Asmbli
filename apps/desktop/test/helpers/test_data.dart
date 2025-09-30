import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:uuid/uuid.dart';

/// Factory class for creating test data
class TestData {
  static const _uuid = Uuid();

  /// Create a test agent with default or custom values
  static Agent createAgent({
    String? id,
    String name = 'Test Agent',
    String description = 'You are a helpful assistant',
    List<String> capabilities = const [],
    Map<String, dynamic>? configuration,
    AgentStatus status = AgentStatus.idle,
  }) {
    return Agent(
      id: id ?? _uuid.v4(),
      name: name,
      description: description,
      capabilities: capabilities,
      configuration: configuration ?? {
        'model': 'claude-3-sonnet',
        'temperature': 0.7,
        'maxTokens': 1000,
      },
      status: status,
    );
  }

  /// Create a test conversation with default or custom values
  static Conversation createConversation({
    String? id,
    String title = 'Test Conversation',
    List<Message> messages = const [],
    ConversationStatus status = ConversationStatus.active,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? _uuid.v4(),
      title: title,
      messages: messages,
      createdAt: DateTime.now(),
      status: status,
      metadata: metadata,
    );
  }

  /// Create a test message with default or custom values
  static Message createMessage({
    String? id,
    String content = 'Hello, world!',
    MessageRole role = MessageRole.user,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? _uuid.v4(),
      content: content,
      role: role,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create a batch of test agents
  static List<Agent> createAgents(int count) {
    return List.generate(
      count,
      (index) => createAgent(
        name: 'Agent ${index + 1}',
        description: 'Test agent number ${index + 1}',
      ),
    );
  }

  /// Create a batch of test conversations
  static List<Conversation> createConversations(int count) {
    return List.generate(
      count,
      (index) => createConversation(
        title: 'Conversation ${index + 1}',
      ),
    );
  }

  /// Create a batch of test messages
  static List<Message> createMessages(int count) {
    return List.generate(
      count,
      (index) => createMessage(
        content: 'Message ${index + 1}',
        role: index.isEven ? MessageRole.user : MessageRole.assistant,
      ),
    );
  }
}