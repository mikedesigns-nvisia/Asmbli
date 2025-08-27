import 'package:flutter/material.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import '../../../../core/services/mcp_template_service.dart';
import 'custom_mcp_server_modal.dart';

/// Helper function to show the appropriate configuration modal for an integration
/// This provides a simplified API for other parts of the app to configure integrations
Future<Map<String, dynamic>?> showIntegrationConfigurationModal({
  required BuildContext context,
  IntegrationDefinition? integration,
  MCPServerTemplate? template,
  Map<String, dynamic>? initialConfig,
}) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => CustomMCPServerModal(
      integration: integration,
      template: template,
      initialConfig: initialConfig,
      onConfigurationComplete: (config) {
        Navigator.of(context).pop(config);
      },
    ),
  );

  return result;
}

/// Configuration result for integration setup
class IntegrationConfigResult {
  final String integrationId;
  final String serverName;
  final Map<String, dynamic> serverConfig;
  final bool isStructuredForm;

  const IntegrationConfigResult({
    required this.integrationId,
    required this.serverName,
    required this.serverConfig,
    required this.isStructuredForm,
  });

  /// Get the first (and expected only) server name from the config
  static String? getServerNameFromConfig(Map<String, dynamic> config) {
    if (config.isEmpty) return null;
    return config.keys.first;
  }

  /// Get the server configuration from the config
  static Map<String, dynamic>? getServerConfigFromConfig(Map<String, dynamic> config) {
    if (config.isEmpty) return null;
    final serverName = getServerNameFromConfig(config);
    if (serverName == null) return null;
    return config[serverName] as Map<String, dynamic>?;
  }
}