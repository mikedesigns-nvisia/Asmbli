import '../agent_service.dart';
import '../conversation_service.dart';
import 'memory_agent_service.dart';
import 'memory_conversation_service.dart';

/// A service provider that creates and manages service instances.
/// This allows us to easily switch between different implementations
/// (e.g., memory, API, local storage) based on the platform or needs.
class ServiceProvider {
  static AgentService? _agentService;
  static ConversationService? _conversationService;

  /// Gets the current AgentService instance.
  /// Creates a new instance if one doesn't exist.
  static AgentService getAgentService() {
    _agentService ??= InMemoryAgentService();
    return _agentService!;
  }

  /// Gets the current ConversationService instance.
  /// Creates a new instance if one doesn't exist.
  static ConversationService getConversationService() {
    _conversationService ??= InMemoryConversationService();
    return _conversationService!;
  }

  /// Resets all services, primarily used for testing.
  static void reset() {
    _agentService = null;
    _conversationService = null;
  }
}
