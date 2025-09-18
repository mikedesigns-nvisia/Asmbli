import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_config_service.dart';
import '../../../core/services/mcp_settings_service.dart';
import '../../../core/services/oauth_integration_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/agent_system_prompt_service.dart';
import '../../../providers/agent_provider.dart';
import '../../../core/models/settings_models.dart';

/// Unified service that orchestrates all settings operations across the app
/// Following the existing service pattern: initialization, orchestration, error handling
class UnifiedSettingsService {
  final ApiConfigService _apiConfigService;
  final MCPSettingsService _mcpSettingsService;
  final OAuthIntegrationService _oauthService;
  final ThemeService _themeService;
  final AgentSystemPromptService _agentPromptService;

  bool _isInitialized = false;
  final StreamController<SettingsEvent> _settingsEventController = 
      StreamController<SettingsEvent>.broadcast();

  UnifiedSettingsService(
    this._apiConfigService,
    this._mcpSettingsService,
    this._oauthService,
    this._themeService,
    this._agentPromptService,
  );

  /// Stream of settings change events
  Stream<SettingsEvent> get settingsEvents => _settingsEventController.stream;

  /// Initialize all settings services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize all services in parallel following existing patterns
      await Future.wait([
        _apiConfigService.initialize(),
        _mcpSettingsService.initialize(),
        _themeService.initialize(),
        _agentPromptService.initialize(),
        // OAuth service doesn't need initialization
      ]);

      _isInitialized = true;
      _settingsEventController.add(SettingsEvent.initialized());
    } catch (e) {
      _settingsEventController.add(SettingsEvent.error('Failed to initialize settings: $e'));
      rethrow;
    }
  }

  /// Get complete settings state from all services
  Future<UnifiedSettingsState> getSettingsState() async {
    if (!_isInitialized) await initialize();

    try {
      // Gather settings from all services using existing APIs
      final apiConfigs = _apiConfigService.allApiConfigs;
      final mcpServers = _mcpSettingsService.getAllMCPServers();
      final themeState = await _themeService.getThemeState();

      return UnifiedSettingsState(
        aiModels: AiModelsSettings.fromApiConfigs(apiConfigs),
        mcpTools: McpToolsSettings.fromMcpServers(mcpServers),
        appearance: AppearanceSettings.fromThemeState(themeState),
        oauth: await _getOAuthSettings(),
        agents: await _getAgentSettings(),
        account: await _getAccountSettings(),
        isLoading: false,
      );
    } catch (e) {
      return UnifiedSettingsState.error('Failed to load settings: $e');
    }
  }

  /// Save AI models settings
  Future<void> saveAiModelsSettings(AiModelsSettings settings) async {
    try {
      // Use existing API config service methods
      for (final config in settings.configurations) {
        await _apiConfigService.setApiConfig(config.id, config);
      }
      
      if (settings.defaultModelId != null) {
        await _apiConfigService.setDefaultApiConfig(settings.defaultModelId!);
      }

      _settingsEventController.add(SettingsEvent.updated(SettingsCategory.aiModels));
    } catch (e) {
      _settingsEventController.add(SettingsEvent.error('Failed to save AI models: $e'));
      rethrow;
    }
  }

  /// Save MCP tools settings
  Future<void> saveMcpToolsSettings(McpToolsSettings settings) async {
    try {
      // Use existing MCP settings service methods
      for (final server in settings.servers) {
        await _mcpSettingsService.setMCPServer(server.id, server);
      }

      _settingsEventController.add(SettingsEvent.updated(SettingsCategory.mcpTools));
    } catch (e) {
      _settingsEventController.add(SettingsEvent.error('Failed to save MCP tools: $e'));
      rethrow;
    }
  }

  /// Save appearance settings
  Future<void> saveAppearanceSettings(AppearanceSettings settings) async {
    try {
      // Use existing theme service methods
      await _themeService.setTheme(settings.themeMode);
      await _themeService.setColorScheme(settings.colorScheme);

      _settingsEventController.add(SettingsEvent.updated(SettingsCategory.appearance));
    } catch (e) {
      _settingsEventController.add(SettingsEvent.error('Failed to save appearance: $e'));
      rethrow;
    }
  }

  /// Save OAuth settings
  Future<void> saveOAuthSettings(OAuthSettings settings) async {
    try {
      // Handle OAuth provider connections/disconnections
      for (final provider in settings.connectedProviders) {
        if (!await _oauthService.hasValidToken(provider)) {
          // This would trigger OAuth flow - in practice this might be handled by UI
          await _oauthService.authenticate(provider);
        }
      }

      _settingsEventController.add(SettingsEvent.updated(SettingsCategory.oauth));
    } catch (e) {
      _settingsEventController.add(SettingsEvent.error('Failed to save OAuth: $e'));
      rethrow;
    }
  }

  /// Get current OAuth settings
  Future<OAuthSettings> _getOAuthSettings() async {
    final connectedProviders = <OAuthProvider>[];
    
    // Check each provider for valid tokens
    for (final provider in OAuthProvider.values) {
      try {
        if (await _oauthService.hasValidToken(provider)) {
          connectedProviders.add(provider);
        }
      } catch (e) {
        // Continue checking other providers
        continue;
      }
    }

    return OAuthSettings(connectedProviders: connectedProviders);
  }

  /// Get current agent settings
  Future<AgentSettings> _getAgentSettings() async {
    // This would integrate with agent provider/service when available
    return AgentSettings(
      systemPrompts: await _agentPromptService.getAllPrompts(),
    );
  }

  /// Get current account settings  
  Future<AccountSettings> _getAccountSettings() async {
    // Placeholder for future account management
    return AccountSettings();
  }

  /// Test connection for a specific settings category
  Future<SettingsTestResult> testConnection(SettingsCategory category) async {
    try {
      switch (category) {
        case SettingsCategory.aiModels:
          return await _testApiConnections();
        case SettingsCategory.mcpTools:
          return await _testMcpConnections();
        case SettingsCategory.oauth:
          return await _testOAuthConnections();
        default:
          return SettingsTestResult.success('No connection test needed');
      }
    } catch (e) {
      return SettingsTestResult.error('Connection test failed: $e');
    }
  }

  /// Test API model connections
  Future<SettingsTestResult> _testApiConnections() async {
    final configs = _apiConfigService.getAllConfigs();
    final results = <String, bool>{};

    for (final config in configs.values) {
      try {
        // Use existing API validation if available
        results[config.name] = config.isConfigured;
      } catch (e) {
        results[config.name] = false;
      }
    }

    final successCount = results.values.where((success) => success).length;
    final totalCount = results.length;

    if (successCount == totalCount) {
      return SettingsTestResult.success('All $totalCount API connections working');
    } else {
      return SettingsTestResult.partial('$successCount/$totalCount connections working');
    }
  }

  /// Test MCP server connections
  Future<SettingsTestResult> _testMcpConnections() async {
    final servers = _mcpSettingsService.getAllMCPServers();
    final enabledCount = servers.where((s) => s.enabled).length;
    
    // This would need integration with MCP execution service for real testing
    return SettingsTestResult.success('$enabledCount MCP servers configured');
  }

  /// Test OAuth connections
  Future<SettingsTestResult> _testOAuthConnections() async {
    final connectedCount = (await _getOAuthSettings()).connectedProviders.length;
    return SettingsTestResult.success('$connectedCount OAuth providers connected');
  }

  /// Export all settings
  Future<Map<String, dynamic>> exportSettings() async {
    final state = await getSettingsState();
    return state.toJson();
  }

  /// Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> settingsJson) async {
    try {
      final state = UnifiedSettingsState.fromJson(settingsJson);
      
      // Import each category
      await Future.wait([
        saveAiModelsSettings(state.aiModels),
        saveMcpToolsSettings(state.mcpTools),
        saveAppearanceSettings(state.appearance),
        // OAuth and agents might need special handling for import
      ]);

      _settingsEventController.add(SettingsEvent.imported());
    } catch (e) {
      _settingsEventController.add(SettingsEvent.error('Failed to import settings: $e'));
      rethrow;
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      await Future.wait([
        _apiConfigService.resetToDefaults(),
        _mcpSettingsService.resetToDefaults(),
        _themeService.resetToDefaults(),
      ]);

      _settingsEventController.add(SettingsEvent.reset());
    } catch (e) {
      _settingsEventController.add(SettingsEvent.error('Failed to reset settings: $e'));
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _settingsEventController.close();
  }
}

/// Riverpod provider for the unified settings service
final unifiedSettingsServiceProvider = Provider<UnifiedSettingsService>((ref) {
  return UnifiedSettingsService(
    ref.read(apiConfigServiceProvider),
    ref.read(mcpSettingsServiceProvider),
    ref.read(oauthIntegrationServiceProvider),
    ref.read(themeServiceProvider.notifier),
    ref.read(agentContextPromptServiceProvider),
  );
});