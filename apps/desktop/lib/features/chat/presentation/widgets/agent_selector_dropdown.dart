import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/agent_provider.dart';
import '../../../../providers/conversation_provider.dart';

class AgentSelectorDropdown extends ConsumerWidget {
  const AgentSelectorDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentNotifierProvider);
    final activeAgent = ref.watch(activeAgentProvider);

    return agentsAsync.when(
      loading: () => _buildLoadingSkeleton(context),
      error: (error, stack) => _buildErrorState(context, error),
      data: (agents) {
        if (agents.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildAgentDropdown(context, ref, agents, activeAgent);
      },
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: SemanticColors.surfaceVariant.withOpacity( 0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              SemanticColors.primary.withOpacity( 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.cardPadding),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: SemanticColors.error.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: SemanticColors.error.withOpacity( 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: SemanticColors.error,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Text(
              'Failed to load agents',
              style: TextStyles.bodySmall.copyWith(
                color: SemanticColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.cardPadding),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: SemanticColors.surfaceVariant.withOpacity( 0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: SemanticColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.smart_toy_outlined,
            size: 16,
            color: SemanticColors.onSurfaceVariant,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Text(
              'No agents available',
              style: TextStyles.bodySmall.copyWith(
                color: SemanticColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentDropdown(BuildContext context, WidgetRef ref, List<Agent> agents, Agent? activeAgent) {
    // Ensure activeAgent exists in the agents list, otherwise set to null
    final validActiveAgentId = activeAgent != null && 
                              agents.any((agent) => agent.id == activeAgent.id) 
                              ? activeAgent.id 
                              : null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.cardPadding),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validActiveAgentId,
          isExpanded: true,
          hint: _buildDropdownHint(context),
          onChanged: (agentId) async {
            if (agentId != null) {
              final selectedAgent = agents.firstWhere((agent) => agent.id == agentId);
              
              // Get current conversation ID from the conversation provider
              final conversationId = ref.read(selectedConversationIdProvider) ?? 'default';
              
              // Load agent with MCP installation check
              await ref.read(agentNotifierProvider.notifier).loadAgentForConversation(selectedAgent, conversationId);
            }
          },
          selectedItemBuilder: (context) {
            return agents.map((agent) => _buildSelectedItem(context, agent)).toList();
          },
          items: agents.map((agent) => _buildDropdownItem(context, agent)).toList(),
          dropdownColor: SemanticColors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          elevation: 8,
          style: TextStyles.bodyMedium.copyWith(
            color: SemanticColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownHint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.smart_toy_outlined,
            size: 16,
            color: SemanticColors.onSurfaceVariant,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            'Select an agent',
            style: TextStyles.bodySmall.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItem(BuildContext context, Agent agent) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: ThemeColors(context).border),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getAgentColor(context, agent).withOpacity( 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(
              _getAgentIcon(agent),
              size: 12,
              color: _getAgentColor(context, agent),
            ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  agent.name,
                  style: TextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SemanticColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (agent.status == AgentStatus.active) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: ThemeColors(context).success,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyles.caption.copyWith(
                          color: ThemeColors(context).success,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: SemanticColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(BuildContext context, Agent agent) {
    return DropdownMenuItem<String>(
      value: agent.id,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getAgentColor(context, agent).withOpacity( 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Icon(
                _getAgentIcon(agent),
                size: 16,
                color: _getAgentColor(context, agent),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          agent.name,
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: SemanticColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (agent.status == AgentStatus.active) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: ThemeColors(context).success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agent.description,
                    style: TextStyles.bodySmall.copyWith(
                      color: SemanticColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...agent.capabilities.take(3).map((capability) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ThemeColors(context).primary.withOpacity( 0.1),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                        ),
                        child: Text(
                          capability,
                          style: TextStyles.caption.copyWith(
                            color: ThemeColors(context).primary,
                            fontSize: 9,
                          ),
                        ),
                      )),
                      if (agent.capabilities.length > 3) ...[
                        Text(
                          '+${agent.capabilities.length - 3}',
                          style: TextStyles.caption.copyWith(
                            color: SemanticColors.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAgentColor(BuildContext context, Agent agent) {
    switch (agent.id) {
      case 'research-assistant':
        return const Color(0xFF4CAF50); // Green
      case 'code-helper':
        return const Color(0xFF2196F3); // Blue
      case 'data-analyst':
        return const Color(0xFFFF9800); // Orange
      default:
        return ThemeColors(context).primary;
    }
  }

  IconData _getAgentIcon(Agent agent) {
    switch (agent.id) {
      case 'research-assistant':
        return Icons.search;
      case 'code-helper':
        return Icons.code;
      case 'data-analyst':
        return Icons.analytics;
      default:
        return Icons.smart_toy;
    }
  }
}