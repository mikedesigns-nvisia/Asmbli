import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/models/model_config.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/model_config_service.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../../providers/artifact_provider.dart';
import '../../../../providers/agent_provider.dart';
import '../../../../core/models/artifact.dart';

/// Slim fixed status bar for chat - replaces floating dock
///
/// Firefox-style: fixed position below tabs, full width, compact height
/// Shows: status indicators (agent tools, quick chat, MCP tools, docs), model selector
class ChatStatusBar extends ConsumerWidget {
  final String? conversationId;
  final String? agentId;

  const ChatStatusBar({
    super.key,
    this.conversationId,
    this.agentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final mcpService = ref.watch(mcpSettingsServiceProvider);
    final modelConfigService = ref.read(modelConfigServiceProvider);

    // Fetch active agent if agentId is provided
    Agent? activeAgent;
    if (agentId != null) {
      final agentsAsync = ref.watch(agentsProvider);
      agentsAsync.whenData((agents) {
        activeAgent = agents.where((a) => a.id == agentId).firstOrNull;
      });
    }

    // Get status data
    final mcpServers = mcpService.getAllMCPServers().where((s) => s.enabled).toList();
    final contextDocs = mcpService.globalContextDocuments;
    final modelConfig = conversationId != null
        ? ref.watch(conversationModelConfigProvider(conversationId!))
        : modelConfigService.defaultModelConfig;

    // Get artifacts if conversation exists
    final artifacts = conversationId != null
        ? ref.watch(conversationArtifactsProvider(conversationId!))
        : <Artifact>[];

    // Quick chat status
    final isQuickChatActive = conversationId != null
        ? ref.watch(isQuickChatActiveProvider(conversationId!))
        : false;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left side: Status indicators
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Agent Tools indicator
                  if (activeAgent != null) ...[
                    _StatusIndicator(
                      icon: Icons.smart_toy,
                      label: activeAgent!.name,
                      color: colors.accent,
                      badgeCount: _getAgentToolsCount(activeAgent!),
                    ),
                    const SizedBox(width: SpacingTokens.md),
                  ],

                  // Quick Chat indicator
                  if (isQuickChatActive) ...[
                    _StatusIndicator(
                      icon: Icons.bolt,
                      label: 'Quick Chat',
                      color: colors.accent,
                    ),
                    const SizedBox(width: SpacingTokens.md),
                  ],

                  // MCP Tools indicator
                  if (activeAgent == null && mcpServers.isNotEmpty) ...[
                    _StatusIndicator(
                      icon: Icons.construction,
                      label: '${mcpServers.length} tools',
                      color: colors.primary,
                    ),
                    const SizedBox(width: SpacingTokens.md),
                  ],

                  // Context docs indicator
                  if (contextDocs.isNotEmpty) ...[
                    _StatusIndicator(
                      icon: Icons.description,
                      label: '${contextDocs.length} docs',
                      color: colors.success,
                    ),
                    const SizedBox(width: SpacingTokens.md),
                  ],

                  // Artifacts indicator
                  if (artifacts.isNotEmpty) ...[
                    _StatusIndicator(
                      icon: Icons.widgets,
                      label: '${artifacts.length}',
                      color: colors.accent,
                    ),
                  ],

                  // Empty state
                  if (activeAgent == null &&
                      !isQuickChatActive &&
                      mcpServers.isEmpty &&
                      contextDocs.isEmpty &&
                      artifacts.isEmpty)
                    Text(
                      'No active tools or context',
                      style: GoogleFonts.fustat(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Right side: Model selector
          _ModelSelector(modelConfig: modelConfig),
        ],
      ),
    );
  }

  int _getAgentToolsCount(Agent agent) {
    final tools = agent.configuration['selectedTools'] as List<dynamic>?;
    return tools?.length ?? 0;
  }
}

/// Compact status indicator chip
class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int? badgeCount;

  const _StatusIndicator({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.fustat(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          if (badgeCount != null && badgeCount! > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$badgeCount',
                style: GoogleFonts.fustat(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact model selector dropdown
class _ModelSelector extends ConsumerWidget {
  final ModelConfig? modelConfig;

  const _ModelSelector({this.modelConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final modelConfigService = ref.read(modelConfigServiceProvider);
    final allModels = modelConfigService.allModelConfigs.values
        .where((model) => model.isConfigured && model.status == ModelStatus.ready)
        .toList();

    return PopupMenuButton<String>(
      tooltip: 'Select model',
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      color: colors.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              modelConfig?.isLocal == true ? Icons.computer : Icons.cloud,
              size: 12,
              color: modelConfig?.isLocal == true
                  ? colors.accent
                  : colors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              modelConfig?.name ?? 'Select Model',
              style: GoogleFonts.fustat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        // Local models section
        if (allModels.any((m) => m.isLocal)) ...[
          PopupMenuItem<String>(
            enabled: false,
            height: 28,
            child: Text(
              'Local Models',
              style: GoogleFonts.fustat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          ...allModels.where((m) => m.isLocal).map((model) => PopupMenuItem<String>(
            value: model.id,
            height: 36,
            child: Row(
              children: [
                Icon(
                  Icons.computer,
                  size: 14,
                  color: modelConfig?.id == model.id ? colors.accent : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    model.name,
                    style: GoogleFonts.fustat(
                      fontSize: 12,
                      fontWeight: modelConfig?.id == model.id ? FontWeight.w600 : FontWeight.normal,
                      color: modelConfig?.id == model.id ? colors.accent : colors.onSurface,
                    ),
                  ),
                ),
                if (modelConfig?.id == model.id)
                  Icon(Icons.check, size: 14, color: colors.accent),
              ],
            ),
          )),
        ],

        // API models section
        if (allModels.any((m) => !m.isLocal)) ...[
          if (allModels.any((m) => m.isLocal))
            const PopupMenuDivider(),
          PopupMenuItem<String>(
            enabled: false,
            height: 28,
            child: Text(
              'API Models',
              style: GoogleFonts.fustat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          ...allModels.where((m) => !m.isLocal).map((model) => PopupMenuItem<String>(
            value: model.id,
            height: 36,
            child: Row(
              children: [
                Icon(
                  Icons.cloud,
                  size: 14,
                  color: modelConfig?.id == model.id ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    model.name,
                    style: GoogleFonts.fustat(
                      fontSize: 12,
                      fontWeight: modelConfig?.id == model.id ? FontWeight.w600 : FontWeight.normal,
                      color: modelConfig?.id == model.id ? colors.primary : colors.onSurface,
                    ),
                  ),
                ),
                if (modelConfig?.id == model.id)
                  Icon(Icons.check, size: 14, color: colors.primary),
              ],
            ),
          )),
        ],

        // Settings link
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '_settings',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.settings, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Model Settings',
                style: GoogleFonts.fustat(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == '_settings') {
          context.go(AppRoutes.settings);
          return;
        }

        final model = modelConfigService.getModelConfig(value);
        if (model != null) {
          ref.read(selectedModelProvider.notifier).state = model;
        }
      },
    );
  }
}
