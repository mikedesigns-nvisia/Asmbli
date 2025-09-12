import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../services/api_config_service.dart';
import 'mcp_server_config.dart';
import 'oauth_provider.dart';
import '../theme/color_schemes.dart';

/// Unified settings state containing all app settings
class UnifiedSettingsState extends Equatable {
  final AiModelsSettings aiModels;
  final McpToolsSettings mcpTools;
  final AppearanceSettings appearance;
  final OAuthSettings oauth;
  final AgentSettings agents;
  final AccountSettings account;
  final bool isLoading;
  final String? error;

  const UnifiedSettingsState({
    required this.aiModels,
    required this.mcpTools,
    required this.appearance,
    required this.oauth,
    required this.agents,
    required this.account,
    this.isLoading = false,
    this.error,
  });

  /// Create loading state
  const UnifiedSettingsState.loading()
      : aiModels = const AiModelsSettings(),
        mcpTools = const McpToolsSettings(),
        appearance = const AppearanceSettings(),
        oauth = const OAuthSettings(),
        agents = const AgentSettings(),
        account = const AccountSettings(),
        isLoading = true,
        error = null;

  /// Create error state
  UnifiedSettingsState.error(String errorMessage)
      : aiModels = const AiModelsSettings(),
        mcpTools = const McpToolsSettings(),
        appearance = const AppearanceSettings(),
        oauth = const OAuthSettings(),
        agents = const AgentSettings(),
        account = const AccountSettings(),
        isLoading = false,
        error = errorMessage;

  /// Create copy with updated values
  UnifiedSettingsState copyWith({
    AiModelsSettings? aiModels,
    McpToolsSettings? mcpTools,
    AppearanceSettings? appearance,
    OAuthSettings? oauth,
    AgentSettings? agents,
    AccountSettings? account,
    bool? isLoading,
    String? error,
  }) {
    return UnifiedSettingsState(
      aiModels: aiModels ?? this.aiModels,
      mcpTools: mcpTools ?? this.mcpTools,
      appearance: appearance ?? this.appearance,
      oauth: oauth ?? this.oauth,
      agents: agents ?? this.agents,
      account: account ?? this.account,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'aiModels': aiModels.toJson(),
      'mcpTools': mcpTools.toJson(),
      'appearance': appearance.toJson(),
      'oauth': oauth.toJson(),
      'agents': agents.toJson(),
      'account': account.toJson(),
    };
  }

  /// Create from JSON for import
  factory UnifiedSettingsState.fromJson(Map<String, dynamic> json) {
    return UnifiedSettingsState(
      aiModels: AiModelsSettings.fromJson(json['aiModels'] ?? {}),
      mcpTools: McpToolsSettings.fromJson(json['mcpTools'] ?? {}),
      appearance: AppearanceSettings.fromJson(json['appearance'] ?? {}),
      oauth: OAuthSettings.fromJson(json['oauth'] ?? {}),
      agents: AgentSettings.fromJson(json['agents'] ?? {}),
      account: AccountSettings.fromJson(json['account'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        aiModels,
        mcpTools,
        appearance,
        oauth,
        agents,
        account,
        isLoading,
        error,
      ];
}

/// AI Models and API configuration settings
class AiModelsSettings extends Equatable {
  final List<ApiConfig> configurations;
  final String? defaultModelId;
  final Map<String, bool> enabledProviders;

  const AiModelsSettings({
    this.configurations = const [],
    this.defaultModelId,
    this.enabledProviders = const {},
  });

  /// Create from existing API configurations
  factory AiModelsSettings.fromApiConfigs(Map<String, ApiConfig> configs) {
    return AiModelsSettings(
      configurations: configs.values.toList(),
      enabledProviders: Map.fromEntries(
        configs.entries.map((e) => MapEntry(e.key, e.value.isConfigured)),
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'configurations': configurations.map((c) => c.toJson()).toList(),
      'defaultModelId': defaultModelId,
      'enabledProviders': enabledProviders,
    };
  }

  /// Create from JSON
  factory AiModelsSettings.fromJson(Map<String, dynamic> json) {
    return AiModelsSettings(
      configurations: (json['configurations'] as List<dynamic>?)
              ?.map((c) => ApiConfig.fromJson(c))
              .toList() ??
          [],
      defaultModelId: json['defaultModelId'],
      enabledProviders: Map<String, bool>.from(json['enabledProviders'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [configurations, defaultModelId, enabledProviders];
}

/// MCP Tools and integrations settings
class McpToolsSettings extends Equatable {
  final List<MCPServerConfig> servers;
  final Map<String, bool> enabledTools;
  final Map<String, Map<String, dynamic>> toolConfigurations;

  const McpToolsSettings({
    this.servers = const [],
    this.enabledTools = const {},
    this.toolConfigurations = const {},
  });

  /// Create from existing MCP server configurations
  factory McpToolsSettings.fromMcpServers(List<MCPServerConfig> mcpServers) {
    return McpToolsSettings(
      servers: mcpServers,
      enabledTools: Map.fromEntries(
        mcpServers.map((s) => MapEntry(s.id, s.enabled)),
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'servers': servers.map((s) => s.toJson()).toList(),
      'enabledTools': enabledTools,
      'toolConfigurations': toolConfigurations,
    };
  }

  /// Create from JSON
  factory McpToolsSettings.fromJson(Map<String, dynamic> json) {
    return McpToolsSettings(
      servers: (json['servers'] as List<dynamic>?)
              ?.map((s) => MCPServerConfig.fromJson(s))
              .toList() ??
          [],
      enabledTools: Map<String, bool>.from(json['enabledTools'] ?? {}),
      toolConfigurations: Map<String, Map<String, dynamic>>.from(
        json['toolConfigurations'] ?? {},
      ),
    );
  }

  @override
  List<Object?> get props => [servers, enabledTools, toolConfigurations];
}

/// Appearance and theme settings
class AppearanceSettings extends Equatable {
  final ThemeMode themeMode;
  final String colorScheme;
  final double fontSize;
  final bool compactMode;

  const AppearanceSettings({
    this.themeMode = ThemeMode.system,
    this.colorScheme = AppColorSchemes.warmNeutral,
    this.fontSize = 14.0,
    this.compactMode = false,
  });

  /// Create from theme service state
  factory AppearanceSettings.fromThemeState(Map<String, dynamic> themeState) {
    return AppearanceSettings(
      themeMode: _parseThemeMode(themeState['themeMode']),
      colorScheme: themeState['colorScheme'] ?? AppColorSchemes.warmNeutral,
    );
  }

  static ThemeMode _parseThemeMode(dynamic value) {
    if (value is ThemeMode) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    }
    return ThemeMode.system;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'colorScheme': colorScheme,
      'fontSize': fontSize,
      'compactMode': compactMode,
    };
  }

  /// Create from JSON
  factory AppearanceSettings.fromJson(Map<String, dynamic> json) {
    return AppearanceSettings(
      themeMode: _parseThemeMode(json['themeMode']),
      colorScheme: json['colorScheme'] ?? AppColorSchemes.warmNeutral,
      fontSize: (json['fontSize'] ?? 14.0).toDouble(),
      compactMode: json['compactMode'] ?? false,
    );
  }

  @override
  List<Object?> get props => [themeMode, colorScheme, fontSize, compactMode];
}

/// OAuth and authentication settings
class OAuthSettings extends Equatable {
  final List<OAuthProvider> connectedProviders;
  final Map<OAuthProvider, DateTime> connectionDates;
  final Map<OAuthProvider, List<String>> grantedScopes;

  const OAuthSettings({
    this.connectedProviders = const [],
    this.connectionDates = const {},
    this.grantedScopes = const {},
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'connectedProviders':
          connectedProviders.map((p) => p.name).toList(),
      'connectionDates': connectionDates.map(
        (k, v) => MapEntry(k.name, v.toIso8601String()),
      ),
      'grantedScopes': grantedScopes.map(
        (k, v) => MapEntry(k.name, v),
      ),
    };
  }

  /// Create from JSON
  factory OAuthSettings.fromJson(Map<String, dynamic> json) {
    return OAuthSettings(
      connectedProviders: (json['connectedProviders'] as List<dynamic>?)
              ?.map((name) => OAuthProvider.values
                  .firstWhere((p) => p.name == name))
              .toList() ??
          [],
      connectionDates: Map<OAuthProvider, DateTime>.fromEntries(
        (json['connectionDates'] as Map<String, dynamic>?)?.entries.map(
              (e) => MapEntry(
                OAuthProvider.values.firstWhere((p) => p.name == e.key),
                DateTime.parse(e.value),
              ),
            ) ??
            [],
      ),
      grantedScopes: Map<OAuthProvider, List<String>>.fromEntries(
        (json['grantedScopes'] as Map<String, dynamic>?)?.entries.map(
              (e) => MapEntry(
                OAuthProvider.values.firstWhere((p) => p.name == e.key),
                List<String>.from(e.value),
              ),
            ) ??
            [],
      ),
    );
  }

  @override
  List<Object?> get props => [connectedProviders, connectionDates, grantedScopes];
}

/// Agent management settings
class AgentSettings extends Equatable {
  final Map<String, String> systemPrompts;
  final Map<String, dynamic> agentConfigurations;

  const AgentSettings({
    this.systemPrompts = const {},
    this.agentConfigurations = const {},
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'systemPrompts': systemPrompts,
      'agentConfigurations': agentConfigurations,
    };
  }

  /// Create from JSON
  factory AgentSettings.fromJson(Map<String, dynamic> json) {
    return AgentSettings(
      systemPrompts: Map<String, String>.from(json['systemPrompts'] ?? {}),
      agentConfigurations: Map<String, dynamic>.from(json['agentConfigurations'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [systemPrompts, agentConfigurations];
}

/// Account and profile settings
class AccountSettings extends Equatable {
  final String? userId;
  final String? email;
  final Map<String, dynamic> preferences;

  const AccountSettings({
    this.userId,
    this.email,
    this.preferences = const {},
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'preferences': preferences,
    };
  }

  /// Create from JSON
  factory AccountSettings.fromJson(Map<String, dynamic> json) {
    return AccountSettings(
      userId: json['userId'],
      email: json['email'],
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [userId, email, preferences];
}

/// Settings categories enum
enum SettingsCategory {
  account,
  aiModels,
  agents,
  mcpTools,
  oauth,
  appearance,
}

/// Settings events for notifications
class SettingsEvent extends Equatable {
  final SettingsEventType type;
  final SettingsCategory? category;
  final String? message;

  const SettingsEvent({
    required this.type,
    this.category,
    this.message,
  });

  factory SettingsEvent.initialized() => const SettingsEvent(type: SettingsEventType.initialized);
  factory SettingsEvent.updated(SettingsCategory category) => SettingsEvent(
        type: SettingsEventType.updated,
        category: category,
      );
  factory SettingsEvent.error(String message) => SettingsEvent(
        type: SettingsEventType.error,
        message: message,
      );
  factory SettingsEvent.imported() => const SettingsEvent(type: SettingsEventType.imported);
  factory SettingsEvent.reset() => const SettingsEvent(type: SettingsEventType.reset);

  @override
  List<Object?> get props => [type, category, message];
}

enum SettingsEventType {
  initialized,
  updated,
  error,
  imported,
  reset,
}

/// Test result for settings connections
class SettingsTestResult extends Equatable {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? details;

  const SettingsTestResult({
    required this.isSuccess,
    required this.message,
    this.details,
  });

  factory SettingsTestResult.success(String message, [Map<String, dynamic>? details]) {
    return SettingsTestResult(
      isSuccess: true,
      message: message,
      details: details,
    );
  }

  factory SettingsTestResult.error(String message, [Map<String, dynamic>? details]) {
    return SettingsTestResult(
      isSuccess: false,
      message: message,
      details: details,
    );
  }

  factory SettingsTestResult.partial(String message, [Map<String, dynamic>? details]) {
    return SettingsTestResult(
      isSuccess: false, // Treat partial as non-success for UI purposes
      message: message,
      details: details,
    );
  }

  @override
  List<Object?> get props => [isSuccess, message, details];
}