import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/settings_models.dart';
import '../services/unified_settings_service.dart';

/// Centralized settings state notifier following the established pattern
class SettingsNotifier extends StateNotifier<UnifiedSettingsState> {
  final UnifiedSettingsService _settingsService;
  StreamSubscription<SettingsEvent>? _eventSubscription;

  SettingsNotifier(this._settingsService) : super(const UnifiedSettingsState.loading()) {
    _initialize();
  }

  /// Initialize and load settings
  Future<void> _initialize() async {
    try {
      // Subscribe to settings events
      _eventSubscription = _settingsService.settingsEvents.listen(_handleSettingsEvent);

      // Load initial settings state
      await _loadSettings();
    } catch (e) {
      state = UnifiedSettingsState.error('Failed to initialize settings: $e');
    }
  }

  /// Load complete settings state
  Future<void> _loadSettings() async {
    try {
      final settingsState = await _settingsService.getSettingsState();
      if (mounted) {
        state = settingsState;
      }
    } catch (e) {
      if (mounted) {
        state = UnifiedSettingsState.error('Failed to load settings: $e');
      }
    }
  }

  /// Handle settings events from the service
  void _handleSettingsEvent(SettingsEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case SettingsEventType.updated:
        // Reload specific category or all settings
        _loadSettings();
        break;
      case SettingsEventType.error:
        state = state.copyWith(error: event.message);
        break;
      case SettingsEventType.initialized:
      case SettingsEventType.imported:
      case SettingsEventType.reset:
        _loadSettings();
        break;
    }
  }

  /// Refresh all settings from services
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadSettings();
  }

  /// Save AI models settings
  Future<void> saveAiModelsSettings(AiModelsSettings settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _settingsService.saveAiModelsSettings(settings);
      // State will update via event listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to save AI models: $e');
    }
  }

  /// Save MCP tools settings
  Future<void> saveMcpToolsSettings(McpToolsSettings settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _settingsService.saveMcpToolsSettings(settings);
      // State will update via event listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to save MCP tools: $e');
    }
  }

  /// Save appearance settings
  Future<void> saveAppearanceSettings(AppearanceSettings settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _settingsService.saveAppearanceSettings(settings);
      // State will update via event listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to save appearance: $e');
    }
  }

  /// Save OAuth settings
  Future<void> saveOAuthSettings(OAuthSettings settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _settingsService.saveOAuthSettings(settings);
      // State will update via event listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to save OAuth: $e');
    }
  }

  /// Test connection for a settings category
  Future<SettingsTestResult> testConnection(SettingsCategory category) async {
    return await _settingsService.testConnection(category);
  }

  /// Export all settings
  Future<Map<String, dynamic>> exportSettings() async {
    return await _settingsService.exportSettings();
  }

  /// Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> settingsJson) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _settingsService.importSettings(settingsJson);
      // State will update via event listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to import settings: $e');
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _settingsService.resetToDefaults();
      // State will update via event listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to reset settings: $e');
    }
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _settingsService.dispose();
    super.dispose();
  }
}

/// Main settings provider - centralized state management
final settingsProvider = StateNotifierProvider<SettingsNotifier, UnifiedSettingsState>((ref) {
  return SettingsNotifier(ref.read(unifiedSettingsServiceProvider));
});

/// Convenience providers for specific setting categories
final aiModelsSettingsProvider = Provider<AiModelsSettings>((ref) {
  return ref.watch(settingsProvider).aiModels;
});

final mcpToolsSettingsProvider = Provider<McpToolsSettings>((ref) {
  return ref.watch(settingsProvider).mcpTools;
});

final appearanceSettingsProvider = Provider<AppearanceSettings>((ref) {
  return ref.watch(settingsProvider).appearance;
});

final oauthSettingsProvider = Provider<OAuthSettings>((ref) {
  return ref.watch(settingsProvider).oauth;
});

final agentSettingsProvider = Provider<AgentSettings>((ref) {
  return ref.watch(settingsProvider).agents;
});

final accountSettingsProvider = Provider<AccountSettings>((ref) {
  return ref.watch(settingsProvider).account;
});

/// Provider for settings loading state
final settingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).isLoading;
});

/// Provider for settings error state
final settingsErrorProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).error;
});

/// Settings search provider - filters settings based on query
final settingsSearchProvider = StateProvider<String>((ref) => '');

/// Filtered settings categories based on search
final filteredSettingsCategoriesProvider = Provider<List<SettingsCategory>>((ref) {
  final searchQuery = ref.watch(settingsSearchProvider);
  
  if (searchQuery.isEmpty) {
    return SettingsCategory.values;
  }

  // Simple search implementation - could be enhanced
  final query = searchQuery.toLowerCase();
  return SettingsCategory.values.where((category) {
    return category.name.toLowerCase().contains(query) ||
           _getCategoryDescription(category).toLowerCase().contains(query);
  }).toList();
});

/// Helper function to get category descriptions for search
String _getCategoryDescription(SettingsCategory category) {
  switch (category) {
    case SettingsCategory.account:
      return 'Account profile user preferences personal information';
    case SettingsCategory.aiModels:
      return 'AI models LLM Claude OpenAI API keys language models';
    case SettingsCategory.agents:
      return 'AI agents system prompts agent management configuration';
    case SettingsCategory.mcpTools:
      return 'MCP tools integrations servers plugins extensions';
    case SettingsCategory.oauth:
      return 'OAuth authentication security login connections providers';
    case SettingsCategory.appearance:
      return 'Appearance theme colors dark light mode UI display';
  }
}

/// Provider for settings that need attention (errors, missing configs, etc.)
final settingsAttentionProvider = Provider<List<SettingsAttentionItem>>((ref) {
  final settings = ref.watch(settingsProvider);
  final attentionItems = <SettingsAttentionItem>[];

  // Check for missing AI model configurations
  if (settings.aiModels.configurations.isEmpty) {
    attentionItems.add(SettingsAttentionItem(
      category: SettingsCategory.aiModels,
      message: 'No AI models configured',
      severity: SettingsAttentionSeverity.warning,
    ));
  }

  // Check for inactive MCP tools
  final inactiveMcpCount = settings.mcpTools.servers
      .where((s) => !s.enabled)
      .length;
  if (inactiveMcpCount > 0) {
    attentionItems.add(SettingsAttentionItem(
      category: SettingsCategory.mcpTools,
      message: '$inactiveMcpCount MCP tools are inactive',
      severity: SettingsAttentionSeverity.info,
    ));
  }

  // Check for OAuth connection issues
  if (settings.oauth.connectedProviders.isEmpty) {
    attentionItems.add(SettingsAttentionItem(
      category: SettingsCategory.oauth,
      message: 'No OAuth providers connected',
      severity: SettingsAttentionSeverity.info,
    ));
  }

  return attentionItems;
});

/// Settings attention item model
class SettingsAttentionItem {
  final SettingsCategory category;
  final String message;
  final SettingsAttentionSeverity severity;

  SettingsAttentionItem({
    required this.category,
    required this.message,
    required this.severity,
  });
}

enum SettingsAttentionSeverity {
  info,
  warning,
  error,
}