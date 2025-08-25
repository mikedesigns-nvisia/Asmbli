import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_service.dart';
import 'mcp_settings_service.dart';

/// Service for backing up and exporting integration configurations
class IntegrationBackupService {
  final IntegrationService _integrationService;
  final MCPSettingsService _mcpService;
  
  IntegrationBackupService(this._integrationService, this._mcpService);
  
  /// Export all integration configurations to a backup file
  Future<String> exportAllConfigurations() async {
    final configurations = await _getAllConfigurations();
    
    final backup = IntegrationBackup(
      version: '1.0',
      timestamp: DateTime.now(),
      totalIntegrations: configurations.length,
      configurations: configurations,
      metadata: BackupMetadata(
        exportedBy: 'AgentEngine Desktop',
        platform: Platform.operatingSystem,
        agentEngineVersion: '1.0.0',
      ),
    );
    
    return jsonEncode(backup.toJson());
  }
  
  /// Export specific integrations to a backup file
  Future<String> exportSelectedConfigurations(List<String> integrationIds) async {
    final allConfigurations = await _getAllConfigurations();
    final selectedConfigurations = allConfigurations
        .where((config) => integrationIds.contains(config.integrationId))
        .toList();
    
    final backup = IntegrationBackup(
      version: '1.0',
      timestamp: DateTime.now(),
      totalIntegrations: selectedConfigurations.length,
      configurations: selectedConfigurations,
      metadata: BackupMetadata(
        exportedBy: 'AgentEngine Desktop',
        platform: Platform.operatingSystem,
        agentEngineVersion: '1.0.0',
        isPartialExport: true,
        selectedIntegrations: integrationIds,
      ),
    );
    
    return jsonEncode(backup.toJson());
  }
  
  /// Save backup to a file
  Future<String> saveBackupToFile(String backupData, String filename) async {
    try {
      // Get user's documents directory (in a real app, would use path_provider)
      final documentsPath = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '/tmp';
      final backupDir = Directory(path.join(documentsPath, 'AgentEngine', 'Backups'));
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final file = File(path.join(backupDir.path, '$filename.json'));
      await file.writeAsString(backupData);
      
      return file.path;
    } catch (e) {
      throw IntegrationBackupException('Failed to save backup file: $e');
    }
  }
  
  /// Import configurations from a backup file
  Future<ImportResult> importFromBackup(String backupData) async {
    try {
      final backupJson = jsonDecode(backupData) as Map<String, dynamic>;
      final backup = IntegrationBackup.fromJson(backupJson);
      
      final importResult = ImportResult(
        totalConfigurations: backup.totalIntegrations,
        successfulImports: [],
        failedImports: [],
        skippedImports: [],
        conflicts: [],
      );
      
      for (final config in backup.configurations) {
        try {
          final result = await _importSingleConfiguration(config);
          
          switch (result.status) {
            case ImportStatus.success:
              importResult.successfulImports.add(result);
              break;
            case ImportStatus.conflict:
              importResult.conflicts.add(result);
              break;
            case ImportStatus.skipped:
              importResult.skippedImports.add(result);
              break;
            case ImportStatus.failed:
              importResult.failedImports.add(result);
              break;
          }
        } catch (e) {
          importResult.failedImports.add(SingleImportResult(
            integrationId: config.integrationId,
            status: ImportStatus.failed,
            error: e.toString(),
          ));
        }
      }
      
      return importResult;
    } catch (e) {
      throw IntegrationBackupException('Failed to import backup: $e');
    }
  }
  
  /// Import configurations with conflict resolution
  Future<ImportResult> importWithConflictResolution(
    String backupData,
    Map<String, ConflictResolution> conflictResolutions,
  ) async {
    final backup = IntegrationBackup.fromJson(jsonDecode(backupData));
    final importResult = ImportResult(
      totalConfigurations: backup.totalIntegrations,
      successfulImports: [],
      failedImports: [],
      skippedImports: [],
      conflicts: [],
    );
    
    for (final config in backup.configurations) {
      try {
        final existingConfig = _mcpService.allMCPServers[config.integrationId];
        
        if (existingConfig != null) {
          final resolution = conflictResolutions[config.integrationId] ?? ConflictResolution.skip;
          
          switch (resolution) {
            case ConflictResolution.replace:
              await _replaceConfiguration(config);
              importResult.successfulImports.add(SingleImportResult(
                integrationId: config.integrationId,
                status: ImportStatus.success,
                message: 'Configuration replaced',
              ));
              break;
              
            case ConflictResolution.merge:
              await _mergeConfiguration(config, existingConfig);
              importResult.successfulImports.add(SingleImportResult(
                integrationId: config.integrationId,
                status: ImportStatus.success,
                message: 'Configuration merged',
              ));
              break;
              
            case ConflictResolution.skip:
              importResult.skippedImports.add(SingleImportResult(
                integrationId: config.integrationId,
                status: ImportStatus.skipped,
                message: 'Skipped due to existing configuration',
              ));
              break;
              
            case ConflictResolution.rename:
              final newId = '${config.integrationId}_imported';
              await _createConfiguration(config.copyWith(integrationId: newId));
              importResult.successfulImports.add(SingleImportResult(
                integrationId: config.integrationId,
                status: ImportStatus.success,
                message: 'Configuration imported with new ID: $newId',
              ));
              break;
          }
        } else {
          await _createConfiguration(config);
          importResult.successfulImports.add(SingleImportResult(
            integrationId: config.integrationId,
            status: ImportStatus.success,
            message: 'New configuration created',
          ));
        }
      } catch (e) {
        importResult.failedImports.add(SingleImportResult(
          integrationId: config.integrationId,
          status: ImportStatus.failed,
          error: e.toString(),
        ));
      }
    }
    
    return importResult;
  }
  
  /// Get backup history
  Future<List<BackupInfo>> getBackupHistory() async {
    try {
      final documentsPath = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '/tmp';
      final backupDir = Directory(path.join(documentsPath, 'AgentEngine', 'Backups'));
      
      if (!await backupDir.exists()) {
        return [];
      }
      
      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();
      
      final backupInfos = <BackupInfo>[];
      
      for (final file in files) {
        try {
          final content = await file.readAsString();
          final backupJson = jsonDecode(content) as Map<String, dynamic>;
          final backup = IntegrationBackup.fromJson(backupJson);
          
          final stat = await file.stat();
          
          backupInfos.add(BackupInfo(
            filename: path.basename(file.path),
            filePath: file.path,
            timestamp: backup.timestamp,
            totalIntegrations: backup.totalIntegrations,
            fileSize: stat.size,
            version: backup.version,
            isPartialExport: backup.metadata.isPartialExport ?? false,
          ));
        } catch (e) {
          // Skip invalid backup files
          continue;
        }
      }
      
      // Sort by timestamp, newest first
      backupInfos.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return backupInfos;
    } catch (e) {
      return [];
    }
  }
  
  /// Validate backup file
  Future<BackupValidation> validateBackup(String backupData) async {
    try {
      final backupJson = jsonDecode(backupData) as Map<String, dynamic>;
      final backup = IntegrationBackup.fromJson(backupJson);
      
      final issues = <ValidationIssue>[];
      final compatibleIntegrations = <String>[];
      final incompatibleIntegrations = <String>[];
      
      for (final config in backup.configurations) {
        final integration = IntegrationRegistry.getById(config.integrationId);
        
        if (integration == null) {
          incompatibleIntegrations.add(config.integrationId);
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            integrationId: config.integrationId,
            message: 'Integration not found in registry',
            affectedIntegrations: [config.integrationId],
          ));
        } else if (!integration.isAvailable) {
          incompatibleIntegrations.add(config.integrationId);
          issues.add(ValidationIssue(
            severity: ValidationSeverity.info,
            integrationId: config.integrationId,
            message: 'Integration is not yet available',
            affectedIntegrations: [config.integrationId],
          ));
        } else {
          compatibleIntegrations.add(config.integrationId);
        }
      }
      
      return BackupValidation(
        isValid: true,
        version: backup.version,
        isCompatible: incompatibleIntegrations.isEmpty,
        totalConfigurations: backup.totalIntegrations,
        compatibleIntegrations: compatibleIntegrations,
        incompatibleIntegrations: incompatibleIntegrations,
        issues: issues,
        metadata: backup.metadata,
      );
    } catch (e) {
      return BackupValidation(
        isValid: false,
        version: 'unknown',
        isCompatible: false,
        totalConfigurations: 0,
        compatibleIntegrations: [],
        incompatibleIntegrations: [],
        issues: [
          ValidationIssue(
            severity: ValidationSeverity.error,
            integrationId: '',
            message: 'Invalid backup file format: $e',
            affectedIntegrations: [],
          ),
        ],
        metadata: BackupMetadata(
          exportedBy: 'Unknown',
          platform: 'Unknown',
          agentEngineVersion: 'Unknown',
        ),
      );
    }
  }
  
  /// Generate backup template for manual configuration
  Future<String> generateConfigurationTemplate(List<String> integrationIds) async {
    final configurations = <IntegrationConfiguration>[];
    
    for (final id in integrationIds) {
      final integration = IntegrationRegistry.getById(id);
      if (integration != null) {
        configurations.add(IntegrationConfiguration(
          integrationId: id,
          name: integration.name,
          enabled: false,
          settings: <String, dynamic>{
            // Add template settings based on integration type
            '_template': true,
            '_description': 'Fill in the required settings for ${integration.name}',
          },
          capabilities: integration.capabilities,
          category: integration.category.name,
          version: '1.0.0',
          lastModified: DateTime.now(),
        ));
      }
    }
    
    final template = IntegrationBackup(
      version: '1.0',
      timestamp: DateTime.now(),
      totalIntegrations: configurations.length,
      configurations: configurations,
      metadata: BackupMetadata(
        exportedBy: 'AgentEngine Template Generator',
        platform: Platform.operatingSystem,
        agentEngineVersion: '1.0.0',
        isTemplate: true,
      ),
    );
    
    return JsonEncoder.withIndent('  ').convert(template.toJson());
  }
  
  // Private helper methods
  Future<List<IntegrationConfiguration>> _getAllConfigurations() async {
    final configurations = <IntegrationConfiguration>[];
    final configuredIntegrations = _integrationService.getConfiguredIntegrations();
    
    for (final integration in configuredIntegrations) {
      if (integration.mcpConfig != null) {
        configurations.add(IntegrationConfiguration(
          integrationId: integration.definition.id,
          name: integration.definition.name,
          enabled: integration.isEnabled,
          settings: integration.mcpConfig!.toJson(),
          capabilities: integration.definition.capabilities,
          category: integration.definition.category.name,
          version: '1.0.0',
          lastModified: DateTime.now(),
        ));
      }
    }
    
    return configurations;
  }
  
  Future<SingleImportResult> _importSingleConfiguration(IntegrationConfiguration config) async {
    final existingConfig = _mcpService.allMCPServers[config.integrationId];
    
    if (existingConfig != null) {
      return SingleImportResult(
        integrationId: config.integrationId,
        status: ImportStatus.conflict,
        message: 'Configuration already exists',
      );
    }
    
    await _createConfiguration(config);
    
    return SingleImportResult(
      integrationId: config.integrationId,
      status: ImportStatus.success,
      message: 'Configuration imported successfully',
    );
  }
  
  Future<void> _createConfiguration(IntegrationConfiguration config) async {
    // Convert back to MCPServerConfig and save
    final mcpConfig = MCPServerConfig.fromJson(config.settings);
    await _mcpService.addMCPServer(config.integrationId, mcpConfig);
  }
  
  Future<void> _replaceConfiguration(IntegrationConfiguration config) async {
    await _mcpService.removeMCPServer(config.integrationId);
    await _createConfiguration(config);
  }
  
  Future<void> _mergeConfiguration(IntegrationConfiguration config, MCPServerConfig existing) async {
    // Simple merge - keep existing enabled state but update settings
    final mergedConfig = MCPServerConfig.fromJson({
      ...existing.toJson(),
      ...config.settings,
    });
    
    await _mcpService.updateMCPServer(config.integrationId, mergedConfig);
  }
}

// Data models
class IntegrationBackup {
  final String version;
  final DateTime timestamp;
  final int totalIntegrations;
  final List<IntegrationConfiguration> configurations;
  final BackupMetadata metadata;
  
  const IntegrationBackup({
    required this.version,
    required this.timestamp,
    required this.totalIntegrations,
    required this.configurations,
    required this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'timestamp': timestamp.toIso8601String(),
      'totalIntegrations': totalIntegrations,
      'configurations': configurations.map((c) => c.toJson()).toList(),
      'metadata': metadata.toJson(),
    };
  }
  
  factory IntegrationBackup.fromJson(Map<String, dynamic> json) {
    return IntegrationBackup(
      version: json['version'],
      timestamp: DateTime.parse(json['timestamp']),
      totalIntegrations: json['totalIntegrations'],
      configurations: (json['configurations'] as List)
          .map((c) => IntegrationConfiguration.fromJson(c))
          .toList(),
      metadata: BackupMetadata.fromJson(json['metadata']),
    );
  }
}

class IntegrationConfiguration {
  final String integrationId;
  final String name;
  final bool enabled;
  final Map<String, dynamic> settings;
  final List<String> capabilities;
  final String category;
  final String version;
  final DateTime lastModified;
  
  const IntegrationConfiguration({
    required this.integrationId,
    required this.name,
    required this.enabled,
    required this.settings,
    required this.capabilities,
    required this.category,
    required this.version,
    required this.lastModified,
  });
  
  IntegrationConfiguration copyWith({
    String? integrationId,
    String? name,
    bool? enabled,
    Map<String, dynamic>? settings,
    List<String>? capabilities,
    String? category,
    String? version,
    DateTime? lastModified,
  }) {
    return IntegrationConfiguration(
      integrationId: integrationId ?? this.integrationId,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      settings: settings ?? this.settings,
      capabilities: capabilities ?? this.capabilities,
      category: category ?? this.category,
      version: version ?? this.version,
      lastModified: lastModified ?? this.lastModified,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'integrationId': integrationId,
      'name': name,
      'enabled': enabled,
      'settings': settings,
      'capabilities': capabilities,
      'category': category,
      'version': version,
      'lastModified': lastModified.toIso8601String(),
    };
  }
  
  factory IntegrationConfiguration.fromJson(Map<String, dynamic> json) {
    return IntegrationConfiguration(
      integrationId: json['integrationId'],
      name: json['name'],
      enabled: json['enabled'],
      settings: Map<String, dynamic>.from(json['settings']),
      capabilities: List<String>.from(json['capabilities']),
      category: json['category'],
      version: json['version'],
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}

class BackupMetadata {
  final String exportedBy;
  final String platform;
  final String agentEngineVersion;
  final bool? isPartialExport;
  final List<String>? selectedIntegrations;
  final bool? isTemplate;
  
  const BackupMetadata({
    required this.exportedBy,
    required this.platform,
    required this.agentEngineVersion,
    this.isPartialExport,
    this.selectedIntegrations,
    this.isTemplate,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'exportedBy': exportedBy,
      'platform': platform,
      'agentEngineVersion': agentEngineVersion,
      if (isPartialExport != null) 'isPartialExport': isPartialExport,
      if (selectedIntegrations != null) 'selectedIntegrations': selectedIntegrations,
      if (isTemplate != null) 'isTemplate': isTemplate,
    };
  }
  
  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      exportedBy: json['exportedBy'],
      platform: json['platform'],
      agentEngineVersion: json['agentEngineVersion'],
      isPartialExport: json['isPartialExport'],
      selectedIntegrations: json['selectedIntegrations']?.cast<String>(),
      isTemplate: json['isTemplate'],
    );
  }
}

class ImportResult {
  final int totalConfigurations;
  final List<SingleImportResult> successfulImports;
  final List<SingleImportResult> failedImports;
  final List<SingleImportResult> skippedImports;
  final List<SingleImportResult> conflicts;
  
  ImportResult({
    required this.totalConfigurations,
    required this.successfulImports,
    required this.failedImports,
    required this.skippedImports,
    required this.conflicts,
  });
  
  bool get hasConflicts => conflicts.isNotEmpty;
  bool get isSuccess => failedImports.isEmpty;
  int get successCount => successfulImports.length;
  int get failureCount => failedImports.length;
}

class SingleImportResult {
  final String integrationId;
  final ImportStatus status;
  final String? message;
  final String? error;
  
  const SingleImportResult({
    required this.integrationId,
    required this.status,
    this.message,
    this.error,
  });
}

class BackupInfo {
  final String filename;
  final String filePath;
  final DateTime timestamp;
  final int totalIntegrations;
  final int fileSize;
  final String version;
  final bool isPartialExport;
  
  const BackupInfo({
    required this.filename,
    required this.filePath,
    required this.timestamp,
    required this.totalIntegrations,
    required this.fileSize,
    required this.version,
    required this.isPartialExport,
  });
  
  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class BackupValidation {
  final bool isValid;
  final String version;
  final bool isCompatible;
  final int totalConfigurations;
  final List<String> compatibleIntegrations;
  final List<String> incompatibleIntegrations;
  final List<ValidationIssue> issues;
  final BackupMetadata metadata;
  
  const BackupValidation({
    required this.isValid,
    required this.version,
    required this.isCompatible,
    required this.totalConfigurations,
    required this.compatibleIntegrations,
    required this.incompatibleIntegrations,
    required this.issues,
    required this.metadata,
  });
}

enum ImportStatus {
  success,
  failed,
  skipped,
  conflict,
}

enum ConflictResolution {
  replace,
  merge,
  skip,
  rename,
}

class IntegrationBackupException implements Exception {
  final String message;
  
  const IntegrationBackupException(this.message);
  
  @override
  String toString() => 'IntegrationBackupException: $message';
}

// Provider
final integrationBackupServiceProvider = Provider<IntegrationBackupService>((ref) {
  final integrationService = ref.watch(integrationServiceProvider);
  final mcpService = ref.watch(mcpSettingsServiceProvider);
  return IntegrationBackupService(integrationService, mcpService);
});