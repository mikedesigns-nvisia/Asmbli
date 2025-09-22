import 'package:flutter/material.dart';
import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/data/mcp_server_configs.dart';
import 'universal_integration_card.dart';


import '../../../../../core/models/mcp_server_config.dart';

/// Integration Cards Grid - Main content area showing all integration cards
/// Responsive grid that adapts to screen size and filters
class IntegrationCardsGrid extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;

  const IntegrationCardsGrid({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final filteredIntegrations = _getFilteredIntegrations();

    if (filteredIntegrations.isEmpty) {
      return _buildEmptyState(colors);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results Header
          if (searchQuery.isNotEmpty || selectedCategory != 'all')
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
              child: Text(
                _buildResultsText(filteredIntegrations.length),
                style: TextStyles.bodyLarge.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          // Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.4, // Width/Height ratio for cards
                  crossAxisSpacing: SpacingTokens.componentSpacing,
                  mainAxisSpacing: SpacingTokens.componentSpacing,
                ),
                itemCount: filteredIntegrations.length,
                itemBuilder: (context, index) {
                  final integration = filteredIntegrations[index];
                  return UniversalIntegrationCard(
                    integration: integration,
                    onPrimaryAction: () => _handlePrimaryAction(integration),
                    onSecondaryAction: () => _handleSecondaryAction(integration),
                  );
                },
              );
            },
          ),
          
          // Load More Button (if more integrations available)
          if (_hasMoreIntegrations())
            Padding(
              padding: const EdgeInsets.only(top: SpacingTokens.sectionSpacing),
              child: Center(
                child: AsmblButton.secondary(
                  text: 'Show more integrations',
                  icon: Icons.expand_more,
                  onPressed: _loadMoreIntegrations,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    final isSearching = searchQuery.isNotEmpty;
    final isFiltering = selectedCategory != 'all';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.hub_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: SpacingTokens.sectionSpacing),
            Text(
              isSearching 
                ? 'No integrations found'
                : isFiltering 
                  ? 'No integrations in this category'
                  : 'No integrations available',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              isSearching
                ? 'Try different search terms or browse categories'
                : isFiltering
                  ? 'Try selecting a different category'
                  : 'Integration marketplace will be available soon',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (isSearching || isFiltering) ...[
              const SizedBox(height: SpacingTokens.sectionSpacing),
              AsmblButton.secondary(
                text: isSearching ? 'Clear search' : 'Show all categories',
                onPressed: _clearFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildResultsText(int count) {
    final categoryText = selectedCategory != 'all' 
        ? ' in ${selectedCategory.replaceAll('_', ' ')}'
        : '';
    final searchText = searchQuery.isNotEmpty 
        ? ' for "$searchQuery"'
        : '';
    
    return '$count integration${count != 1 ? 's' : ''}$searchText$categoryText';
  }

  int _calculateCrossAxisCount(double width) {
    // Responsive grid: more columns for wider screens
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 600) return 2;
    return 1;
  }

  List<IntegrationCardData> _getFilteredIntegrations() {
    var integrations = _getAllIntegrations();
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      integrations = integrations.where((integration) =>
        integration.name.toLowerCase().contains(query) ||
        integration.description.toLowerCase().contains(query)
      ).toList();
    }
    
    // Filter by category
    if (selectedCategory != 'all') {
      integrations = integrations.where((integration) =>
        integration.category == selectedCategory
      ).toList();
    }
    
    // Sort by status priority (configured/active first, then available)
    integrations.sort((a, b) {
      final statusPriority = {
        IntegrationStatus.active: 0,
        IntegrationStatus.configured: 1,
        IntegrationStatus.needsAttention: 2,
        IntegrationStatus.installing: 3,
        IntegrationStatus.error: 4,
        IntegrationStatus.available: 5,
      };
      
      final priorityA = statusPriority[a.status] ?? 5;
      final priorityB = statusPriority[b.status] ?? 5;
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      // Secondary sort by rating for same status
      return b.rating.compareTo(a.rating);
    });
    
    return integrations;
  }

  List<IntegrationCardData> _getAllIntegrations() {
    // Load from MCP Server configuration library
    return MCPServerLibrary.servers.map((mcpServer) {
      return IntegrationCardData(
        id: mcpServer.id,
        name: mcpServer.name,
        description: mcpServer.description,
        icon: _getIconForServer(mcpServer),
        brandColor: _getBrandColorForServer(mcpServer),
        status: _getStatusForServer(mcpServer),
        category: _getCategoryForServer(mcpServer),
        rating: _getRatingForServer(mcpServer),
      );
    }).toList();
  }

  IconData _getIconForServer(MCPServerLibraryConfig server) {
    // Map server capabilities to appropriate icons
    if (server.capabilities.contains('git_log') || server.capabilities.contains('repository_search')) {
      return Icons.code;
    } else if (server.capabilities.contains('database_queries') || server.capabilities.contains('data_querying')) {
      return Icons.storage;
    } else if (server.capabilities.contains('web_fetching') || server.capabilities.contains('web_automation')) {
      return Icons.web;
    } else if (server.capabilities.contains('file_read') || server.capabilities.contains('file_operations')) {
      return Icons.folder;
    } else if (server.capabilities.contains('messaging') || server.capabilities.contains('channel_operations')) {
      return Icons.chat;
    } else if (server.capabilities.contains('payment_processing') || server.capabilities.contains('billing_monitoring')) {
      return Icons.payment;
    } else if (server.capabilities.contains('cloud') || server.capabilities.contains('infrastructure_as_code')) {
      return Icons.cloud;
    } else if (server.capabilities.contains('error_tracking') || server.capabilities.contains('security_scanning')) {
      return Icons.security;
    } else if (server.capabilities.contains('build_monitoring') || server.capabilities.contains('pipeline_management')) {
      return Icons.build;
    } else if (server.capabilities.contains('analytics') || server.capabilities.contains('data_visualization')) {
      return Icons.analytics;
    } else if (server.capabilities.contains('design_file_access') || server.capabilities.contains('component_data')) {
      return Icons.design_services;
    } else if (server.capabilities.contains('calendar_management') || server.capabilities.contains('scheduling')) {
      return Icons.calendar_today;
    } else {
      return Icons.hub;
    }
  }

  Color _getBrandColorForServer(MCPServerLibraryConfig server) {
    // Map server names to brand colors
    switch (server.id) {
      case 'github': return const Color(0xFF24292F);
      case 'slack': return const Color(0xFF4A154B);
      case 'notion': return const Color(0xFF000000);
      case 'postgresql': return const Color(0xFF336791);
      case 'aws-bedrock':
      case 'aws-cdk':
      case 'aws-cost-analysis': return const Color(0xFFFF9900);
      case 'cloudflare': return const Color(0xFFF38020);
      case 'vercel': return const Color(0xFF000000);
      case 'netlify': return const Color(0xFF00AD9F);
      case 'stripe': return const Color(0xFF635BFF);
      case 'twilio': return const Color(0xFFE1282A);
      case 'discord': return const Color(0xFF5865F2);
      case 'figma-official': return const Color(0xFFF24E1E);
      case 'linear': return const Color(0xFF5E6AD2);
      case 'sentry': return const Color(0xFF362D59);
      case 'docker': return const Color(0xFF2496ED);
      case 'supabase': return const Color(0xFF3ECF8E);
      case 'redis': return const Color(0xFFDC382D);
      case 'zapier': return const Color(0xFFFF4F00);
      case 'box': return const Color(0xFF0061D5);
      default: return const Color(0xFF6B46C1); // Default purple
    }
  }

  IntegrationStatus _getStatusForServer(MCPServerLibraryConfig server) {
    // Map server status to integration status
    switch (server.status) {
      case MCPServerStatus.stable:
        return IntegrationStatus.available;
      case MCPServerStatus.beta:
        return IntegrationStatus.available;
      case MCPServerStatus.alpha:
        return IntegrationStatus.available;
      case MCPServerStatus.deprecated:
        return IntegrationStatus.error;
      default:
        return IntegrationStatus.available;
    }
  }

  String _getCategoryForServer(MCPServerLibraryConfig server) {
    // Map server types and capabilities to categories
    if (server.type == MCPServerType.official) {
      if (server.capabilities.any((cap) => ['git_log', 'repository_search', 'code_review'].contains(cap))) {
        return 'development';
      } else if (server.capabilities.any((cap) => ['database_queries', 'data_querying'].contains(cap))) {
        return 'data';
      } else if (server.capabilities.any((cap) => ['web_fetching', 'content_conversion'].contains(cap))) {
        return 'web';
      }
    }
    
    // Developer tools
    if (server.capabilities.any((cap) => ['pipeline_management', 'build_monitoring', 'error_tracking', 'security_scanning'].contains(cap))) {
      return 'development';
    }
    
    // Cloud & Infrastructure
    if (server.capabilities.any((cap) => ['infrastructure_as_code', 'cloud', 'storage_management'].contains(cap))) {
      return 'cloud';
    }
    
    // Database & Data
    if (server.capabilities.any((cap) => ['database_operations', 'analytics', 'data_visualization'].contains(cap))) {
      return 'data';
    }
    
    // Communication
    if (server.capabilities.any((cap) => ['messaging', 'channel_operations', 'team_collaboration'].contains(cap))) {
      return 'communication';
    }
    
    // Business & Productivity
    if (server.capabilities.any((cap) => ['payment_processing', 'workflow_automation', 'content_management'].contains(cap))) {
      return 'productivity';
    }
    
    return 'other';
  }

  double _getRatingForServer(MCPServerLibraryConfig server) {
    // Generate ratings based on server type and status
    if (server.type == MCPServerType.official) {
      return 4.8 + (server.id.hashCode % 3) * 0.1; // 4.8-4.9 for official
    } else if (server.status == MCPServerStatus.stable) {
      return 4.3 + (server.id.hashCode % 5) * 0.1; // 4.3-4.7 for stable community
    } else if (server.status == MCPServerStatus.beta) {
      return 4.0 + (server.id.hashCode % 3) * 0.1; // 4.0-4.2 for beta
    } else {
      return 3.5 + (server.id.hashCode % 5) * 0.1; // 3.5-3.9 for alpha
    }
  }

  void _handlePrimaryAction(IntegrationCardData integration) {
    // Handle primary action based on integration status
    print('Primary action for ${integration.name}: ${integration.status}');
  }

  void _handleSecondaryAction(IntegrationCardData integration) {
    // Handle secondary action (settings, more options, etc.)
    print('Secondary action for ${integration.name}');
  }

  void _clearFilters() {
    // This would be handled by parent widget in real implementation
    print('Clear filters');
  }

  bool _hasMoreIntegrations() {
    // In real app, check if there are more integrations to load
    return false;
  }

  void _loadMoreIntegrations() {
    // Load more integrations from service
    print('Load more integrations');
  }
}