import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/services/agent_tool_recommendation_service.dart';
import '../../../../core/services/featured_mcp_servers_service.dart';
import '../../../../core/services/mcp_catalog_service.dart';

/// Provider for the tool recommendation service
final toolRecommendationServiceProvider = Provider<AgentToolRecommendationService>((ref) {
  final featuredService = FeaturedMCPServersService();
  final catalogService = ref.read(mcpCatalogServiceProvider);
  return AgentToolRecommendationService(featuredService, catalogService);
});

/// Widget that shows recommended tools based on agent category
class RecommendedToolsWidget extends ConsumerStatefulWidget {
  final String category;
  final Function(MCPCatalogEntry)? onToolSelected;

  const RecommendedToolsWidget({
    super.key,
    required this.category,
    this.onToolSelected,
  });

  @override
  ConsumerState<RecommendedToolsWidget> createState() => _RecommendedToolsWidgetState();
}

class _RecommendedToolsWidgetState extends ConsumerState<RecommendedToolsWidget> {
  List<MCPCatalogEntry> _recommendations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void didUpdateWidget(RecommendedToolsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(toolRecommendationServiceProvider);
      final recommendations = await service.getRecommendedToolsForCategory(widget.category);

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final service = ref.read(toolRecommendationServiceProvider);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colors.error,
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'Failed to load recommendations',
              style: TextStyles.bodyMedium.copyWith(color: colors.error),
            ),
            const SizedBox(height: SpacingTokens.sm),
            AsmblButton.secondary(
              text: 'Retry',
              onPressed: _loadRecommendations,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header with description
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(widget.category),
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    'Recommended for ${widget.category}',
                    style: TextStyles.titleMedium.copyWith(color: colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                service.getCategoryDescription(widget.category),
                style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),

        const SizedBox(height: SpacingTokens.md),

        // Recommended tools grid
        if (_recommendations.isEmpty)
          Center(
            child: Text(
              'No recommendations available for this category',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: SpacingTokens.md,
                mainAxisSpacing: SpacingTokens.md,
                childAspectRatio: 1.2,
              ),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final tool = _recommendations[index];
                return _buildToolCard(tool, colors);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildToolCard(MCPCatalogEntry tool, ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        onTap: () => widget.onToolSelected?.call(tool),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and featured badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.xs),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Icon(
                      Icons.extension,
                      size: 16,
                      color: colors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (tool.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                      ),
                      child: Text(
                        'FEATURED',
                        style: TextStyles.caption.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: SpacingTokens.sm),

              // Tool name
              Text(
                tool.name,
                style: TextStyles.titleSmall.copyWith(color: colors.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: SpacingTokens.xs),

              // Tool description
              Expanded(
                child: Text(
                  tool.description,
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: SpacingTokens.sm),

              // Tags
              if (tool.tags.isNotEmpty)
                Wrap(
                  spacing: SpacingTokens.xs,
                  children: tool.tags.take(2).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                    ),
                    child: Text(
                      tag,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Research':
        return Icons.search;
      case 'Development':
        return Icons.code;
      case 'Data Analysis':
        return Icons.analytics;
      case 'Writing':
        return Icons.edit;
      case 'Automation':
        return Icons.smart_toy;
      case 'DevOps':
        return Icons.cloud;
      case 'Business':
        return Icons.business;
      case 'Education':
        return Icons.school;
      case 'Content Creation':
        return Icons.create;
      case 'Customer Support':
        return Icons.support_agent;
      default:
        return Icons.category;
    }
  }
}