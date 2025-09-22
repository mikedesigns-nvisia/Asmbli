import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../providers/simple_real_execution_provider.dart';

/// Working Agent Connections tab that uses only existing real models
class WorkingAgentConnectionsTab extends ConsumerWidget {
  const WorkingAgentConnectionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final state = ref.watch(simpleExecutionProvider);
    final agentConnections = ref.watch(agentConnectionsWithStatusProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorState(colors, state.error!, ref);
    }

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, state),
          const SizedBox(height: SpacingTokens.lg),
          
          // Agent Connections List
          Expanded(
            child: agentConnections.isEmpty 
                ? _buildEmptyState(colors)
                : _buildAgentConnectionsList(colors, agentConnections, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, SimpleExecutionState state) {
    final runningServers = state.installedServers.where((s) => s.isRunning).length;
    final totalAgents = state.agentConnections.length;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🤖 Real Agent-MCP Connections',
                style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'Live view of which agents have access to which MCP tools',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        
        // Status indicators
        Row(
          children: [
            _buildStatusIndicator(
              colors,
              'Agents',
              totalAgents.toString(),
              Icons.smart_toy,
              colors.primary,
            ),
            const SizedBox(width: SpacingTokens.lg),
            _buildStatusIndicator(
              colors,
              'Running Servers',
              runningServers.toString(),
              Icons.dns,
              runningServers > 0 ? colors.success : colors.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    ThemeColors colors,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: SpacingTokens.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentConnectionsList(
    ThemeColors colors,
    List<AgentConnectionWithStatus> connections,
    WidgetRef ref,
  ) {
    return ListView.builder(
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final agentConnection = connections[index];
        return _buildAgentConnectionCard(colors, agentConnection, ref);
      },
    );
  }

  Widget _buildAgentConnectionCard(
    ThemeColors colors,
    AgentConnectionWithStatus agentConnection,
    WidgetRef ref,
  ) {
    final connection = agentConnection.connection;
    
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
      child: AsmblCard(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Agent header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: agentConnection.hasActiveServers 
                          ? colors.success.withValues(alpha: 0.2)
                          : colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: agentConnection.hasActiveServers ? colors.success : colors.primary,
                          size: 24,
                        ),
                        if (agentConnection.hasActiveServers)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.lg),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.agentName,
                          style: TextStyles.bodyLarge.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          'ID: ${connection.agentId}',
                          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                        ),
                        if (connection.lastUpdated != null)
                          Text(
                            'Updated: ${_formatDateTime(connection.lastUpdated!)}',
                            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  
                  // Quick stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildQuickStat(colors, agentConnection.connectedRunningServers.length.toString(), 'Active'),
                      _buildQuickStat(colors, agentConnection.totalConnectedServers.toString(), 'Total'),
                      _buildQuickStat(colors, agentConnection.availableToolsCount.toString(), 'Tools'),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.md),
              
              // Connected servers status
              if (agentConnection.connectedRunningServers.isNotEmpty) ...[
                Text(
                  'Active MCP Servers:',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                
                Wrap(
                  spacing: SpacingTokens.sm,
                  runSpacing: SpacingTokens.sm,
                  children: agentConnection.connectedRunningServers.map((server) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: SpacingTokens.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.xs),
                          Text(
                            server.name,
                            style: TextStyles.caption.copyWith(
                              color: colors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (server.isOfficial) ...[
                            const SizedBox(width: SpacingTokens.xs),
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: colors.success,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ] else if (agentConnection.totalConnectedServers > 0) ...[
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: Border.all(color: colors.onSurfaceVariant.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: colors.onSurfaceVariant, size: 16),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        '${agentConnection.totalConnectedServers} servers configured but not running',
                        style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: Border.all(color: colors.onSurfaceVariant.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.onSurfaceVariant, size: 16),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        'No MCP servers connected to this agent',
                        style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: SpacingTokens.md),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AsmblButton.secondary(
                      text: 'View Configuration',
                      onPressed: () => _showConfigurationDialog(agentConnection, ref),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  if (agentConnection.hasActiveServers)
                    Expanded(
                      child: AsmblButton.primary(
                        text: 'Test Connection',
                        onPressed: () => _testConnection(agentConnection, ref),
                      ),
                    )
                  else
                    Expanded(
                      child: AsmblButton.primary(
                        text: 'Configure Tools',
                        onPressed: () => _showToolConfiguration(agentConnection, ref),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(ThemeColors colors, String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              size: 40,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'No agents found',
            style: TextStyles.headlineSmall.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Create an agent to see its MCP tool connections here',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeColors colors, String error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Connection Error',
            style: TextStyles.headlineSmall.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            error,
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.lg),
          AsmblButton.primary(
            text: 'Retry',
            onPressed: () => ref.read(simpleExecutionProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _showConfigurationDialog(AgentConnectionWithStatus connection, WidgetRef ref) {
    // TODO: Show detailed agent-MCP configuration
    print('Show configuration for agent: ${connection.connection.agentName}');
  }

  void _testConnection(AgentConnectionWithStatus connection, WidgetRef ref) {
    // TODO: Test MCP connections for this agent
    print('Test connections for agent: ${connection.connection.agentName}');
  }

  void _showToolConfiguration(AgentConnectionWithStatus connection, WidgetRef ref) {
    // TODO: Configure MCP tools for this agent
    print('Configure tools for agent: ${connection.connection.agentName}');
  }
}