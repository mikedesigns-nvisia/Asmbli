import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/agent_engine_core.dart';
import 'integration_service.dart';
import 'mcp_settings_service.dart';

/// Service for managing integration dependencies and requirements
class IntegrationDependencyService {
  final IntegrationService _integrationService;
  final MCPSettingsService _mcpService;
  
  // Dependency graph
  final Map<String, IntegrationDependency> _dependencies = {};
  
  IntegrationDependencyService(this._integrationService, this._mcpService) {
    _initializeDependencies();
  }
  
  /// Initialize dependency definitions
  void _initializeDependencies() {
    // Define dependencies between integrations
    
    // GitHub depends on Git
    _dependencies['github'] = const IntegrationDependency(
      integrationId: 'github',
      requires: ['git'],
      optionalRequires: ['filesystem'],
      conflicts: [],
      setupOrder: 2,
    );
    
    // Figma may benefit from filesystem for exports
    _dependencies['figma'] = const IntegrationDependency(
      integrationId: 'figma',
      requires: [],
      optionalRequires: ['filesystem'],
      conflicts: [],
      setupOrder: 3,
    );
    
    // Slack can integrate with other services
    _dependencies['slack'] = const IntegrationDependency(
      integrationId: 'slack',
      requires: [],
      optionalRequires: ['github', 'linear', 'notion'],
      conflicts: [],
      setupOrder: 4,
    );
    
    // Notion can sync with other tools
    _dependencies['notion'] = const IntegrationDependency(
      integrationId: 'notion',
      requires: [],
      optionalRequires: ['github', 'linear', 'slack'],
      conflicts: [],
      setupOrder: 4,
    );
    
    // Linear project management
    _dependencies['linear'] = const IntegrationDependency(
      integrationId: 'linear',
      requires: [],
      optionalRequires: ['github', 'slack', 'notion'],
      conflicts: [],
      setupOrder: 4,
    );
    
    // Database integrations
    _dependencies['postgresql'] = const IntegrationDependency(
      integrationId: 'postgresql',
      requires: [],
      optionalRequires: [],
      conflicts: ['mysql', 'mongodb'], // Usually only one DB at a time
      setupOrder: 1,
    );
    
    _dependencies['mysql'] = const IntegrationDependency(
      integrationId: 'mysql',
      requires: [],
      optionalRequires: [],
      conflicts: ['postgresql', 'mongodb'],
      setupOrder: 1,
    );
    
    _dependencies['mongodb'] = const IntegrationDependency(
      integrationId: 'mongodb',
      requires: [],
      optionalRequires: [],
      conflicts: ['postgresql', 'mysql'],
      setupOrder: 1,
    );
    
    // Memory/AI integrations
    _dependencies['memory'] = const IntegrationDependency(
      integrationId: 'memory',
      requires: [],
      optionalRequires: ['filesystem'],
      conflicts: [],
      setupOrder: 1,
    );
    
    _dependencies['sequential-thinking'] = const IntegrationDependency(
      integrationId: 'sequential-thinking',
      requires: [],
      optionalRequires: ['memory'],
      conflicts: [],
      setupOrder: 5,
    );
    
    // Local services
    _dependencies['filesystem'] = const IntegrationDependency(
      integrationId: 'filesystem',
      requires: [],
      optionalRequires: [],
      conflicts: [],
      setupOrder: 0, // Base service, should be set up first
    );
    
    _dependencies['git'] = const IntegrationDependency(
      integrationId: 'git',
      requires: [],
      optionalRequires: ['filesystem'],
      conflicts: [],
      setupOrder: 1,
    );
    
    _dependencies['terminal'] = const IntegrationDependency(
      integrationId: 'terminal',
      requires: [],
      optionalRequires: ['filesystem'],
      conflicts: [],
      setupOrder: 1,
    );
    
    // Utility services
    _dependencies['web-search'] = const IntegrationDependency(
      integrationId: 'web-search',
      requires: [],
      optionalRequires: [],
      conflicts: [],
      setupOrder: 2,
    );
    
    _dependencies['http-client'] = const IntegrationDependency(
      integrationId: 'http-client',
      requires: [],
      optionalRequires: [],
      conflicts: [],
      setupOrder: 2,
    );
    
    _dependencies['calendar'] = const IntegrationDependency(
      integrationId: 'calendar',
      requires: [],
      optionalRequires: ['notion', 'slack'],
      conflicts: [],
      setupOrder: 3,
    );
    
    _dependencies['time'] = const IntegrationDependency(
      integrationId: 'time',
      requires: [],
      optionalRequires: [],
      conflicts: [],
      setupOrder: 0,
    );
  }
  
  /// Get dependency information for an integration
  IntegrationDependency? getDependency(String integrationId) {
    return _dependencies[integrationId];
  }
  
  /// Check if all required dependencies are satisfied
  DependencyCheckResult checkDependencies(String integrationId) {
    final dependency = _dependencies[integrationId];
    if (dependency == null) {
      // No dependencies defined, assume OK
      return const DependencyCheckResult(
        canInstall: true,
        missingRequired: [],
        missingOptional: [],
        conflicts: [],
      );
    }
    
    final configuredIntegrations = _integrationService.getConfiguredIntegrations();
    final configuredIds = configuredIntegrations.map((i) => i.definition.id).toSet();
    
    // Check required dependencies
    final missingRequired = dependency.requires
        .where((reqId) => !configuredIds.contains(reqId))
        .toList();
    
    // Check optional dependencies
    final missingOptional = dependency.optionalRequires
        .where((optId) => !configuredIds.contains(optId))
        .toList();
    
    // Check conflicts
    final conflicts = dependency.conflicts
        .where((conflictId) => configuredIds.contains(conflictId))
        .toList();
    
    return DependencyCheckResult(
      canInstall: missingRequired.isEmpty && conflicts.isEmpty,
      missingRequired: missingRequired,
      missingOptional: missingOptional,
      conflicts: conflicts,
    );
  }
  
  /// Get installation order for a set of integrations
  List<String> getInstallationOrder(List<String> integrationIds) {
    // Build dependency graph
    final graph = <String, Set<String>>{};
    final inDegree = <String, int>{};
    
    for (final id in integrationIds) {
      graph[id] = {};
      inDegree[id] = 0;
    }
    
    // Add edges based on dependencies
    for (final id in integrationIds) {
      final dep = _dependencies[id];
      if (dep != null) {
        for (final reqId in dep.requires) {
          if (integrationIds.contains(reqId)) {
            graph[reqId]!.add(id);
            inDegree[id] = inDegree[id]! + 1;
          }
        }
      }
    }
    
    // Topological sort using Kahn's algorithm
    final queue = <String>[];
    final result = <String>[];
    
    // Find nodes with no dependencies
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }
    
    // Sort initial nodes by setup order
    queue.sort((a, b) {
      final orderA = _dependencies[a]?.setupOrder ?? 999;
      final orderB = _dependencies[b]?.setupOrder ?? 999;
      return orderA.compareTo(orderB);
    });
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);
      
      for (final neighbor in graph[current]!) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
      
      // Sort queue by setup order
      queue.sort((a, b) {
        final orderA = _dependencies[a]?.setupOrder ?? 999;
        final orderB = _dependencies[b]?.setupOrder ?? 999;
        return orderA.compareTo(orderB);
      });
    }
    
    // Check for cycles
    if (result.length != integrationIds.length) {
      // Cycle detected, return original order
      return integrationIds;
    }
    
    return result;
  }
  
  /// Get removal order (reverse of installation)
  List<String> getRemovalOrder(List<String> integrationIds) {
    return getInstallationOrder(integrationIds).reversed.toList();
  }
  
  /// Get dependent integrations (integrations that depend on this one)
  List<String> getDependents(String integrationId) {
    final dependents = <String>[];
    
    for (final entry in _dependencies.entries) {
      if (entry.value.requires.contains(integrationId)) {
        dependents.add(entry.key);
      }
    }
    
    return dependents;
  }
  
  /// Get all integrations that would be affected by removing this one
  AffectedIntegrations getAffectedByRemoval(String integrationId) {
    final directDependents = getDependents(integrationId);
    final allAffected = <String>{};
    final queue = [...directDependents];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!allAffected.contains(current)) {
        allAffected.add(current);
        queue.addAll(getDependents(current));
      }
    }
    
    return AffectedIntegrations(
      directDependents: directDependents,
      allAffected: allAffected.toList(),
    );
  }
  
  /// Get recommended integrations based on current setup
  List<IntegrationRecommendation> getRecommendations() {
    final recommendations = <IntegrationRecommendation>[];
    final configured = _integrationService.getConfiguredIntegrations();
    final configuredIds = configured.map((i) => i.definition.id).toSet();
    
    for (final integration in IntegrationRegistry.allIntegrations) {
      if (configuredIds.contains(integration.id)) continue;
      
      final dependency = _dependencies[integration.id];
      if (dependency == null) continue;
      
      // Check if this would complete optional dependencies for configured integrations
      int benefitCount = 0;
      final benefitsFor = <String>[];
      
      for (final configuredId in configuredIds) {
        final configDep = _dependencies[configuredId];
        if (configDep != null && configDep.optionalRequires.contains(integration.id)) {
          benefitCount++;
          benefitsFor.add(configuredId);
        }
      }
      
      // Check if all requirements are met
      final reqsMet = dependency.requires.every((req) => configuredIds.contains(req));
      
      if (benefitCount > 0 && reqsMet) {
        recommendations.add(IntegrationRecommendation(
          integrationId: integration.id,
          reason: 'Would enhance ${benefitsFor.map((id) => IntegrationRegistry.getById(id)?.name ?? id).join(", ")}',
          priority: benefitCount,
          requiredFirst: dependency.requires.where((req) => !configuredIds.contains(req)).toList(),
        ));
      }
    }
    
    // Sort by priority
    recommendations.sort((a, b) => b.priority.compareTo(a.priority));
    
    return recommendations;
  }
  
  /// Validate a proposed configuration change
  ValidationResult validateConfigurationChange({
    required List<String> toAdd,
    required List<String> toRemove,
  }) {
    final issues = <ValidationIssue>[];
    
    // Check removals
    for (final removeId in toRemove) {
      final affected = getAffectedByRemoval(removeId);
      if (affected.directDependents.isNotEmpty) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.error,
          integrationId: removeId,
          message: 'Cannot remove: required by ${affected.directDependents.join(", ")}',
          affectedIntegrations: affected.directDependents,
        ));
      }
    }
    
    // Check additions
    for (final addId in toAdd) {
      final depCheck = checkDependencies(addId);
      
      if (depCheck.missingRequired.isNotEmpty) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.error,
          integrationId: addId,
          message: 'Missing required dependencies: ${depCheck.missingRequired.join(", ")}',
          affectedIntegrations: depCheck.missingRequired,
        ));
      }
      
      if (depCheck.conflicts.isNotEmpty) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.warning,
          integrationId: addId,
          message: 'Conflicts with: ${depCheck.conflicts.join(", ")}',
          affectedIntegrations: depCheck.conflicts,
        ));
      }
      
      if (depCheck.missingOptional.isNotEmpty) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.info,
          integrationId: addId,
          message: 'Consider also installing: ${depCheck.missingOptional.join(", ")}',
          affectedIntegrations: depCheck.missingOptional,
        ));
      }
    }
    
    return ValidationResult(
      isValid: !issues.any((issue) => issue.severity == ValidationSeverity.error),
      issues: issues,
      suggestedOrder: getInstallationOrder(toAdd),
    );
  }
}

/// Integration dependency definition
class IntegrationDependency {
  final String integrationId;
  final List<String> requires; // Must be installed first
  final List<String> optionalRequires; // Recommended but not required
  final List<String> conflicts; // Cannot be installed together
  final int setupOrder; // Priority for setup (lower = earlier)
  
  const IntegrationDependency({
    required this.integrationId,
    required this.requires,
    required this.optionalRequires,
    required this.conflicts,
    required this.setupOrder,
  });
}

/// Result of dependency check
class DependencyCheckResult {
  final bool canInstall;
  final List<String> missingRequired;
  final List<String> missingOptional;
  final List<String> conflicts;
  
  const DependencyCheckResult({
    required this.canInstall,
    required this.missingRequired,
    required this.missingOptional,
    required this.conflicts,
  });
}

/// Integrations affected by a change
class AffectedIntegrations {
  final List<String> directDependents;
  final List<String> allAffected;
  
  const AffectedIntegrations({
    required this.directDependents,
    required this.allAffected,
  });
}

/// Integration recommendation
class IntegrationRecommendation {
  final String integrationId;
  final String reason;
  final int priority;
  final List<String> requiredFirst;
  
  const IntegrationRecommendation({
    required this.integrationId,
    required this.reason,
    required this.priority,
    required this.requiredFirst,
  });
}

/// Validation result for configuration changes
class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> issues;
  final List<String> suggestedOrder;
  
  const ValidationResult({
    required this.isValid,
    required this.issues,
    required this.suggestedOrder,
  });
}

/// Validation issue
class ValidationIssue {
  final ValidationSeverity severity;
  final String integrationId;
  final String message;
  final List<String> affectedIntegrations;
  
  const ValidationIssue({
    required this.severity,
    required this.integrationId,
    required this.message,
    required this.affectedIntegrations,
  });
}

/// Validation severity levels
enum ValidationSeverity {
  info,
  warning,
  error,
}

// Provider
final integrationDependencyServiceProvider = Provider<IntegrationDependencyService>((ref) {
  final integrationService = ref.watch(integrationServiceProvider);
  final mcpService = ref.watch(mcpSettingsServiceProvider);
  return IntegrationDependencyService(integrationService, mcpService);
});