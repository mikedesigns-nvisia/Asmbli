import '../agent_service.dart';
import '../conversation_service.dart';
import 'memory_agent_service.dart';
import 'memory_conversation_service.dart';
import 'sqlite/sqlite_agent_service.dart';
import 'sqlite/sqlite_conversation_service.dart';

/// A service provider that creates and manages service instances.
/// This allows us to easily switch between different implementations
/// (e.g., memory, API, local storage) based on the platform or needs.
class ServiceProvider {
  static AgentService? _agentService;
  static ConversationService? _conversationService;
  static bool _useInMemory = true;
  static bool _initialized = false;

  /// Configure whether to use in-memory or SQLite storage
  static void configure({bool useInMemory = true}) {
    if (_initialized && useInMemory != _useInMemory) {
      throw StateError('Cannot change storage type after initialization');
    }
    _useInMemory = useInMemory;
  }

  /// Initialize the service provider
  static Future<void> initialize() async {
    if (!_useInMemory) {
      // Create new service instances if needed
      getAgentService();
      getConversationService();
      
      // Initialize the services
      await (_agentService as SqliteAgentService).initialize();
      await (_conversationService as SqliteConversationService).initialize();
    }
    _initialized = true;
  }

  /// Gets the current AgentService instance.
  /// Creates a new instance if one doesn't exist.
  static AgentService getAgentService() {
    if (_agentService == null) {
      _agentService = _useInMemory
          ? InMemoryAgentService()
          : SqliteAgentService();
    }
    return _agentService!;
  }

  /// Gets the current ConversationService instance.
  /// Creates a new instance if one doesn't exist.
  static ConversationService getConversationService() {
    if (_conversationService == null) {
      _conversationService = _useInMemory
          ? InMemoryConversationService()
          : SqliteConversationService();
    }
    return _conversationService!;
  }

  /// Resets all services, primarily used for testing.
  static Future<void> reset() async {
    if (!_useInMemory) {
      if (_agentService != null) {
        await (_agentService as SqliteAgentService).close();
      }
      if (_conversationService != null) {
        await (_conversationService as SqliteConversationService).close();
      }
    }
    _agentService = null;
    _conversationService = null;
    _initialized = false;
  }
}
