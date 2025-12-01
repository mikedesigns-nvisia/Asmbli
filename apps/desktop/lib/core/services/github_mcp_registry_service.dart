import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/github_mcp_registry_models.dart';
import '../models/mcp_catalog_entry.dart';
import 'featured_mcp_servers_service.dart';
import 'github_mcp_registry_client.dart';

/// HTTP client for GitHub MCP Registry API
class GitHubMCPRegistryApi {
  final Dio _dio;
  static const String baseUrl = 'https://registry.modelcontextprotocol.io';

  GitHubMCPRegistryApi(this._dio);

  /// Get all servers from the registry
  Future<List<GitHubMCPRegistryEntry>> getServers({
    String? status,
    int? limit,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (limit != null) queryParams['limit'] = limit;
    if (cursor != null) queryParams['cursor'] = cursor;

    final response = await _dio.get(
      '$baseUrl/v0/servers',
      queryParameters: queryParams,
    );

    final responseData = response.data as Map<String, dynamic>;
    final List<dynamic> servers = responseData['servers'] as List<dynamic>;

    return servers
        .map((json) => GitHubMCPRegistryEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific server by ID
  Future<GitHubMCPRegistryEntry> getServer(String id) async {
    final response = await _dio.get('$baseUrl/v0/servers/$id');
    return GitHubMCPRegistryEntry.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get GitHub repository star count from GitHub API
  Future<int?> getGitHubStarCount(String repositoryUrl) async {
    try {
      // Extract owner/repo from GitHub URL
      final match = RegExp(r'github\.com/([^/]+)/([^/]+)').firstMatch(repositoryUrl);
      if (match == null) return null;

      final owner = match.group(1)!;
      final repo = match.group(2)!.replaceAll('.git', '');

      final response = await _dio.get('https://api.github.com/repos/$owner/$repo');
      final data = response.data as Map<String, dynamic>;
      return data['stargazers_count'] as int?;
    } catch (e) {
      print('[GitHub API] Error fetching star count for $repositoryUrl: $e');
      return null;
    }
  }
}

/// Provider for Dio HTTP client
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  // Add interceptors for logging and error handling
  dio.interceptors.add(LogInterceptor(
    requestHeader: false,
    requestBody: false,
    responseHeader: false,
    responseBody: false,
    logPrint: (obj) {
      // Only log in debug mode
      if (const bool.fromEnvironment('DEBUG_MODE', defaultValue: false)) {
        print('[MCP Registry API] $obj');
      }
    },
  ));

  // Set timeouts
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);

  return dio;
});

/// Provider for GitHub MCP Registry API client
final githubMCPRegistryApiProvider = Provider<GitHubMCPRegistryApi>((ref) {
  final dio = ref.read(dioProvider);
  return GitHubMCPRegistryApi(dio);
});

/// Enhanced error types for better error handling
enum RegistryErrorType {
  networkError,
  parseError,
  serverNotFound,
  rateLimited,
  unauthorized,
  timeout,
  serverError,
  unknown,
}

/// Registry exception with detailed error information
class RegistryException implements Exception {
  final RegistryErrorType type;
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const RegistryException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'RegistryException: $message (Type: $type, Code: $statusCode)';
}

/// Service for managing GitHub MCP Registry integration with comprehensive error handling
class GitHubMCPRegistryService {
  final GitHubMCPRegistryApi _api;
  final FeaturedMCPServersService _featuredServers = FeaturedMCPServersService();
  final GitHubMCPRegistryClient _readmeClient;

  // Cache for registry data
  List<GitHubMCPRegistryEntry>? _cachedServers;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(hours: 1);

  // Error handling and retry configuration
  static const int _maxRetryAttempts = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  static const Duration _maxRetryDelay = Duration(seconds: 30);
  static const Duration _requestTimeout = Duration(seconds: 30);

  // Circuit breaker pattern
  bool _circuitBreakerOpen = false;
  DateTime? _circuitBreakerOpenTime;
  int _consecutiveFailures = 0;
  static const int _circuitBreakerThreshold = 5;
  static const Duration _circuitBreakerCooldown = Duration(minutes: 5);

  GitHubMCPRegistryService(this._api, {GitHubMCPRegistryClient? readmeClient})
      : _readmeClient = readmeClient ?? GitHubMCPRegistryClient();

  /// Get the underlying API client for advanced operations
  GitHubMCPRegistryApi get api => _api;

  /// Get all active servers from the registry with comprehensive error handling
  Future<List<GitHubMCPRegistryEntry>> getAllActiveServers({bool forceRefresh = false}) async {
    // Check circuit breaker
    if (_isCircuitBreakerOpen()) {
      print('[GitHubMCPRegistryService] Circuit breaker is open, using fallback data');
      return _getFallbackServers();
    }

    try {
      // Check cache first
      if (!forceRefresh && _cachedServers != null && _lastCacheTime != null) {
        final cacheAge = DateTime.now().difference(_lastCacheTime!);
        if (cacheAge < _cacheValidDuration) {
          return _cachedServers!.where((server) => server.isActive).toList();
        }
      }

      // Fetch from API with retry logic
      final servers = await _retryOperation(() async {
        return await _api.getServers(status: 'active', limit: 100);
      });

      // Update cache and reset failure count
      _cachedServers = servers;
      _lastCacheTime = DateTime.now();
      _consecutiveFailures = 0;
      _circuitBreakerOpen = false;

      return servers.where((server) => server.isActive).toList();

    } catch (e) {
      _handleError(e);

      // Graceful degradation: return cached data if available
      if (_cachedServers != null) {
        print('[GitHubMCPRegistryService] Using cached data due to API failure');
        return _cachedServers!.where((server) => server.isActive).toList();
      }

      // Try README parsing as fallback before featured servers
      try {
        print('[GitHubMCPRegistryService] API failed, trying README parsing...');
        final readmeServers = await _getServersFromReadme();
        if (readmeServers.isNotEmpty) {
          print('[GitHubMCPRegistryService] Successfully fetched ${readmeServers.length} servers from README');
          // Cache the README results
          _cachedServers = readmeServers;
          _lastCacheTime = DateTime.now();
          return readmeServers;
        }
      } catch (readmeError) {
        print('[GitHubMCPRegistryService] README parsing also failed: $readmeError');
      }

      // Final fallback: return featured servers
      print('[GitHubMCPRegistryService] Using featured servers as final fallback');
      return _getFallbackServers();
    }
  }

  /// Check if circuit breaker is open
  bool _isCircuitBreakerOpen() {
    if (!_circuitBreakerOpen) return false;

    // Check if cooldown period has passed
    if (_circuitBreakerOpenTime != null) {
      final timeSinceOpen = DateTime.now().difference(_circuitBreakerOpenTime!);
      if (timeSinceOpen > _circuitBreakerCooldown) {
        _circuitBreakerOpen = false;
        _consecutiveFailures = 0;
        return false;
      }
    }

    return true;
  }

  /// Handle errors and update circuit breaker state
  void _handleError(dynamic error) {
    _consecutiveFailures++;

    if (_consecutiveFailures >= _circuitBreakerThreshold) {
      _circuitBreakerOpen = true;
      _circuitBreakerOpenTime = DateTime.now();
      print('[GitHubMCPRegistryService] Circuit breaker opened after $_consecutiveFailures consecutive failures');
    }

    // Log detailed error information
    if (error is DioException) {
      final registryError = _mapDioError(error);
      print('[GitHubMCPRegistryService] ${registryError.type}: ${registryError.message}');
    } else {
      print('[GitHubMCPRegistryService] Unexpected error: $error');
    }
  }

  /// Map Dio errors to registry errors
  RegistryException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return RegistryException(
          type: RegistryErrorType.timeout,
          message: 'Request timeout: ${error.message}',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return RegistryException(
          type: RegistryErrorType.networkError,
          message: 'Network connection failed: ${error.message}',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 401:
            return RegistryException(
              type: RegistryErrorType.unauthorized,
              message: 'Unauthorized access to registry',
              statusCode: statusCode,
              originalError: error,
            );
          case 404:
            return RegistryException(
              type: RegistryErrorType.serverNotFound,
              message: 'Registry endpoint not found',
              statusCode: statusCode,
              originalError: error,
            );
          case 429:
            return RegistryException(
              type: RegistryErrorType.rateLimited,
              message: 'Rate limit exceeded',
              statusCode: statusCode,
              originalError: error,
            );
          case 500:
          case 502:
          case 503:
          case 504:
            return RegistryException(
              type: RegistryErrorType.serverError,
              message: 'Registry server error (${statusCode})',
              statusCode: statusCode,
              originalError: error,
            );
          default:
            return RegistryException(
              type: RegistryErrorType.serverError,
              message: 'HTTP error ${statusCode}: ${error.message}',
              statusCode: statusCode,
              originalError: error,
            );
        }

      case DioExceptionType.cancel:
        return RegistryException(
          type: RegistryErrorType.unknown,
          message: 'Request was cancelled',
          originalError: error,
        );

      default:
        return RegistryException(
          type: RegistryErrorType.unknown,
          message: 'Unknown error: ${error.message}',
          originalError: error,
        );
    }
  }

  /// Retry operation with exponential backoff
  Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    for (int attempt = 0; attempt < _maxRetryAttempts; attempt++) {
      try {
        return await operation().timeout(_requestTimeout);
      } catch (e) {
        // Don't retry on certain errors
        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
            rethrow; // Don't retry authorization or not found errors
          }
        }

        // If this is the last attempt, rethrow the error
        if (attempt == _maxRetryAttempts - 1) {
          rethrow;
        }

        // Calculate delay with exponential backoff and jitter
        final delay = _calculateRetryDelay(attempt);
        print('[GitHubMCPRegistryService] Attempt ${attempt + 1} failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }

    throw RegistryException(
      type: RegistryErrorType.unknown,
      message: 'Operation failed after $_maxRetryAttempts attempts',
    );
  }

  /// Calculate retry delay with exponential backoff and jitter
  Duration _calculateRetryDelay(int attempt) {
    final exponentialDelay = Duration(
      milliseconds: _baseRetryDelay.inMilliseconds * pow(2, attempt).round(),
    );

    // Add jitter (±25% random variation)
    final jitter = Duration(
      milliseconds: (exponentialDelay.inMilliseconds * 0.25 * (Random().nextDouble() - 0.5) * 2).round(),
    );

    final totalDelay = exponentialDelay + jitter;

    // Cap at maximum delay
    return totalDelay > _maxRetryDelay ? _maxRetryDelay : totalDelay;
  }

  /// Get servers from GitHub README parsing
  Future<List<GitHubMCPRegistryEntry>> _getServersFromReadme() async {
    // Fetch servers from README via client
    final catalogEntries = await _readmeClient.fetchServers();
    
    // Convert MCPCatalogEntry to GitHubMCPRegistryEntry for consistency
    return catalogEntries.map((entry) => GitHubMCPRegistryEntry(
      id: entry.id,
      name: entry.name,
      description: entry.description,
      status: MCPServerStatus.active,
      version: entry.version ?? '1.0.0',
      packages: [
        MCPRegistryPackage(
          registryType: PackageRegistryType.npm,
          identifier: entry.args.isNotEmpty ? entry.args.last : entry.id,
        ),
      ],
      updatedAt: DateTime.now(),
      meta: {
        'from_readme': true,
        'featured': entry.isFeatured,
        'official': entry.isOfficial,
        'remoteUrl': entry.remoteUrl,
        'capabilities': entry.capabilities,
        'tags': entry.tags,
        'requiredEnvVars': entry.requiredEnvVars,
        'optionalEnvVars': entry.optionalEnvVars,
        'defaultEnvVars': entry.defaultEnvVars,
      },
    )).toList();
  }

  /// Get fallback servers (featured servers) when API is unavailable
  List<GitHubMCPRegistryEntry> _getFallbackServers() {
    // Convert featured servers to GitHub registry entries for consistency
    final featuredServers = _featuredServers.getFeaturedServers();

    return featuredServers.map((server) => GitHubMCPRegistryEntry(
      id: server.id,
      name: server.name,
      description: server.description,
      status: MCPServerStatus.active,
      version: server.version ?? '1.0.0',
      packages: [
        MCPRegistryPackage(
          registryType: PackageRegistryType.npm,
          identifier: server.name.toLowerCase().replaceAll(' ', '-'),
        ),
      ],
      updatedAt: server.lastUpdated,
      meta: {
        'featured': true,
        'official': server.isOfficial,
        'repository': server.repository,
        'capabilities': server.capabilities,
        'tags': server.tags,
        'difficulty': _featuredServers.getServerDifficulty(server.id),
      },
    )).toList();
  }

  /// Get a specific server by ID
  Future<GitHubMCPRegistryEntry?> getServer(String id) async {
    try {
      return await _api.getServer(id);
    } catch (e) {
      print('[GitHubMCPRegistryService] Failed to fetch server $id: $e');
      return null;
    }
  }

  /// Search servers by name or description
  Future<List<GitHubMCPRegistryEntry>> searchServers(String query) async {
    final servers = await getAllActiveServers();
    final lowerQuery = query.toLowerCase();

    return servers.where((server) =>
      server.name.toLowerCase().contains(lowerQuery) ||
      server.description.toLowerCase().contains(lowerQuery) ||
      server.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  /// Get servers by package type
  Future<List<GitHubMCPRegistryEntry>> getServersByPackageType(PackageRegistryType type) async {
    final servers = await getAllActiveServers();
    return servers.where((server) =>
      server.packages.any((package) => package.registryType == type)
    ).toList();
  }

  /// Get featured servers (based on meta data or popularity)
  Future<List<GitHubMCPRegistryEntry>> getFeaturedServers() async {
    final servers = await getAllActiveServers();

    // Sort by various criteria to determine "featured" status
    servers.sort((a, b) {
      // Prioritize servers with more complete metadata
      int scoreA = _calculateServerScore(a);
      int scoreB = _calculateServerScore(b);
      return scoreB.compareTo(scoreA);
    });

    // Return top 10 as featured
    return servers.take(10).toList();
  }

  /// Get trending servers (recently updated with good scores)
  Future<List<GitHubMCPRegistryEntry>> getTrendingServers() async {
    final servers = await getAllActiveServers();

    // Filter for recently updated servers
    final recentServers = servers.where((server) {
      if (server.updatedAt == null) return false;
      final daysSinceUpdate = DateTime.now().difference(server.updatedAt!).inDays;
      return daysSinceUpdate <= 30; // Updated in last 30 days
    }).toList();

    // Sort by score
    recentServers.sort((a, b) {
      int scoreA = _calculateServerScore(a);
      int scoreB = _calculateServerScore(b);
      return scoreB.compareTo(scoreA);
    });

    return recentServers.take(8).toList();
  }

  /// Get most popular servers (high scores, many stars/forks)
  Future<List<GitHubMCPRegistryEntry>> getPopularServers() async {
    final servers = await getAllActiveServers();

    // Filter for servers with GitHub metrics
    final popularServers = servers.where((server) {
      final meta = server.meta;
      if (meta == null) return false;

      final stars = meta['stars'] as int? ?? 0;
      final forks = meta['forks'] as int? ?? 0;

      return stars > 5 || forks > 2; // Has some community engagement
    }).toList();

    // Sort by score (which now includes popularity metrics)
    popularServers.sort((a, b) {
      int scoreA = _calculateServerScore(a);
      int scoreB = _calculateServerScore(b);
      return scoreB.compareTo(scoreA);
    });

    return popularServers.take(12).toList();
  }

  /// Get servers by installation difficulty
  Future<List<GitHubMCPRegistryEntry>> getServersByDifficulty(InstallationDifficulty difficulty) async {
    final servers = await getAllActiveServers();

    return servers.where((server) => _getInstallationDifficulty(server) == difficulty).toList();
  }

  /// Determine installation difficulty for a server
  InstallationDifficulty _getInstallationDifficulty(GitHubMCPRegistryEntry server) {
    final installCmd = server.installationCommand?.toLowerCase() ?? '';
    final hasEnvVars = server.meta?.containsKey('required_env_vars') == true ||
                      server.meta?.containsKey('env_vars') == true;
    final hasComplexSetup = server.meta?.containsKey('setup_instructions') == true;

    // Easy: Simple command, no env vars needed
    if ((installCmd.contains('npx') || installCmd.contains('uvx')) && !hasEnvVars && !hasComplexSetup) {
      return InstallationDifficulty.beginner;
    }

    // Hard: Requires compilation, complex setup, or many dependencies
    if (installCmd.contains('git clone') ||
        installCmd.contains('build') ||
        installCmd.contains('compile') ||
        hasComplexSetup) {
      return InstallationDifficulty.advanced;
    }

    // Medium: Everything else (Docker, some env vars, etc.)
    return InstallationDifficulty.intermediate;
  }

  /// Calculate a score for a server based on completeness and quality indicators
  int _calculateServerScore(GitHubMCPRegistryEntry server) {
    int score = 0;

    // Base score for having packages
    score += server.packages.length * 10;

    // Bonus for having version info
    if (server.version != null && server.version!.isNotEmpty) score += 5;

    // Bonus for having repository info
    if (server.repositoryUrl != null) score += 10;

    // Bonus for having tags
    score += server.tags.length * 2;

    // Bonus for recent updates
    if (server.updatedAt != null) {
      final daysSinceUpdate = DateTime.now().difference(server.updatedAt!).inDays;
      if (daysSinceUpdate < 30) score += 25; // Increased weight for very recent
      else if (daysSinceUpdate < 90) score += 15; // Increased weight
      else if (daysSinceUpdate < 180) score += 10; // Increased weight
      else if (daysSinceUpdate < 365) score += 5; // Some credit for yearly updates
    }

    // Bonus for meta information and quality indicators
    if (server.meta != null && server.meta!.isNotEmpty) {
      score += 5;

      // GitHub-specific quality metrics
      final meta = server.meta!;

      // GitHub stars (major quality indicator)
      if (meta.containsKey('stars')) {
        final stars = meta['stars'] as int? ?? 0;
        if (stars > 100) score += 30;
        else if (stars > 50) score += 20;
        else if (stars > 10) score += 10;
        else if (stars > 0) score += 5;
      }

      // GitHub forks (adoption indicator)
      if (meta.containsKey('forks')) {
        final forks = meta['forks'] as int? ?? 0;
        if (forks > 20) score += 15;
        else if (forks > 5) score += 10;
        else if (forks > 0) score += 5;
      }

      // Documentation quality
      if (meta.containsKey('has_readme') && meta['has_readme'] == true) score += 8;
      if (meta.containsKey('has_documentation') && meta['has_documentation'] == true) score += 10;
      if (meta.containsKey('has_examples') && meta['has_examples'] == true) score += 12;

      // Maintenance indicators
      if (meta.containsKey('open_issues')) {
        final issues = meta['open_issues'] as int? ?? 0;
        // Fewer open issues is better, but some issues indicate activity
        if (issues == 0) score += 5;
        else if (issues < 5) score += 8;
        else if (issues < 20) score += 3;
        // Too many issues (>20) don't add to score
      }

      // Release management
      if (meta.containsKey('has_releases') && meta['has_releases'] == true) score += 8;
      if (meta.containsKey('has_tags') && meta['has_tags'] == true) score += 5;

      // Testing and CI
      if (meta.containsKey('has_ci') && meta['has_ci'] == true) score += 10;
      if (meta.containsKey('has_tests') && meta['has_tests'] == true) score += 12;

      // License (indicates professionalism)
      if (meta.containsKey('license') && meta['license'] != null) score += 5;
    }

    // Package type quality (some types are more stable/mature)
    for (final package in server.packages) {
      switch (package.registryType) {
        case PackageRegistryType.npm:
          score += 8; // npm packages are well-maintained
          break;
        case PackageRegistryType.pypi:
          score += 10; // Python packages often well-documented
          break;
        case PackageRegistryType.docker:
          score += 6; // Docker can be complex to set up
          break;
        case PackageRegistryType.github:
          score += 4; // Direct GitHub repos vary in quality
          break;
        case PackageRegistryType.custom:
          score += 2; // Custom setups can be problematic
          break;
      }
    }

    // Installation complexity penalty/bonus
    final installCmd = server.installationCommand?.toLowerCase() ?? '';
    if (installCmd.contains('npx') || installCmd.contains('uvx')) {
      score += 10; // Easy one-command install
    } else if (installCmd.contains('docker run')) {
      score += 5; // Docker is reliable but complex
    } else if (installCmd.contains('git clone')) {
      score -= 5; // Manual setup required
    }

    return score;
  }

  /// Enrich server metadata with GitHub repository information
  Future<GitHubMCPRegistryEntry> enrichServerWithGitHubMetadata(GitHubMCPRegistryEntry server) async {
    final repoUrl = server.repositoryUrl;
    if (repoUrl == null || !repoUrl.contains('github.com')) {
      return server; // Return unchanged if no GitHub repo
    }

    try {
      // Extract owner/repo from GitHub URL
      final githubMatch = RegExp(r'github\.com/([^/]+)/([^/]+)').firstMatch(repoUrl);
      if (githubMatch == null) return server;

      final owner = githubMatch.group(1)!;
      final repo = githubMatch.group(2)!.replaceAll('.git', '');

      // Fetch repository metadata from GitHub API
      final repoData = await _fetchGitHubRepository(owner, repo);
      if (repoData == null) return server;

      // Create enriched metadata
      final enrichedMeta = Map<String, dynamic>.from(server.meta ?? {});

      // Add GitHub metrics
      enrichedMeta['stars'] = repoData['stargazers_count'] ?? 0;
      enrichedMeta['forks'] = repoData['forks_count'] ?? 0;
      enrichedMeta['open_issues'] = repoData['open_issues_count'] ?? 0;
      enrichedMeta['watchers'] = repoData['watchers_count'] ?? 0;
      enrichedMeta['size'] = repoData['size'] ?? 0;

      // Add repository info
      enrichedMeta['license'] = repoData['license']?['name'];
      enrichedMeta['language'] = repoData['language'];
      enrichedMeta['topics'] = repoData['topics'] ?? [];
      enrichedMeta['has_wiki'] = repoData['has_wiki'] ?? false;
      enrichedMeta['has_pages'] = repoData['has_pages'] ?? false;
      enrichedMeta['has_discussions'] = repoData['has_discussions'] ?? false;

      // Add activity metrics
      enrichedMeta['created_at'] = repoData['created_at'];
      enrichedMeta['updated_at'] = repoData['updated_at'];
      enrichedMeta['pushed_at'] = repoData['pushed_at'];

      // Add quality indicators
      enrichedMeta['has_readme'] = await _checkFileExists(owner, repo, 'README.md');
      enrichedMeta['has_documentation'] = await _checkFileExists(owner, repo, 'docs') ||
                                         await _checkFileExists(owner, repo, 'DOCS.md');
      enrichedMeta['has_examples'] = await _checkFileExists(owner, repo, 'examples') ||
                                    await _checkFileExists(owner, repo, 'example');
      enrichedMeta['has_tests'] = await _checkFileExists(owner, repo, 'test') ||
                                 await _checkFileExists(owner, repo, 'tests') ||
                                 await _checkFileExists(owner, repo, '__tests__');

      // Check for CI/CD
      enrichedMeta['has_ci'] = await _checkFileExists(owner, repo, '.github/workflows') ||
                              await _checkFileExists(owner, repo, '.gitlab-ci.yml') ||
                              await _checkFileExists(owner, repo, '.travis.yml');

      // Check for releases
      enrichedMeta['has_releases'] = await _hasReleases(owner, repo);
      enrichedMeta['has_tags'] = await _hasTags(owner, repo);

      // Calculate repository health score
      enrichedMeta['health_score'] = _calculateHealthScore(repoData, enrichedMeta);

      // Mark as enriched and timestamp
      enrichedMeta['enriched'] = true;
      enrichedMeta['enriched_at'] = DateTime.now().toIso8601String();

      return GitHubMCPRegistryEntry(
        id: server.id,
        name: server.name,
        description: server.description,
        status: server.status,
        version: server.version,
        packages: server.packages,
        meta: enrichedMeta,
        createdAt: server.createdAt,
        updatedAt: server.updatedAt,
      );

    } catch (e) {
      print('[GitHubMCPRegistryService] Failed to enrich ${server.name} with GitHub metadata: $e');
      return server; // Return unchanged on error
    }
  }

  /// Fetch repository data from GitHub API
  Future<Map<String, dynamic>?> _fetchGitHubRepository(String owner, String repo) async {
    try {
      final response = await _api._dio.get(
        'https://api.github.com/repos/$owner/$repo',
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'AgentEngine-MCP-Registry',
          },
        ),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('[GitHubMCPRegistryService] GitHub API error for $owner/$repo: $e');
      return null;
    }
  }

  /// Check if a file or directory exists in the repository
  Future<bool> _checkFileExists(String owner, String repo, String path) async {
    try {
      await _api._dio.get(
        'https://api.github.com/repos/$owner/$repo/contents/$path',
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'AgentEngine-MCP-Registry',
          },
        ),
      );
      return true;
    } catch (e) {
      return false; // File doesn't exist or API error
    }
  }

  /// Check if repository has releases
  Future<bool> _hasReleases(String owner, String repo) async {
    try {
      final response = await _api._dio.get(
        'https://api.github.com/repos/$owner/$repo/releases',
        queryParameters: {'per_page': 1},
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'AgentEngine-MCP-Registry',
          },
        ),
      );
      final releases = response.data as List;
      return releases.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if repository has tags
  Future<bool> _hasTags(String owner, String repo) async {
    try {
      final response = await _api._dio.get(
        'https://api.github.com/repos/$owner/$repo/tags',
        queryParameters: {'per_page': 1},
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'AgentEngine-MCP-Registry',
          },
        ),
      );
      final tags = response.data as List;
      return tags.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Calculate repository health score based on various metrics
  int _calculateHealthScore(Map<String, dynamic> repoData, Map<String, dynamic> meta) {
    int score = 0;

    // Stars (major indicator)
    final stars = repoData['stargazers_count'] ?? 0;
    if (stars > 1000) score += 50;
    else if (stars > 100) score += 40;
    else if (stars > 10) score += 30;
    else if (stars > 0) score += 20;

    // Recent activity
    if (repoData['pushed_at'] != null) {
      final pushedAt = DateTime.parse(repoData['pushed_at']);
      final daysSincePush = DateTime.now().difference(pushedAt).inDays;
      if (daysSincePush < 7) score += 25;
      else if (daysSincePush < 30) score += 20;
      else if (daysSincePush < 90) score += 15;
      else if (daysSincePush < 365) score += 10;
    }

    // Documentation
    if (meta['has_readme'] == true) score += 15;
    if (meta['has_documentation'] == true) score += 15;
    if (meta['has_examples'] == true) score += 10;

    // Testing and CI
    if (meta['has_tests'] == true) score += 20;
    if (meta['has_ci'] == true) score += 15;

    // Maintenance indicators
    if (meta['has_releases'] == true) score += 10;
    if (repoData['license'] != null) score += 10;

    // Issue management
    final openIssues = repoData['open_issues_count'] ?? 0;
    if (openIssues == 0) score += 10;
    else if (openIssues < 5) score += 5;
    else if (openIssues > 50) score -= 10; // Too many open issues

    return score.clamp(0, 100);
  }

  /// Enrich all servers with GitHub metadata (use sparingly due to API limits)
  Future<List<GitHubMCPRegistryEntry>> enrichAllServersWithGitHubMetadata(
    List<GitHubMCPRegistryEntry> servers,
    {int maxConcurrent = 3}
  ) async {
    final enrichedServers = <GitHubMCPRegistryEntry>[];

    // Process servers in batches to respect GitHub API rate limits
    for (int i = 0; i < servers.length; i += maxConcurrent) {
      final batch = servers.skip(i).take(maxConcurrent);
      final enrichedBatch = await Future.wait(
        batch.map((server) => enrichServerWithGitHubMetadata(server)),
      );
      enrichedServers.addAll(enrichedBatch);

      // Add small delay between batches to be respectful to GitHub API
      if (i + maxConcurrent < servers.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return enrichedServers;
  }

  /// Clear cache to force refresh on next request
  void clearCache() {
    _cachedServers = null;
    _lastCacheTime = null;
  }

  /// Check if cache is valid
  bool get isCacheValid {
    if (_cachedServers == null || _lastCacheTime == null) return false;
    final cacheAge = DateTime.now().difference(_lastCacheTime!);
    return cacheAge < _cacheValidDuration;
  }
}

/// Provider for GitHub MCP Registry Service
final githubMCPRegistryServiceProvider = Provider<GitHubMCPRegistryService>((ref) {
  final api = ref.read(githubMCPRegistryApiProvider);
  return GitHubMCPRegistryService(api);
});

/// Provider for all active servers
final activeServersProvider = FutureProvider<List<GitHubMCPRegistryEntry>>((ref) async {
  final service = ref.read(githubMCPRegistryServiceProvider);
  return service.getAllActiveServers();
});

/// Provider for featured servers
final featuredServersProvider = FutureProvider<List<GitHubMCPRegistryEntry>>((ref) async {
  final service = ref.read(githubMCPRegistryServiceProvider);
  return service.getFeaturedServers();
});

/// Provider for server search
final serverSearchProvider = FutureProvider.family<List<GitHubMCPRegistryEntry>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.read(githubMCPRegistryServiceProvider);
  return service.searchServers(query);
});

/// Provider for trending servers
final trendingServersProvider = FutureProvider<List<GitHubMCPRegistryEntry>>((ref) async {
  final service = ref.read(githubMCPRegistryServiceProvider);
  return service.getTrendingServers();
});

/// Provider for popular servers
final popularServersProvider = FutureProvider<List<GitHubMCPRegistryEntry>>((ref) async {
  final service = ref.read(githubMCPRegistryServiceProvider);
  return service.getPopularServers();
});

/// Provider for servers by difficulty
final serversByDifficultyProvider = FutureProvider.family<List<GitHubMCPRegistryEntry>, InstallationDifficulty>((ref, difficulty) async {
  final service = ref.read(githubMCPRegistryServiceProvider);
  return service.getServersByDifficulty(difficulty);
});