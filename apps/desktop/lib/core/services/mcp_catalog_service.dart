import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'desktop/desktop_storage_service.dart';
import 'desktop/desktop_service_provider.dart';
import '../models/mcp_catalog_entry.dart';
import '../data/mcp_server_registry.dart';
import 'secure_auth_service.dart';
import '../error/app_error_handler.dart';
import '../validation/input_validator.dart';
import '../security/security_validator.dart';
import 'production_logger.dart';

/// Service for managing MCP server catalog and per-agent configurations
class MCPCatalogService {
  final DesktopStorageService _storageService;
  final SecureAuthService _authService;
  
  // Core catalog entries from mcp-core
  final Map<String, MCPCatalogEntry> _catalogEntries = {};
  
  // Per-agent MCP server configurations
  final Map<String, Map<String, AgentMCPServerConfig>> _agentConfigs = {};
  
  // User-added custom catalog entries
  final Map<String, MCPCatalogEntry> _customEntries = {};

  MCPCatalogService(this._storageService, this._authService) {
    _loadCatalog();
    _loadAgentConfigs();
  }

  /// Initialize with built-in catalog entries
  Future<void> _loadCatalog() async {
    await AppErrorHandler.withErrorBoundary(
      () async {
        _catalogEntries.clear();
        
        // Load built-in GitHub and Slack entries (MVP focus)
        _catalogEntries.addAll(_getBuiltInEntries());
        
        // Load custom user-added entries
        await _loadCustomEntries();
        
        ProductionLogger.instance.info(
          'MCP catalog loaded successfully',
          data: {
            'built_in_entries': _catalogEntries.length,
            'custom_entries': _customEntries.length,
          },
          category: 'mcp_catalog',
        );
      },
      operationName: 'load_mcp_catalog',
      throwError: true,
    );
  }

  /// Get built-in catalog entries from registry
  Map<String, MCPCatalogEntry> _getBuiltInEntries() {
    return MCPServerRegistry.getAllServers();
  }

  /// Get all catalog entries
  List<MCPCatalogEntry> getAllCatalogEntries() {
    final allEntries = <MCPCatalogEntry>[];
    allEntries.addAll(_catalogEntries.values);
    allEntries.addAll(_customEntries.values);
    return allEntries;
  }

  /// Get catalog entry by ID
  MCPCatalogEntry? getCatalogEntry(String id) {
    return _catalogEntries[id] ?? _customEntries[id];
  }

  /// Get featured catalog entries
  List<MCPCatalogEntry> getFeaturedEntries() {
    return getAllCatalogEntries().where((entry) => entry.isFeatured).toList();
  }

  /// Get entries by category
  List<MCPCatalogEntry> getEntriesByCategory(MCPServerCategory category) {
    return getAllCatalogEntries().where((entry) => entry.category == category).toList();
  }

  /// Search catalog entries with validation
  List<MCPCatalogEntry> searchEntries(String query) {
    try {
      // Validate search query
      final queryResult = InputValidator.validateLength(
        query.trim(),
        min: 1,
        max: 100,
        fieldName: 'Search query',
      );
      queryResult.throwIfInvalid('search_query');
      
      final sanitizedQuery = InputValidator.sanitizeString(query);
      final lowerQuery = sanitizedQuery.toLowerCase();
      
      final results = getAllCatalogEntries().where((entry) {
        return entry.name.toLowerCase().contains(lowerQuery) ||
               entry.description.toLowerCase().contains(lowerQuery) ||
               entry.capabilities.any((cap) => cap.toLowerCase().contains(lowerQuery));
      }).toList();
      
      ProductionLogger.instance.info(
        'Catalog search completed',
        data: {
          'query': sanitizedQuery,
          'results_count': results.length,
        },
        category: 'mcp_catalog',
      );
      
      return results;
    } catch (error) {
      throw AppErrorHandler.handleBusinessError(
        error,
        operation: 'search_catalog_entries',
        context: {'query': query},
      );
    }
  }

  /// Add custom catalog entry with validation
  Future<void> addCustomEntry(MCPCatalogEntry entry) async {
    await AppErrorHandler.withErrorBoundary(
      () async {
        // Validate entry data
        _validateCatalogEntry(entry);
        
        // Check for duplicates
        if (_catalogEntries.containsKey(entry.id) || _customEntries.containsKey(entry.id)) {
          throw AppException.validation(
            message: 'Catalog entry with ID "${entry.id}" already exists',
            field: 'entry_id',
          );
        }
        
        _customEntries[entry.id] = entry;
        await _saveCustomEntries();
        
        ProductionLogger.instance.info(
          'Custom catalog entry added',
          data: {
            'entry_id': entry.id,
            'entry_name': entry.name,
            'category': entry.category.name,
          },
          category: 'mcp_catalog',
        );
      },
      operationName: 'add_custom_catalog_entry',
      context: {'entry_id': entry.id, 'entry_name': entry.name},
      throwError: true,
    );
  }

  /// Remove custom catalog entry
  Future<void> removeCustomEntry(String id) async {
    _customEntries.remove(id);
    await _saveCustomEntries();
  }

  // ==================== Agent Configuration Management ====================

  /// Get MCP server configurations for an agent
  Map<String, AgentMCPServerConfig> getAgentMCPConfigs(String agentId) {
    return Map.from(_agentConfigs[agentId] ?? {});
  }

  /// Check if agent has MCP server enabled
  bool isServerEnabledForAgent(String agentId, String catalogEntryId) {
    final config = _agentConfigs[agentId]?[catalogEntryId];
    return config?.enabled ?? false;
  }

  /// Enable MCP server for agent with secure credential storage
  Future<void> enableServerForAgent(
    String agentId, 
    String catalogEntryId,
    Map<String, String> authConfig,
  ) async {
    // Store credentials securely
    for (final entry in authConfig.entries) {
      final key = 'mcp:$agentId:$catalogEntryId:${entry.key}';
      await _authService.storeCredential(key, entry.value);
    }

    _agentConfigs[agentId] ??= {};
    _agentConfigs[agentId]![catalogEntryId] = AgentMCPServerConfig(
      catalogEntryId: catalogEntryId,
      enabled: true,
      authConfig: Map.fromEntries(authConfig.keys.map((k) => MapEntry(k, '***'))), // Store keys only, not values
      createdAt: DateTime.now(),
    );
    await _saveAgentConfigs();
  }

  /// Disable MCP server for agent
  Future<void> disableServerForAgent(String agentId, String catalogEntryId) async {
    final config = _agentConfigs[agentId]?[catalogEntryId];
    if (config != null) {
      _agentConfigs[agentId]![catalogEntryId] = config.copyWith(enabled: false);
      await _saveAgentConfigs();
    }
  }

  /// Update agent MCP server configuration
  Future<void> updateAgentServerConfig(
    String agentId,
    String catalogEntryId,
    AgentMCPServerConfig config,
  ) async {
    _agentConfigs[agentId] ??= {};
    _agentConfigs[agentId]![catalogEntryId] = config;
    await _saveAgentConfigs();
  }

  /// Remove MCP server from agent
  Future<void> removeServerFromAgent(String agentId, String catalogEntryId) async {
    _agentConfigs[agentId]?.remove(catalogEntryId);
    if (_agentConfigs[agentId]?.isEmpty ?? false) {
      _agentConfigs.remove(agentId);
    }
    await _saveAgentConfigs();
  }

  /// Get list of enabled MCP servers for agent (for execution service)
  List<String> getEnabledServerIds(String agentId) {
    final configs = _agentConfigs[agentId] ?? {};
    return configs.entries
        .where((entry) => entry.value.enabled)
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if agent server configuration is complete
  Future<bool> isAgentServerConfigured(String agentId, String catalogEntryId) async {
    final config = _agentConfigs[agentId]?[catalogEntryId];
    if (config == null) return false;

    final catalogEntry = getCatalogEntry(catalogEntryId);
    if (catalogEntry == null) return false;

    // Check if all required auth is provided and valid
    for (final authReq in catalogEntry.requiredAuth.where((a) => a.required)) {
      final key = 'mcp:$agentId:$catalogEntryId:${authReq.name}';
      final value = await _authService.getCredential(key);
      if (value == null || value.isEmpty) return false;
    }

    return true;
  }

  /// Get actual credentials for agent deployment (for execution service)
  Future<Map<String, String>> getAgentServerCredentials(
    String agentId,
    String catalogEntryId,
  ) async {
    final catalogEntry = getCatalogEntry(catalogEntryId);
    if (catalogEntry == null) return {};

    final credentials = <String, String>{};
    for (final authReq in catalogEntry.requiredAuth) {
      final key = 'mcp:$agentId:$catalogEntryId:${authReq.name}';
      final value = await _authService.getCredential(key);
      if (value != null) {
        credentials[authReq.name] = value;
      }
    }

    return credentials;
  }

  // ==================== Persistence Methods ====================

  Future<void> _loadCustomEntries() async {
    try {
      final data = _storageService.getPreference<String>('mcp_custom_catalog');
      if (data != null) {
        final Map<String, dynamic> entriesJson = Map<String, dynamic>.from(json.decode(data));
        _customEntries.clear();
        for (final entry in entriesJson.entries) {
          _customEntries[entry.key] = MCPCatalogEntry.fromJson(entry.value);
        }
      }
    } catch (e) {
      // Handle loading error
      print('Error loading custom catalog entries: $e');
    }
  }

  Future<void> _saveCustomEntries() async {
    try {
      final Map<String, dynamic> entriesJson = {};
      for (final entry in _customEntries.entries) {
        entriesJson[entry.key] = entry.value.toJson();
      }
      await _storageService.setPreference('mcp_custom_catalog', json.encode(entriesJson));
    } catch (e) {
      print('Error saving custom catalog entries: $e');
    }
  }

  Future<void> _loadAgentConfigs() async {
    try {
      final data = _storageService.getAllHiveData('mcp_agent_configs');
      _agentConfigs.clear();
      for (final agentEntry in data.entries) {
        final agentId = agentEntry.key;
        final agentData = Map<String, dynamic>.from(agentEntry.value);
        _agentConfigs[agentId] = {};
        
        for (final serverEntry in agentData.entries) {
          final serverId = serverEntry.key;
          _agentConfigs[agentId]![serverId] = AgentMCPServerConfig.fromJson(serverEntry.value);
        }
      }
    } catch (e) {
      print('Error loading agent MCP configs: $e');
    }
  }

  Future<void> _saveAgentConfigs() async {
    try {
      // Clear existing data
      await _storageService.clearHiveBox('mcp_agent_configs');
      
      // Save updated data
      for (final agentEntry in _agentConfigs.entries) {
        final agentId = agentEntry.key;
        final Map<String, dynamic> agentData = {};
        
        for (final serverEntry in agentEntry.value.entries) {
          agentData[serverEntry.key] = serverEntry.value.toJson();
        }
        
        await _storageService.setHiveData('mcp_agent_configs', agentId, agentData);
      }
    } catch (e) {
      print('Error saving agent MCP configs: $e');
    }
  }

  /// Mark server as used for an agent (for analytics)
  Future<void> markServerUsed(String agentId, String catalogEntryId) async {
    final config = _agentConfigs[agentId]?[catalogEntryId];
    if (config != null) {
      _agentConfigs[agentId]![catalogEntryId] = config.copyWith(
        lastUsed: DateTime.now(),
      );
      // Don't save immediately to avoid too many writes
    }
  }

  /// Validate catalog entry data
  void _validateCatalogEntry(MCPCatalogEntry entry) {
    final validations = InputValidator.validateFields({
      'entry_id': () => InputValidator.validateMcpServerId(entry.id),
      'entry_name': () => InputValidator.validateLength(
        entry.name,
        min: 1,
        max: 100,
        fieldName: 'Entry name',
      ),
      'description': () => InputValidator.validateLength(
        entry.description,
        min: 1,
        max: 500,
        fieldName: 'Description',
      ),
    });

    validations.throwIfInvalid(context: {
      'entry_id': entry.id,
      'entry_name': entry.name,
    });

    // Validate capabilities
    if (entry.capabilities.isEmpty) {
      throw AppErrorHandler.handleValidationError(
        'capabilities',
        'At least one capability must be specified',
      );
    }
  }
}

// ==================== Riverpod Providers ====================

final mcpCatalogServiceProvider = Provider<MCPCatalogService>((ref) {
  final storageService = ref.read(desktopStorageServiceProvider);
  final authService = ref.read(secureAuthServiceProvider);
  return MCPCatalogService(storageService, authService);
});

/// Provider for all catalog entries
final mcpCatalogEntriesProvider = Provider<List<MCPCatalogEntry>>((ref) {
  final service = ref.read(mcpCatalogServiceProvider);
  return service.getAllCatalogEntries();
});

/// Provider for featured catalog entries
final mcpFeaturedEntriesProvider = Provider<List<MCPCatalogEntry>>((ref) {
  final service = ref.read(mcpCatalogServiceProvider);
  return service.getFeaturedEntries();
});

/// Provider for agent MCP configurations
final agentMCPConfigsProvider = Provider.family<Map<String, AgentMCPServerConfig>, String>((ref, agentId) {
  final service = ref.read(mcpCatalogServiceProvider);
  return service.getAgentMCPConfigs(agentId);
});

/// Provider for checking if server is enabled for agent
final isServerEnabledProvider = Provider.family<bool, (String, String)>((ref, params) {
  final (agentId, catalogEntryId) = params;
  final service = ref.read(mcpCatalogServiceProvider);
  return service.isServerEnabledForAgent(agentId, catalogEntryId);
});