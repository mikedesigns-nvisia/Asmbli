import '../models/mcp_catalog_entry.dart';
import 'featured_mcp_servers_service.dart';
import 'mcp_catalog_service.dart';

/// Service for recommending MCP servers/tools based on agent categories
class AgentToolRecommendationService {
  final FeaturedMCPServersService _featuredService;
  final MCPCatalogService _catalogService;

  AgentToolRecommendationService(this._featuredService, this._catalogService);

  /// Category-to-server mappings for tool recommendations
  static const Map<String, List<String>> _categoryRecommendations = {
    'Research': [
      'mcp-server-brave-search',
      'mcp-server-memory',
      'mcp-server-filesystem',
      'mcp-server-fetch',
      'markitdown',
    ],
    'Development': [
      'github-mcp-server',
      'mcp-server-git',
      'mcp-server-filesystem',
      'mcp-server-memory',
      'playwright-mcp',
      'mcp-server-puppeteer',
    ],
    'Data Analysis': [
      'mcp-server-postgres',
      'mcp-server-sqlite',
      'mongodb-mcp',
      'mcp-server-memory',
      'mcp-server-filesystem',
    ],
    'Writing': [
      'mcp-server-brave-search',
      'mcp-server-fetch',
      'markitdown',
      'mcp-server-memory',
      'mcp-server-filesystem',
    ],
    'Automation': [
      'playwright-mcp',
      'mcp-server-puppeteer',
      'mcp-server-fetch',
      'mcp-server-memory',
      'mcp-server-filesystem',
    ],
    'DevOps': [
      'azure-mcp',
      'azure-devops-mcp',
      'terraform-mcp',
      'mcp-server-git',
      'mcp-server-memory',
    ],
    'Business': [
      'mcp-server-memory',
      'mcp-server-filesystem',
      'markitdown',
      'mcp-server-fetch',
    ],
    'Education': [
      'mcp-server-memory',
      'mcp-server-filesystem',
      'mcp-server-brave-search',
      'markitdown',
    ],
    'Content Creation': [
      'mcp-server-brave-search',
      'markitdown',
      'mcp-server-fetch',
      'mcp-server-memory',
      'mcp-server-filesystem',
    ],
    'Customer Support': [
      'mcp-server-memory',
      'mcp-server-filesystem',
      'mcp-server-fetch',
    ],
  };

  /// Get recommended MCP servers for a given category
  Future<List<MCPCatalogEntry>> getRecommendedToolsForCategory(String category) async {
    final recommendedIds = _categoryRecommendations[category] ?? [];

    if (recommendedIds.isEmpty) {
      // Fallback to basic tools for unknown categories
      return await _getBasicRecommendations();
    }

    final allEntries = await _catalogService.getAllEntries();
    final recommendations = <MCPCatalogEntry>[];

    // Get recommended servers in order of preference
    for (final serverId in recommendedIds) {
      final entry = allEntries.cast<MCPCatalogEntry?>().firstWhere(
        (e) => e?.id == serverId,
        orElse: () => null,
      );
      if (entry != null) {
        recommendations.add(entry);
      }
    }

    return recommendations;
  }

  /// Get basic tool recommendations for unknown categories
  Future<List<MCPCatalogEntry>> _getBasicRecommendations() async {
    const basicTools = [
      'mcp-server-memory',
      'mcp-server-filesystem',
      'mcp-server-brave-search',
    ];

    final allEntries = await _catalogService.getAllEntries();
    final recommendations = <MCPCatalogEntry>[];

    for (final serverId in basicTools) {
      final entry = allEntries.cast<MCPCatalogEntry?>().firstWhere(
        (e) => e?.id == serverId,
        orElse: () => null,
      );
      if (entry != null) {
        recommendations.add(entry);
      }
    }

    return recommendations;
  }

  /// Get all available categories that have recommendations
  List<String> getAvailableCategories() {
    return _categoryRecommendations.keys.toList();
  }

  /// Get category description for UI display
  String getCategoryDescription(String category) {
    switch (category) {
      case 'Research':
        return 'Academic research with citation management and fact-checking';
      case 'Development':
        return 'Code review, Git operations, and software development';
      case 'Data Analysis':
        return 'Statistical analysis and database operations';
      case 'Writing':
        return 'SEO-optimized content generation and editing';
      case 'Automation':
        return 'Browser automation and web scraping';
      case 'DevOps':
        return 'Infrastructure management and cloud operations';
      case 'Business':
        return 'Business analysis and document management';
      case 'Education':
        return 'Educational content and knowledge management';
      case 'Content Creation':
        return 'Media creation and content optimization';
      case 'Customer Support':
        return 'Customer service and support automation';
      default:
        return 'General purpose agent with basic capabilities';
    }
  }

  /// Get recommended tool count for category (for UI display)
  int getRecommendedToolCount(String category) {
    return _categoryRecommendations[category]?.length ?? 0;
  }
}