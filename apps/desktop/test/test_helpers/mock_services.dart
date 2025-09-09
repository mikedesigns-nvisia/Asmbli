import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentengine_desktop/core/services/desktop/desktop_storage_service.dart';
import 'package:agentengine_desktop/core/services/api_config_service.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/services/conversation_service.dart';

/// Mock implementation of DesktopStorageService for testing
class MockDesktopStorageService {
  // Using composition instead of full interface implementation for testing
  final Map<String, dynamic> _preferences = {};
  final Map<String, dynamic> _secureStorage = {};
  
  bool get isInitialized => true;
  
  Future<void> initialize() async {}
  
  T? getPreference<T>(String key, {T? defaultValue}) {
    return _preferences[key] as T? ?? defaultValue;
  }
  
  Future<void> setPreference<T>(String key, T value) async {
    _preferences[key] = value;
  }
  
  Future<void> removePreference(String key) async {
    _preferences.remove(key);
  }
  
  Future<void> clearPreferences() async {
    _preferences.clear();
  }
  
  Future<String?> getSecureValue(String key) async {
    return _secureStorage[key] as String?;
  }
  
  Future<void> setSecureValue(String key, String value) async {
    _secureStorage[key] = value;
  }
  
  Future<void> removeSecureValue(String key) async {
    _secureStorage.remove(key);
  }
  
  Future<void> clearSecureStorage() async {
    _secureStorage.clear();
  }
  
  // Test helper methods
  void setMockPreference<T>(String key, T value) {
    _preferences[key] = value;
  }
  
  void setMockSecureValue(String key, String value) {
    _secureStorage[key] = value;
  }
}

/// Mock implementation of ApiConfigService for testing
class MockApiConfigService {
  Map<String, MockApiConfig> mockApiConfigs = {};
  String? _defaultApiConfigId;
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    _isInitialized = true;
  }
  
  Map<String, ApiConfig> get allApiConfigs {
    return Map.fromEntries(
      mockApiConfigs.entries.map(
        (entry) => MapEntry(entry.key, ApiConfig(
          id: entry.key,
          name: entry.value.provider,
          provider: entry.value.provider,
          apiKey: entry.value.apiKey,
          isConfigured: entry.value.isConfigured,
        )),
      ),
    );
  }
  
  String? get defaultApiConfigId => _defaultApiConfigId;
  
  ApiConfig? get defaultApiConfig {
    if (_defaultApiConfigId != null) {
      return allApiConfigs[_defaultApiConfigId];
    }
    return null;
  }
  
  Future<void> setApiConfig(String id, ApiConfig config) async {
    mockApiConfigs[id] = MockApiConfig(
      provider: config.provider,
      apiKey: config.apiKey,
      isConfigured: config.apiKey.isNotEmpty,
    );
  }
  
  Future<void> removeApiConfig(String id) async {
    mockApiConfigs.remove(id);
    if (_defaultApiConfigId == id) {
      _defaultApiConfigId = null;
    }
  }
  
  ApiConfig? getApiConfig(String id) {
    final mock = mockApiConfigs[id];
    if (mock == null) return null;
    
    return ApiConfig(
      id: id,
      name: mock.provider,
      provider: mock.provider,
      apiKey: mock.apiKey,
      isConfigured: mock.isConfigured,
    );
  }
  
  Future<void> setDefaultApiConfig(String id) async {
    _defaultApiConfigId = id;
  }
  
  Future<bool> testApiConfig(String id) async {
    final config = mockApiConfigs[id];
    return config?.apiKey.isNotEmpty ?? false;
  }
  
  Future<void> resetToDefaults() async {
    mockApiConfigs.clear();
    _defaultApiConfigId = null;
  }
  
  // Test helper methods
  void setMockApiConfigs(Map<String, MockApiConfig> configs) {
    mockApiConfigs = Map.from(configs);
  }
  
  void clearMockConfigs() {
    mockApiConfigs.clear();
  }
}


/// Mock conversation service for testing
class MockConversationService implements ConversationService {
  final List<Conversation> _conversations = [];
  
  // Expose conversations for testing
  List<Conversation> get conversations => List.from(_conversations);
  
  @override
  Future<Conversation> createConversation(Conversation conversation) async {
    _conversations.add(conversation);
    return conversation;
  }
  
  // Helper method for testing
  Future<Conversation> createConversationFromParams({
    String? title,
    Map<String, dynamic>? metadata,
  }) async {
    final conversation = Conversation(
      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Test Conversation',
      messages: [],
      createdAt: DateTime.now(),
      status: ConversationStatus.active,
      metadata: metadata,
    );
    
    return createConversation(conversation);
  }
  
  @override
  Future<List<Conversation>> listConversations() async {
    return List.from(_conversations);
  }
  
  @override
  Future<Conversation> getConversation(String conversationId) async {
    return _conversations.firstWhere((c) => c.id == conversationId);
  }
  
  @override
  Future<Conversation> updateConversation(Conversation conversation) async {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
    }
    return conversation;
  }
  
  @override
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
  }
  
  @override
  Future<Message> addMessage(String conversationId, Message message) async {
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      final updatedMessages = List<Message>.from(conversation.messages)..add(message);
      _conversations[conversationIndex] = conversation.copyWith(messages: updatedMessages);
    }
    return message;
  }
  
  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final conversation = _conversations.where((c) => c.id == conversationId).firstOrNull;
    return conversation?.messages ?? [];
  }
  
  @override
  Future<void> setConversationStatus(String id, ConversationStatus status) async {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(status: status);
    }
  }
  
  // Test helper methods
  void addMockConversation(Conversation conversation) {
    _conversations.add(conversation);
  }
  
  void clearMockData() {
    _conversations.clear();
  }
}

/// Mock API config for testing
class MockApiConfig {
  final String provider;
  final String apiKey;
  final bool isConfigured;
  
  MockApiConfig({
    required this.provider,
    required this.apiKey,
    required this.isConfigured,
  });
}

/// API Config class for compatibility
class ApiConfig {
  final String id;
  final String name;
  final String provider;
  final String apiKey;
  final bool isConfigured;
  
  ApiConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.apiKey,
    required this.isConfigured,
  });
}
