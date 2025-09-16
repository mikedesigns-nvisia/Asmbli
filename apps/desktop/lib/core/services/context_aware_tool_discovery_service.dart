import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_catalog_entry.dart';
import 'mcp_catalog_service.dart';
import 'production_logger.dart';

/// Service for discovering and recommending MCP tools based on project context
class ContextAwareToolDiscoveryService {
  final MCPCatalogService _catalogService;
  final Map<String, ProjectContext> _projectContextCache = {};
  final Map<String, List<String>> _agentRecommendations = {};

  ContextAwareToolDiscoveryService(this._catalogService);

  /// Detect project context and recommend appropriate MCP tools
  Future<ToolRecommendations> discoverToolsForProject(String projectPath) async {
    try {
      ProductionLogger.instance.info(
        'Discovering tools for project',
        data: {'project_path': projectPath},
        category: 'tool_discovery',
      );

      // Detect project context
      final context = await _detectProjectContext(projectPath);
      
      // Cache the context
      _projectContextCache[projectPath] = context;

      // Get tool recommendations based on context
      final recommendations = await _getRecommendationsForContext(context);

      ProductionLogger.instance.info(
        'Tool discovery completed',
        data: {
          'project_path': projectPath,
          'detected_types': context.projectTypes,
          'recommended_tools': recommendations.recommended.map((t) => t.id).toList(),
          'optional_tools': recommendations.optional.map((t) => t.id).toList(),
        },
        category: 'tool_discovery',
      );

      return recommendations;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to discover tools for project',
        error: e,
        data: {'project_path': projectPath},
        category: 'tool_discovery',
      );
      rethrow;
    }
  }

  /// Get tool recommendations for agent based on working directory
  Future<ToolRecommendations> getToolRecommendationsForAgent(
    String agentId,
    String workingDirectory,
  ) async {
    try {
      ProductionLogger.instance.info(
        'Getting tool recommendations for agent',
        data: {'agent_id': agentId, 'working_directory': workingDirectory},
        category: 'tool_discovery',
      );

      // Get project context
      final context = await _detectProjectContext(workingDirectory);
      
      // Get recommendations
      final recommendations = await _getRecommendationsForContext(context);
      
      // Cache recommendations for this agent
      _agentRecommendations[agentId] = [
        ...recommendations.recommended.map((t) => t.id),
        ...recommendations.optional.map((t) => t.id),
      ];

      return recommendations;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to get tool recommendations for agent',
        error: e,
        data: {'agent_id': agentId, 'working_directory': workingDirectory},
        category: 'tool_discovery',
      );
      rethrow;
    }
  }

  /// Update tool recommendations when project context changes
  Future<ToolRecommendations> updateRecommendations(
    String agentId,
    String workingDirectory,
  ) async {
    try {
      ProductionLogger.instance.info(
        'Updating tool recommendations for agent',
        data: {'agent_id': agentId, 'working_directory': workingDirectory},
        category: 'tool_discovery',
      );

      // Clear cached context to force re-detection
      _projectContextCache.remove(workingDirectory);
      
      // Get fresh recommendations
      final recommendations = await getToolRecommendationsForAgent(agentId, workingDirectory);
      
      // Compare with previous recommendations
      final previousRecommendations = _agentRecommendations[agentId] ?? [];
      final newRecommendations = [
        ...recommendations.recommended.map((t) => t.id),
        ...recommendations.optional.map((t) => t.id),
      ];
      
      final addedTools = newRecommendations.where((t) => !previousRecommendations.contains(t)).toList();
      final removedTools = previousRecommendations.where((t) => !newRecommendations.contains(t)).toList();
      
      if (addedTools.isNotEmpty || removedTools.isNotEmpty) {
        ProductionLogger.instance.info(
          'Tool recommendations changed',
          data: {
            'agent_id': agentId,
            'added_tools': addedTools,
            'removed_tools': removedTools,
          },
          category: 'tool_discovery',
        );
      }

      return recommendations;
    } catch (e) {
      ProductionLogger.instance.error(
        'Failed to update tool recommendations',
        error: e,
        data: {'agent_id': agentId, 'working_directory': workingDirectory},
        category: 'tool_discovery',
      );
      rethrow;
    }
  }

  /// Detect project context by analyzing files and directories
  Future<ProjectContext> _detectProjectContext(String projectPath) async {
    final directory = Directory(projectPath);
    if (!await directory.exists()) {
      return ProjectContext(
        projectPath: projectPath,
        projectTypes: [ProjectType.unknown],
        detectedFiles: [],
        packageManagers: [],
        frameworks: [],
        languages: [],
      );
    }

    final detectedFiles = <String>[];
    final projectTypes = <ProjectType>{};
    final packageManagers = <PackageManager>{};
    final frameworks = <Framework>{};
    final languages = <ProgrammingLanguage>{};

    try {
      // Scan directory for indicator files
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          detectedFiles.add(fileName);
          
          // Detect project types and technologies
          _analyzeFile(fileName, projectTypes, packageManagers, frameworks, languages);
        }
      }

      // Check for subdirectories that indicate project structure
      await _analyzeDirectoryStructure(directory, projectTypes, frameworks, languages);

      // If no specific type detected, default to filesystem
      if (projectTypes.isEmpty) {
        projectTypes.add(ProjectType.filesystem);
      }

      return ProjectContext(
        projectPath: projectPath,
        projectTypes: projectTypes.toList(),
        detectedFiles: detectedFiles,
        packageManagers: packageManagers.toList(),
        frameworks: frameworks.toList(),
        languages: languages.toList(),
      );
    } catch (e) {
      ProductionLogger.instance.warning(
        'Error analyzing project context',
        data: {'project_path': projectPath, 'error': e.toString()},
        category: 'tool_discovery',
      );
      
      return ProjectContext(
        projectPath: projectPath,
        projectTypes: [ProjectType.filesystem],
        detectedFiles: detectedFiles,
        packageManagers: [],
        frameworks: [],
        languages: [],
      );
    }
  }

  /// Analyze individual file to detect technologies
  void _analyzeFile(
    String fileName,
    Set<ProjectType> projectTypes,
    Set<PackageManager> packageManagers,
    Set<Framework> frameworks,
    Set<ProgrammingLanguage> languages,
  ) {
    // Git repository
    if (fileName == '.git' || fileName == '.gitignore') {
      projectTypes.add(ProjectType.git);
    }

    // Node.js projects
    if (fileName == 'package.json') {
      projectTypes.add(ProjectType.nodejs);
      packageManagers.add(PackageManager.npm);
      languages.add(ProgrammingLanguage.javascript);
    }
    if (fileName == 'package-lock.json') {
      packageManagers.add(PackageManager.npm);
    }
    if (fileName == 'yarn.lock') {
      packageManagers.add(PackageManager.yarn);
    }
    if (fileName == 'pnpm-lock.yaml') {
      packageManagers.add(PackageManager.pnpm);
    }

    // Python projects
    if (fileName == 'requirements.txt' || fileName == 'setup.py' || fileName == 'pyproject.toml') {
      projectTypes.add(ProjectType.python);
      languages.add(ProgrammingLanguage.python);
      packageManagers.add(PackageManager.pip);
    }
    if (fileName == 'Pipfile') {
      packageManagers.add(PackageManager.pipenv);
    }
    if (fileName == 'poetry.lock') {
      packageManagers.add(PackageManager.poetry);
    }

    // Rust projects
    if (fileName == 'Cargo.toml') {
      projectTypes.add(ProjectType.rust);
      languages.add(ProgrammingLanguage.rust);
      packageManagers.add(PackageManager.cargo);
    }

    // Go projects
    if (fileName == 'go.mod') {
      projectTypes.add(ProjectType.go);
      languages.add(ProgrammingLanguage.go);
      packageManagers.add(PackageManager.gomod);
    }

    // Java/Kotlin projects
    if (fileName == 'pom.xml') {
      projectTypes.add(ProjectType.java);
      languages.add(ProgrammingLanguage.java);
      packageManagers.add(PackageManager.maven);
    }
    if (fileName == 'build.gradle' || fileName == 'build.gradle.kts') {
      projectTypes.add(ProjectType.java);
      packageManagers.add(PackageManager.gradle);
    }

    // Database files
    if (fileName.endsWith('.db') || fileName.endsWith('.sqlite') || fileName.endsWith('.sqlite3')) {
      projectTypes.add(ProjectType.database);
    }

    // Docker
    if (fileName == 'Dockerfile' || fileName == 'docker-compose.yml' || fileName == 'docker-compose.yaml') {
      projectTypes.add(ProjectType.docker);
    }

    // Web frameworks
    if (fileName == 'next.config.js' || fileName == 'next.config.ts') {
      frameworks.add(Framework.nextjs);
    }
    if (fileName == 'nuxt.config.js' || fileName == 'nuxt.config.ts') {
      frameworks.add(Framework.nuxtjs);
    }
    if (fileName == 'angular.json') {
      frameworks.add(Framework.angular);
    }
    if (fileName == 'vue.config.js') {
      frameworks.add(Framework.vue);
    }

    // Configuration files
    if (fileName == 'tsconfig.json') {
      languages.add(ProgrammingLanguage.typescript);
    }
  }

  /// Analyze directory structure for additional context
  Future<void> _analyzeDirectoryStructure(
    Directory directory,
    Set<ProjectType> projectTypes,
    Set<Framework> frameworks,
    Set<ProgrammingLanguage> languages,
  ) async {
    try {
      final subdirs = <String>[];
      await for (final entity in directory.list(recursive: false)) {
        if (entity is Directory) {
          final dirName = entity.path.split(Platform.pathSeparator).last;
          subdirs.add(dirName);
        }
      }

      // Check for common directory patterns
      if (subdirs.contains('src') || subdirs.contains('lib')) {
        // Likely a source code project
      }
      
      if (subdirs.contains('node_modules')) {
        projectTypes.add(ProjectType.nodejs);
      }
      
      if (subdirs.contains('venv') || subdirs.contains('.venv') || subdirs.contains('env')) {
        projectTypes.add(ProjectType.python);
      }
      
      if (subdirs.contains('target') && projectTypes.contains(ProjectType.rust)) {
        // Rust project with build artifacts
      }
      
      if (subdirs.contains('.git')) {
        projectTypes.add(ProjectType.git);
      }
    } catch (e) {
      // Ignore errors in directory analysis
    }
  }

  /// Get tool recommendations based on detected project context
  Future<ToolRecommendations> _getRecommendationsForContext(ProjectContext context) async {
    final recommended = <MCPCatalogEntry>[];
    final optional = <MCPCatalogEntry>[];
    final allTools = _catalogService.getAllCatalogEntries();

    // Always recommend filesystem tools
    _addToolIfExists(allTools, 'filesystem', recommended);

    // Git repository tools
    if (context.projectTypes.contains(ProjectType.git)) {
      _addToolIfExists(allTools, 'git', recommended);
      _addToolIfExists(allTools, 'github', optional);
    }

    // Node.js tools
    if (context.projectTypes.contains(ProjectType.nodejs)) {
      _addToolIfExists(allTools, 'npm', recommended);
      _addToolIfExists(allTools, 'node', recommended);
      
      if (context.packageManagers.contains(PackageManager.yarn)) {
        _addToolIfExists(allTools, 'yarn', optional);
      }
      if (context.packageManagers.contains(PackageManager.pnpm)) {
        _addToolIfExists(allTools, 'pnpm', optional);
      }
    }

    // Python tools
    if (context.projectTypes.contains(ProjectType.python)) {
      _addToolIfExists(allTools, 'python', recommended);
      _addToolIfExists(allTools, 'pip', recommended);
      
      if (context.packageManagers.contains(PackageManager.poetry)) {
        _addToolIfExists(allTools, 'poetry', optional);
      }
      if (context.packageManagers.contains(PackageManager.pipenv)) {
        _addToolIfExists(allTools, 'pipenv', optional);
      }
    }

    // Database tools
    if (context.projectTypes.contains(ProjectType.database)) {
      _addToolIfExists(allTools, 'sqlite', recommended);
      _addToolIfExists(allTools, 'postgres', optional);
      _addToolIfExists(allTools, 'mysql', optional);
    }

    // Docker tools
    if (context.projectTypes.contains(ProjectType.docker)) {
      _addToolIfExists(allTools, 'docker', recommended);
    }

    // Web development tools
    if (context.frameworks.contains(Framework.nextjs)) {
      _addToolIfExists(allTools, 'nextjs', optional);
    }
    if (context.frameworks.contains(Framework.vue)) {
      _addToolIfExists(allTools, 'vue', optional);
    }
    if (context.frameworks.contains(Framework.angular)) {
      _addToolIfExists(allTools, 'angular', optional);
    }

    // Language-specific tools
    if (context.languages.contains(ProgrammingLanguage.typescript)) {
      _addToolIfExists(allTools, 'typescript', optional);
    }
    if (context.languages.contains(ProgrammingLanguage.rust)) {
      _addToolIfExists(allTools, 'cargo', recommended);
      _addToolIfExists(allTools, 'rust', optional);
    }
    if (context.languages.contains(ProgrammingLanguage.go)) {
      _addToolIfExists(allTools, 'go', recommended);
    }

    // Always suggest some useful general tools
    _addToolIfExists(allTools, 'web-search', optional);
    _addToolIfExists(allTools, 'http-client', optional);

    return ToolRecommendations(
      context: context,
      recommended: recommended,
      optional: optional,
      timestamp: DateTime.now(),
    );
  }

  /// Helper to add tool if it exists in catalog
  void _addToolIfExists(List<MCPCatalogEntry> allTools, String toolId, List<MCPCatalogEntry> targetList) {
    final tool = allTools.where((t) => t.id == toolId).firstOrNull;
    if (tool != null && !targetList.contains(tool)) {
      targetList.add(tool);
    }
  }

  /// Get cached project context
  ProjectContext? getCachedProjectContext(String projectPath) {
    return _projectContextCache[projectPath];
  }

  /// Get cached recommendations for agent
  List<String>? getCachedRecommendations(String agentId) {
    return _agentRecommendations[agentId];
  }

  /// Clear cache for project
  void clearProjectCache(String projectPath) {
    _projectContextCache.remove(projectPath);
  }

  /// Clear cache for agent
  void clearAgentCache(String agentId) {
    _agentRecommendations.remove(agentId);
  }

  /// Dispose and cleanup
  void dispose() {
    _projectContextCache.clear();
    _agentRecommendations.clear();
    
    ProductionLogger.instance.info(
      'Context-aware tool discovery service disposed',
      category: 'tool_discovery',
    );
  }
}

/// Project context detected from file system analysis
class ProjectContext {
  final String projectPath;
  final List<ProjectType> projectTypes;
  final List<String> detectedFiles;
  final List<PackageManager> packageManagers;
  final List<Framework> frameworks;
  final List<ProgrammingLanguage> languages;

  const ProjectContext({
    required this.projectPath,
    required this.projectTypes,
    required this.detectedFiles,
    required this.packageManagers,
    required this.frameworks,
    required this.languages,
  });

  /// Check if project has specific type
  bool hasProjectType(ProjectType type) => projectTypes.contains(type);

  /// Check if project uses specific package manager
  bool usesPackageManager(PackageManager manager) => packageManagers.contains(manager);

  /// Check if project uses specific framework
  bool usesFramework(Framework framework) => frameworks.contains(framework);

  /// Check if project uses specific language
  bool usesLanguage(ProgrammingLanguage language) => languages.contains(language);
}

/// Tool recommendations based on project context
class ToolRecommendations {
  final ProjectContext context;
  final List<MCPCatalogEntry> recommended;
  final List<MCPCatalogEntry> optional;
  final DateTime timestamp;

  const ToolRecommendations({
    required this.context,
    required this.recommended,
    required this.optional,
    required this.timestamp,
  });

  /// Get all recommended tool IDs
  List<String> get allRecommendedIds => [
    ...recommended.map((t) => t.id),
    ...optional.map((t) => t.id),
  ];

  /// Get only essential tool IDs
  List<String> get essentialIds => recommended.map((t) => t.id).toList();
}

/// Types of projects that can be detected
enum ProjectType {
  unknown,
  filesystem,
  git,
  nodejs,
  python,
  rust,
  go,
  java,
  database,
  docker,
  web,
}

/// Package managers that can be detected
enum PackageManager {
  npm,
  yarn,
  pnpm,
  pip,
  pipenv,
  poetry,
  cargo,
  gomod,
  maven,
  gradle,
}

/// Web frameworks that can be detected
enum Framework {
  nextjs,
  nuxtjs,
  vue,
  angular,
  react,
  svelte,
  django,
  flask,
  fastapi,
  express,
}

/// Programming languages that can be detected
enum ProgrammingLanguage {
  javascript,
  typescript,
  python,
  rust,
  go,
  java,
  kotlin,
  csharp,
  cpp,
  c,
}

/// Exception for tool discovery errors
class ToolDiscoveryException implements Exception {
  final String message;
  
  ToolDiscoveryException(this.message);

  @override
  String toString() => 'ToolDiscoveryException: $message';
}

// ==================== Riverpod Provider ====================

final contextAwareToolDiscoveryServiceProvider = Provider<ContextAwareToolDiscoveryService>((ref) {
  final catalogService = ref.read(mcpCatalogServiceProvider);
  return ContextAwareToolDiscoveryService(catalogService);
});