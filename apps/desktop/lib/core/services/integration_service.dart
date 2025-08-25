import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'mcp_settings_service.dart';

/// Service for managing integration status and configurations
/// Acts as a bridge between the unified IntegrationRegistry and actual MCP server configs
class IntegrationService {
  final MCPSettingsService _mcpService;
  
  IntegrationService(this._mcpService);

  /// Get all integrations with their current configuration status
  List<IntegrationStatus> getAllIntegrationsWithStatus() {
    final configuredServers = _mcpService.allMCPServers;
    
    return IntegrationRegistry.allIntegrations.map((integrationDef) {
      final mcpConfig = configuredServers[integrationDef.id];
      
      return IntegrationStatus(
        definition: integrationDef,
        isConfigured: mcpConfig != null,
        isEnabled: mcpConfig?.enabled ?? false,
        mcpConfig: mcpConfig,
        lastUpdated: mcpConfig?.lastUpdated,
      );
    }).toList();
  }

  /// Get integrations by category with status
  List<IntegrationStatus> getByCategory(IntegrationCategory category) {
    return getAllIntegrationsWithStatus()
        .where((integration) => integration.definition.category == category)
        .toList();
  }

  /// Search integrations with status
  List<IntegrationStatus> search(String query) {
    final allWithStatus = getAllIntegrationsWithStatus();
    final lowercaseQuery = query.toLowerCase();
    
    return allWithStatus.where((integration) =>
        integration.definition.name.toLowerCase().contains(lowercaseQuery) ||
        integration.definition.description.toLowerCase().contains(lowercaseQuery) ||
        integration.definition.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  /// Get only configured integrations
  List<IntegrationStatus> getConfiguredIntegrations() {
    return getAllIntegrationsWithStatus()
        .where((integration) => integration.isConfigured)
        .toList();
  }

  /// Get only available (not configured) integrations
  List<IntegrationStatus> getAvailableIntegrations() {
    return getAllIntegrationsWithStatus()
        .where((integration) => !integration.isConfigured)
        .toList();
  }

  /// Configure an integration using its definition
  Future<void> configureIntegration(String integrationId, Map<String, dynamic> config) async {
    final integrationDef = IntegrationRegistry.getById(integrationId);
    if (integrationDef == null) {
      throw Exception('Integration definition not found: $integrationId');
    }

    // Create MCP server config from integration definition
    final mcpConfig = MCPServerConfig(
      id: integrationDef.id,
      name: integrationDef.name,
      command: integrationDef.command,
      args: List.from(integrationDef.args),
      env: config.map((key, value) => MapEntry(key, value.toString())),
      description: integrationDef.description,
      enabled: true,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    await _mcpService.setMCPServer(integrationId, mcpConfig);
    await _mcpService.saveSettings();
  }

  /// Update an existing integration configuration
  Future<void> updateIntegration(String integrationId, Map<String, dynamic> config) async {
    final existingConfig = _mcpService.allMCPServers[integrationId];
    if (existingConfig == null) {
      throw Exception('Integration not configured: $integrationId');
    }

    final updatedConfig = existingConfig.copyWith(
      env: config.map((key, value) => MapEntry(key, value.toString())),
      lastUpdated: DateTime.now(),
    );

    await _mcpService.setMCPServer(integrationId, updatedConfig);
    await _mcpService.saveSettings();
  }

  /// Remove an integration
  Future<void> removeIntegration(String integrationId) async {
    await _mcpService.removeMCPServer(integrationId);
    await _mcpService.saveSettings();
  }

  /// Toggle integration enabled/disabled
  Future<void> toggleIntegration(String integrationId) async {
    final existingConfig = _mcpService.allMCPServers[integrationId];
    if (existingConfig == null) {
      throw Exception('Integration not configured: $integrationId');
    }

    final updatedConfig = existingConfig.copyWith(
      enabled: !existingConfig.enabled,
      lastUpdated: DateTime.now(),
    );

    await _mcpService.setMCPServer(integrationId, updatedConfig);
    await _mcpService.saveSettings();
  }

  /// Get integration statistics
  IntegrationStats getStats() {
    final all = getAllIntegrationsWithStatus();
    final configured = all.where((i) => i.isConfigured).length;
    final enabled = all.where((i) => i.isEnabled).length;
    final available = all.where((i) => i.definition.isAvailable).length;

    return IntegrationStats(
      total: all.length,
      configured: configured,
      enabled: enabled,
      available: available,
      byCategory: IntegrationCategory.values.map((category) {
        final categoryIntegrations = getByCategory(category);
        return MapEntry(
          category,
          CategoryStats(
            total: categoryIntegrations.length,
            configured: categoryIntegrations.where((i) => i.isConfigured).length,
            enabled: categoryIntegrations.where((i) => i.isEnabled).length,
          ),
        );
      }).fold({}, (map, entry) => map..[entry.key] = entry.value),
    );
  }
}

/// Integration with its current configuration status
class IntegrationStatus {
  final IntegrationDefinition definition;
  final bool isConfigured;
  final bool isEnabled;
  final MCPServerConfig? mcpConfig;
  final DateTime? lastUpdated;

  const IntegrationStatus({
    required this.definition,
    required this.isConfigured,
    required this.isEnabled,
    this.mcpConfig,
    this.lastUpdated,
  });

  /// Get display status text
  String get statusText {
    if (!isConfigured) return 'Available';
    if (!isEnabled) return 'Configured (Disabled)';
    return 'Configured';
  }

  /// Get status color
  Color get statusColor {
    if (!isConfigured) return Colors.grey;
    if (!isEnabled) return Colors.orange;
    return Colors.green;
  }
}

/// Integration statistics
class IntegrationStats {
  final int total;
  final int configured;
  final int enabled;
  final int available;
  final Map<IntegrationCategory, CategoryStats> byCategory;

  const IntegrationStats({
    required this.total,
    required this.configured,
    required this.enabled,
    required this.available,
    required this.byCategory,
  });
}

class CategoryStats {
  final int total;
  final int configured;
  final int enabled;

  const CategoryStats({
    required this.total,
    required this.configured,
    required this.enabled,
  });
}

// Provider for the integration service
final integrationServiceProvider = Provider<IntegrationService>((ref) {
  final mcpService = ref.watch(mcpSettingsServiceProvider);
  return IntegrationService(mcpService);
});

// Provider for integration stats
final integrationStatsProvider = Provider<IntegrationStats>((ref) {
  final integrationService = ref.watch(integrationServiceProvider);
  return integrationService.getStats();
});