import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';

/// Widget that displays the health status of MCP servers
/// DEPRECATED: This widget depends on the removed MCPHealthMonitor service
/// TODO: Reimplement with MCPServerExecutionService if health monitoring is needed
@Deprecated('Will be reimplemented with MCPServerExecutionService')
class MCPHealthStatusWidget extends ConsumerWidget {
  final String? serverId; // If null, shows all servers
  final bool showDetails;
  final bool compact;

  const MCPHealthStatusWidget({
    super.key,
    this.serverId,
    this.showDetails = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder until health monitoring is reimplemented
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            size: 16,
            color: ThemeColors(context).onSurfaceVariant,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            'Health monitoring disabled',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder provider for health data
/// DEPRECATED: Will be replaced with MCPServerExecutionService-based provider
@Deprecated('Use MCPServerExecutionService directly')
final mcpServerHealthProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return Stream.value({});
});