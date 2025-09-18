/// Categories for organizing MCP servers
enum MCPServerCategory {
  development('Development', 'Tools for software development'),
  productivity('Productivity', 'Tools for enhancing productivity'),
  communication('Communication', 'Communication and collaboration tools'),
  dataAnalysis('Data Analysis', 'Data processing and analysis tools'),
  automation('Automation', 'Task automation and workflow tools'),
  fileManagement('File Management', 'File and document management'),
  webServices('Web Services', 'Web APIs and online services'),
  cloud('Cloud', 'Cloud services and infrastructure'),
  database('Database', 'Database and data storage tools'),
  security('Security', 'Security and authentication tools'),
  monitoring('Monitoring', 'System monitoring and alerting'),
  ai('AI & ML', 'Artificial Intelligence and Machine Learning'),
  utility('Utility', 'General utility tools'),
  experimental('Experimental', 'Experimental and beta tools'),
  custom('Custom', 'Custom and user-defined tools');

  const MCPServerCategory(this.displayName, this.description);

  final String displayName;
  final String description;

  /// Get category by name (case-insensitive)
  static MCPServerCategory? fromName(String name) {
    final normalizedName = name.toLowerCase().trim();
    for (final category in MCPServerCategory.values) {
      if (category.name.toLowerCase() == normalizedName ||
          category.displayName.toLowerCase() == normalizedName) {
        return category;
      }
    }
    return null;
  }

  /// Get all category names
  static List<String> get allNames =>
      MCPServerCategory.values.map((c) => c.name).toList();

  /// Get all display names
  static List<String> get allDisplayNames =>
      MCPServerCategory.values.map((c) => c.displayName).toList();

  /// Check if this is a system category (not custom)
  bool get isSystemCategory => this != MCPServerCategory.custom;

  /// Get icon data for this category
  String get iconName {
    switch (this) {
      case MCPServerCategory.development:
        return 'code';
      case MCPServerCategory.productivity:
        return 'trending_up';
      case MCPServerCategory.communication:
        return 'chat';
      case MCPServerCategory.dataAnalysis:
        return 'analytics';
      case MCPServerCategory.automation:
        return 'auto_awesome';
      case MCPServerCategory.fileManagement:
        return 'folder';
      case MCPServerCategory.webServices:
        return 'language';
      case MCPServerCategory.cloud:
        return 'cloud';
      case MCPServerCategory.database:
        return 'storage';
      case MCPServerCategory.security:
        return 'security';
      case MCPServerCategory.monitoring:
        return 'monitor';
      case MCPServerCategory.ai:
        return 'psychology';
      case MCPServerCategory.utility:
        return 'build';
      case MCPServerCategory.experimental:
        return 'science';
      case MCPServerCategory.custom:
        return 'extension';
    }
  }

  /// Get color for this category
  String get colorHex {
    switch (this) {
      case MCPServerCategory.development:
        return '#2196F3'; // Blue
      case MCPServerCategory.productivity:
        return '#4CAF50'; // Green
      case MCPServerCategory.communication:
        return '#FF9800'; // Orange
      case MCPServerCategory.dataAnalysis:
        return '#9C27B0'; // Purple
      case MCPServerCategory.automation:
        return '#607D8B'; // Blue Grey
      case MCPServerCategory.fileManagement:
        return '#795548'; // Brown
      case MCPServerCategory.webServices:
        return '#00BCD4'; // Cyan
      case MCPServerCategory.cloud:
        return '#2196F3'; // Light Blue
      case MCPServerCategory.database:
        return '#3F51B5'; // Indigo
      case MCPServerCategory.security:
        return '#F44336'; // Red
      case MCPServerCategory.monitoring:
        return '#FFEB3B'; // Yellow
      case MCPServerCategory.ai:
        return '#E91E63'; // Pink
      case MCPServerCategory.utility:
        return '#9E9E9E'; // Grey
      case MCPServerCategory.experimental:
        return '#FF5722'; // Deep Orange
      case MCPServerCategory.custom:
        return '#673AB7'; // Deep Purple
    }
  }
}