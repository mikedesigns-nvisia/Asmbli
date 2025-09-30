import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import 'package:agent_engine_core/services/conversation_service.dart';

/// Mock implementation of AgentService for testing
class MockAgentService implements AgentService {
  final List<Agent> _agents = [];
  bool _throwError = false;

  /// Set to true to simulate errors
  void setThrowError(bool value) {
    _throwError = value;
  }

  void _checkError() {
    if (_throwError) {
      throw Exception('Mock error: Operation failed');
    }
  }

  @override
  Future<Agent> createAgent(Agent agent) async {
    _checkError();
    _agents.add(agent);
    return agent;
  }

  @override
  Future<List<Agent>> listAgents() async {
    _checkError();
    return List.from(_agents);
  }

  @override
  Future<Agent> getAgent(String id) async {
    _checkError();
    try {
      return _agents.firstWhere((a) => a.id == id);
    } catch (e) {
      throw Exception('Agent not found: $id');
    }
  }

  @override
  Future<Agent> updateAgent(Agent agent) async {
    _checkError();
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index != -1) {
      _agents[index] = agent;
      return agent;
    }
    throw Exception('Agent not found: ${agent.id}');
  }

  @override
  Future<void> deleteAgent(String id) async {
    _checkError();
    _agents.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> setAgentStatus(String id, AgentStatus status) async {
    _checkError();
    final index = _agents.indexWhere((a) => a.id == id);
    if (index != -1) {
      _agents[index] = _agents[index].copyWith(status: status);
    }
  }

  /// Helper to clear all agents
  void clear() {
    _agents.clear();
    _throwError = false;
  }
}

/// Mock implementation of ConversationService for testing
class MockConversationService implements ConversationService {
  final List<Conversation> _conversations = [];
  final Map<String, List<Message>> _messages = {};
  bool _throwError = false;

  void setThrowError(bool value) {
    _throwError = value;
  }

  void _checkError() {
    if (_throwError) {
      throw Exception('Mock error: Operation failed');
    }
  }

  @override
  Future<Conversation> createConversation(Conversation conversation) async {
    _checkError();
    _conversations.add(conversation);
    _messages[conversation.id] = [];
    return conversation;
  }

  @override
  Future<List<Conversation>> listConversations() async {
    _checkError();
    return List.from(_conversations);
  }

  @override
  Future<Conversation> getConversation(String id) async {
    _checkError();
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      throw Exception('Conversation not found: $id');
    }
  }

  @override
  Future<Conversation> updateConversation(Conversation conversation) async {
    _checkError();
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
      return conversation;
    }
    throw Exception('Conversation not found: ${conversation.id}');
  }

  @override
  Future<void> setConversationStatus(String id, ConversationStatus status) async {
    _checkError();
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(status: status);
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    _checkError();
    _conversations.removeWhere((c) => c.id == id);
    _messages.remove(id);
  }

  @override
  Future<Message> addMessage(String conversationId, Message message) async {
    _checkError();
    if (!_messages.containsKey(conversationId)) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(message);
    return message;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    _checkError();
    return List.from(_messages[conversationId] ?? []);
  }

  /// Helper to clear all conversations
  void clear() {
    _conversations.clear();
    _messages.clear();
    _throwError = false;
  }
}