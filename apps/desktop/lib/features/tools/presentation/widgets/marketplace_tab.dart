import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../models/mcp_server.dart';
import '../providers/tools_provider.dart';

class MarketplaceTab extends ConsumerWidget {
  const MarketplaceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final state = ref.watch(toolsProvider);

    if (state.isLoading && !state.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final installedServerIds = state.installedServers.map((s) => s.id).toSet();
    final availableServers = state.availableServers
        .where((server) => !installedServerIds.contains(server.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MCP Server Marketplace',
                style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
              ),
              const Spacer(),
              AsmblButton.secondary(
                text: 'Refresh',
                icon: Icons.refresh,
                onPressed: () => ref.read(toolsProvider.notifier).refresh(),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Discover and install MCP servers to extend your agent capabilities',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          if (availableServers.isEmpty) 
            _buildEmptyState(colors)
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: SpacingTokens.lg,
                  crossAxisSpacing: SpacingTokens.lg,
                  childAspectRatio: 1.2,
                ),
                itemCount: availableServers.length,
                itemBuilder: (context, index) {
                  return _buildServerCard(context, ref, colors, availableServers[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 40,
                color: colors.success,
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'All available servers installed',
              style: TextStyles.headlineSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'You have installed all available MCP servers',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard(
    BuildContext context,
    WidgetRef ref,
    ThemeColors colors,
    MCPServer server,
  ) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  ),
                  child: Icon(
                    Icons.extension,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (server.isOfficial)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Text(
                      'OFFICIAL',
                      style: TextStyles.caption.copyWith(
                        color: colors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Text(
                      'COMMUNITY',
                      style: TextStyles.caption.copyWith(
                        color: colors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              server.name,
              style: TextStyles.headlineSmall.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Expanded(
              child: Text(
                server.description,
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            
            // Command preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(
                  color: colors.border.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${server.command} ${server.args.join(' ')}',
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: SpacingTokens.md),
            
            Row(
              children: [
                Expanded(
                  child: AsmblButton.primary(
                    text: 'Install',
                    onPressed: () => _showInstallDialog(context, ref, server),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                IconButton(
                  onPressed: () => _showServerDetails(context, ref, server),
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'View details',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInstallDialog(BuildContext context, WidgetRef ref, MCPServer server) {
    final colors = ThemeColors(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Install MCP Server',
          style: TextStyle(color: colors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Install "${server.name}"?',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              server.description,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(
                  color: colors.border.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Command:',
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    '${server.command} ${server.args.join(' ')}',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurface,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          AsmblButton.primary(
            text: 'Install',
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(toolsProvider.notifier).installServer(server.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Installing ${server.name}...'),
                  backgroundColor: colors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showServerDetails(BuildContext context, WidgetRef ref, MCPServer server) {
    final colors = ThemeColors(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Row(
          children: [
            Expanded(
              child: Text(
                server.name,
                style: TextStyle(color: colors.onSurface),
              ),
            ),
            if (server.isOfficial)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  'OFFICIAL',
                  style: TextStyles.caption.copyWith(
                    color: colors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                server.description,
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: SpacingTokens.lg),
              
              Text(
                'Installation Command',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(
                    color: colors.border.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${server.command} ${server.args.join(' ')}',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              
              const SizedBox(height: SpacingTokens.lg),
              Text(
                'Category',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                server.isOfficial ? 'Official MCP Server' : 'Community Contributed',
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actions: [
          AsmblButton.secondary(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AsmblButton.primary(
            text: 'Install',
            onPressed: () {
              Navigator.of(context).pop();
              _showInstallDialog(context, ref, server);
            },
          ),
        ],
      ),
    );
  }
}