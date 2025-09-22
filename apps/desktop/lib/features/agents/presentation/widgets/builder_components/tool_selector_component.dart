import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/models/mcp_catalog_entry.dart';
import '../../../../../core/services/mcp_catalog_service.dart';
import '../recommended_tools_widget.dart';
import '../../../models/agent_builder_state.dart';
import '../../screens/agent_builder_screen.dart';

/// Tool Selector Component with smart recommendations and selected tools
class ToolSelectorComponent extends ConsumerWidget {
  const ToolSelectorComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors(context);
    final builderState = ref.watch(agentBuilderStateProvider);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(colors),
            const SizedBox(height: SpacingTokens.sectionSpacing),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Recommended tools
                Expanded(
                  flex: 2,
                  child: _buildRecommendedTools(builderState, colors),
                ),

                const SizedBox(width: SpacingTokens.lg),

                // Right side - Selected tools overview
                Expanded(
                  flex: 1,
                  child: _buildSelectedToolsOverview(builderState, colors),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          ),
          child: Icon(
            Icons.extension,
            color: colors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tool Selection',
              style: TextStyles.titleLarge.copyWith(color: colors.onSurface),
            ),
            Text(
              'Select MCP servers and tools for your agent',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendedTools(AgentBuilderState builderState, ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: colors.accent, size: 20),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Recommended for ${builderState.category}',
                  style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            Text(
              'These tools are specifically recommended for ${builderState.category.toLowerCase()} agents based on common use cases.',
              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: SpacingTokens.lg),

            SizedBox(
              height: 400,
              child: RecommendedToolsWidget(
                category: builderState.category,
                onToolSelected: (tool) {
                  builderState.toggleToolWithEntry(tool);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedToolsOverview(AgentBuilderState builderState, ThemeColors colors) {
    return Column(
      children: [
        // Selected tools summary
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: colors.primary, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Selected Tools',
                      style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),

                Text(
                  '${builderState.selectedTools.length} tools selected',
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.sm),

                if (builderState.selectedTools.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: colors.accent, size: 24),
                        const SizedBox(height: SpacingTokens.sm),
                        Text(
                          'No tools selected yet',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          'Select recommended tools from the left to get started',
                          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Consumer(
                    builder: (context, ref, child) {
                      return FutureBuilder<List<MCPCatalogEntry>>(
                        future: _getSelectedToolDetails(ref, builderState.selectedToolIds),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text(
                              'Loading tool details...',
                              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                            );
                          }

                          return Column(
                            children: snapshot.data!.map((tool) => Padding(
                              padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                              child: Container(
                                padding: const EdgeInsets.all(SpacingTokens.sm),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tool.name,
                                            style: TextStyles.bodySmall.copyWith(
                                              color: colors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (tool.description.isNotEmpty)
                                            Text(
                                              tool.description,
                                              style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline, color: colors.error),
                                      iconSize: 16,
                                      onPressed: () => builderState.toggleToolWithEntry(tool),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    ),
                                  ],
                                ),
                              ),
                            )).toList(),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: SpacingTokens.lg),

        // Tool categories info
        AsmblCard(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, color: colors.accent, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                    Text(
                      'Tool Categories',
                      style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.md),

                ..._getToolCategoryInfo().map((info) => Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Text(
                          info,
                          style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<List<MCPCatalogEntry>> _getSelectedToolDetails(WidgetRef ref, List<String> selectedToolIds) async {
    final mcpCatalogService = ref.read(mcpCatalogServiceProvider);
    final allTools = await mcpCatalogService.getAllEntries();

    return allTools.where((tool) => selectedToolIds.contains(tool.id)).toList();
  }

  List<String> _getToolCategoryInfo() {
    return [
      'File System - Read/write local files',
      'Web Search - Internet search capabilities',
      'APIs - Connect to external services',
      'Development - Code analysis and version control',
      'Data Processing - Transform and analyze data',
    ];
  }
}