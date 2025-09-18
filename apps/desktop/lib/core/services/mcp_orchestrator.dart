import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../models/mcp_capability.dart';
import '../data/mcp_server_configs.dart';
import 'mcp_installation_service.dart';
import 'mcp_safety_service.dart';
import 'mcp_user_interface_service.dart';
import '../di/service_locator.dart';

/// Anthropic PM-style MCP Orchestrator
/// 
/// This service provides "magic mode" MCP server management:
/// - One-click capability enablement
/// - Hides technical complexity from users
/// - Provides friendly progress updates
/// - Handles errors gracefully with recovery suggestions
class MCPOrchestrator {
  final MCPSafetyService _safetyService;
  final MCPUserInterfaceService _uiService;
  final StreamController<MCPOrchestrationEvent> _eventController;

  MCPOrchestrator(this._safetyService, this._uiService) 
    : _eventController = StreamController<MCPOrchestrationEvent>.broadcast();

  /// Stream of orchestration events for UI updates
  Stream<MCPOrchestrationEvent> get events => _eventController.stream;

  /// Enable a capability for an agent (Magic Mode)
  /// 
  /// This is the main entry point - users just say "I want code analysis"
  /// and this method handles all the complexity behind the scenes
  Future<CapabilityResult> enableCapability(
    AgentCapability capability, 
    Agent agent,
    {bool skipUserApproval = false}
  ) async {
    try {
      _emitEvent(MCPOrchestrationEvent.started(capability));
      
      // Step 1: Safety check - can we do this?
      final safetyCheck = await _safetyService.canEnableCapability(capability, agent);
      if (!safetyCheck.isAllowed) {
        return CapabilityResult.blocked(safetyCheck.reason ?? 'Safety check failed');
      }
      
      // Step 2: Get user approval if needed (unless auto-approved)
      if (!skipUserApproval && safetyCheck.requiresUserApproval) {
        final approved = await _uiService.requestCapabilityPermission(
          capability, 
          safetyCheck.explanation
        );
        if (!approved) {
          return CapabilityResult.cancelled();
        }
      }
      
      // Step 3: Show friendly progress to user
      _uiService.showCapabilityProgress(capability, 'Setting up ${capability.displayName}...');
      
      // Step 4: Get required MCP servers for this capability
      final requiredServers = _getServersForCapability(capability);
      
      // Step 5: Install servers with friendly progress updates
      final installResults = <String, bool>{};
      final errors = <String, String>{};
      
      for (final server in requiredServers) {
        _uiService.showCapabilityProgress(
          capability, 
          'Configuring ${server.name}...'
        );
        
        try {
          final installed = await _installServerSafely(server, agent);
          installResults[server.id] = installed;
          
          if (installed) {
            _uiService.showCapabilityProgress(
              capability,
              '✅ ${server.name} ready'
            );
          } else {
            errors[server.id] = 'Installation failed';
          }
        } catch (e) {
          errors[server.id] = e.toString();
          installResults[server.id] = false;
        }
      }
      
      // Step 6: Check if capability is fully enabled
      final successCount = installResults.values.where((success) => success).length;
      final totalCount = requiredServers.length;
      
      if (successCount == totalCount) {
        _uiService.showCapabilitySuccess(capability);
        _emitEvent(MCPOrchestrationEvent.completed(capability));
        return CapabilityResult.success(
          message: '🚀 ${capability.displayName} is ready to use!'
        );
      } else if (successCount > 0) {
        // Partial success - some servers installed
        _uiService.showCapabilityPartialSuccess(capability, successCount, totalCount);
        _emitEvent(MCPOrchestrationEvent.partialSuccess(capability, errors));
        return CapabilityResult.partialSuccess(
          message: '⚠️ ${capability.displayName} is partially available',
          errors: errors
        );
      } else {
        // Complete failure - provide helpful recovery suggestions
        final recovery = _generateRecoverySuggestions(errors);
        _uiService.showCapabilityError(capability, recovery);
        _emitEvent(MCPOrchestrationEvent.failed(capability, errors));
        return CapabilityResult.failed(
          message: '❌ Could not set up ${capability.displayName}',
          errors: errors,
          recoverySuggestions: recovery
        );
      }
      
    } catch (e) {
      _emitEvent(MCPOrchestrationEvent.error(capability, e.toString()));
      return CapabilityResult.error(e.toString());
    }
  }

  /// Check what capabilities an agent currently has available
  Future<List<AgentCapability>> getAvailableCapabilities(Agent agent) async {
    final allCapabilities = AgentCapability.getAllCapabilities();
    final available = <AgentCapability>[];
    
    for (final capability in allCapabilities) {
      final requiredServers = _getServersForCapability(capability);
      final hasAllServers = await _checkServersInstalled(requiredServers);
      
      if (hasAllServers) {
        available.add(capability);
      }
    }
    
    return available;
  }

  /// Suggest capabilities based on user request
  List<AgentCapability> suggestCapabilities(String userRequest) {
    final suggestions = <AgentCapability>[];
    final request = userRequest.toLowerCase();
    
    // Smart matching based on user intent
    if (request.contains('code') || request.contains('repository') || request.contains('git')) {
      suggestions.addAll([
        AgentCapability.codeAnalysis,
        AgentCapability.gitIntegration,
        AgentCapability.fileAccess
      ]);
    }
    
    if (request.contains('web') || request.contains('search') || request.contains('browse')) {
      suggestions.addAll([
        AgentCapability.webSearch,
        AgentCapability.webScraping
      ]);
    }
    
    if (request.contains('database') || request.contains('data') || request.contains('sql')) {
      suggestions.add(AgentCapability.databaseAccess);
    }
    
    if (request.contains('memory') || request.contains('remember') || request.contains('context')) {
      suggestions.add(AgentCapability.persistentMemory);
    }
    
    return suggestions.toSet().toList(); // Remove duplicates
  }

  /// Install a server safely with progress updates
  Future<bool> _installServerSafely(MCPServerLibraryConfig server, Agent agent) async {
    try {
      // Check if already installed
      final installationService = ServiceLocator.instance.get<MCPInstallationService>();
      final requirements = await installationService.checkAgentMCPRequirements(agent.id);

      // Check if server is already in requirements
      if (requirements.contains(server.id)) {
        return true; // Already installed
      }

      // Install the server
      await installationService.installMCPServers(agent.id, [server.id]);
      return true;
    } catch (e) {
      print('Error installing server ${server.id}: $e');
      return false;
    }
  }

  /// Get MCP servers required for a capability
  List<MCPServerLibraryConfig> _getServersForCapability(AgentCapability capability) {
    final serverIds = capability.requiredMCPServers;
    return serverIds
        .map((id) => MCPServerLibrary.getServer(id))
        .where((server) => server != null)
        .cast<MCPServerLibraryConfig>()
        .toList();
  }

  /// Check if all required servers are installed
  Future<bool> _checkServersInstalled(List<MCPServerLibraryConfig> servers) async {
    for (final server in servers) {
      // Simple check - if we can find the server config, assume it's available
      final serverConfig = MCPServerLibrary.getServer(server.id);
      if (serverConfig == null) return false;
    }
    return true;
  }

  /// Generate helpful recovery suggestions when installation fails
  List<String> _generateRecoverySuggestions(Map<String, String> errors) {
    final suggestions = <String>[];
    
    // Check for common issues
    if (errors.values.any((error) => error.contains('npm') || error.contains('npx'))) {
      suggestions.add('Install Node.js from https://nodejs.org');
      suggestions.add('Restart the application after installing Node.js');
    }
    
    if (errors.values.any((error) => error.contains('pip') || error.contains('python'))) {
      suggestions.add('Install Python from https://python.org');
      suggestions.add('Make sure Python is added to your PATH');
    }
    
    if (errors.values.any((error) => error.contains('git'))) {
      suggestions.add('Install Git from https://git-scm.com');
    }
    
    if (errors.values.any((error) => error.contains('permission') || error.contains('access'))) {
      suggestions.add('Try running as administrator');
      suggestions.add('Check firewall and antivirus settings');
    }
    
    // Always provide these general suggestions
    suggestions.addAll([
      'Check your internet connection',
      'Try again in a few moments',
      'Contact support if the problem persists'
    ]);
    
    return suggestions;
  }

  void _emitEvent(MCPOrchestrationEvent event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}

/// Result of enabling a capability
class CapabilityResult {
  final bool success;
  final String message;
  final Map<String, String> errors;
  final List<String> recoverySuggestions;
  final CapabilityResultType type;

  const CapabilityResult._({
    required this.success,
    required this.message,
    required this.errors,
    required this.recoverySuggestions,
    required this.type,
  });

  factory CapabilityResult.success({required String message}) {
    return CapabilityResult._(
      success: true,
      message: message,
      errors: {},
      recoverySuggestions: [],
      type: CapabilityResultType.success,
    );
  }

  factory CapabilityResult.partialSuccess({
    required String message,
    required Map<String, String> errors,
  }) {
    return CapabilityResult._(
      success: true,
      message: message,
      errors: errors,
      recoverySuggestions: [],
      type: CapabilityResultType.partialSuccess,
    );
  }

  factory CapabilityResult.failed({
    required String message,
    required Map<String, String> errors,
    required List<String> recoverySuggestions,
  }) {
    return CapabilityResult._(
      success: false,
      message: message,
      errors: errors,
      recoverySuggestions: recoverySuggestions,
      type: CapabilityResultType.failed,
    );
  }

  factory CapabilityResult.blocked(String reason) {
    return CapabilityResult._(
      success: false,
      message: 'Not allowed: $reason',
      errors: {'security': reason},
      recoverySuggestions: ['Check security settings', 'Contact administrator'],
      type: CapabilityResultType.blocked,
    );
  }

  factory CapabilityResult.cancelled() {
    return const CapabilityResult._(
      success: false,
      message: 'Cancelled by user',
      errors: {},
      recoverySuggestions: [],
      type: CapabilityResultType.cancelled,
    );
  }

  factory CapabilityResult.error(String error) {
    return CapabilityResult._(
      success: false,
      message: 'An error occurred: $error',
      errors: {'system': error},
      recoverySuggestions: ['Try again', 'Contact support'],
      type: CapabilityResultType.error,
    );
  }
}

enum CapabilityResultType {
  success,
  partialSuccess,
  failed,
  blocked,
  cancelled,
  error,
}

/// Events emitted during orchestration for UI updates
class MCPOrchestrationEvent {
  final AgentCapability capability;
  final MCPEventType type;
  final String? message;
  final Map<String, String>? errors;

  const MCPOrchestrationEvent._({
    required this.capability,
    required this.type,
    this.message,
    this.errors,
  });

  factory MCPOrchestrationEvent.started(AgentCapability capability) {
    return MCPOrchestrationEvent._(
      capability: capability,
      type: MCPEventType.started,
    );
  }

  factory MCPOrchestrationEvent.completed(AgentCapability capability) {
    return MCPOrchestrationEvent._(
      capability: capability,
      type: MCPEventType.completed,
    );
  }

  factory MCPOrchestrationEvent.partialSuccess(
    AgentCapability capability, 
    Map<String, String> errors
  ) {
    return MCPOrchestrationEvent._(
      capability: capability,
      type: MCPEventType.partialSuccess,
      errors: errors,
    );
  }

  factory MCPOrchestrationEvent.failed(
    AgentCapability capability, 
    Map<String, String> errors
  ) {
    return MCPOrchestrationEvent._(
      capability: capability,
      type: MCPEventType.failed,
      errors: errors,
    );
  }

  factory MCPOrchestrationEvent.error(AgentCapability capability, String message) {
    return MCPOrchestrationEvent._(
      capability: capability,
      type: MCPEventType.error,
      message: message,
    );
  }
}

enum MCPEventType {
  started,
  completed,
  partialSuccess,
  failed,
  error,
}

/// Provider for MCP Orchestrator
final mcpOrchestratorProvider = Provider<MCPOrchestrator>((ref) {
  final safetyService = ref.watch(mcpSafetyServiceProvider);
  final uiService = ref.watch(mcpUserInterfaceServiceProvider);
  return MCPOrchestrator(safetyService, uiService);
});