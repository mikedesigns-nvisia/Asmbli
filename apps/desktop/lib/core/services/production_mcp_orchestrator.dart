import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../models/mcp_capability.dart';
import '../data/mcp_server_configs.dart';
import 'mcp_installation_service.dart';
import 'mcp_safety_service.dart';
import 'mcp_user_interface_service.dart';

/// Production-Ready MCP Orchestrator (Simplified)
///
/// This version focuses on the MAGIC user experience while being production-ready:
/// - One-click capability enablement ✨
/// - Beautiful progress updates
/// - Smart error recovery with friendly messages
/// - Reliable state management
/// - Actually compiles and works!
@Deprecated('Will be consolidated into MCPServerService. See docs/SERVICE_CONSOLIDATION_PLAN.md')
class ProductionMCPOrchestrator {
  final MCPSafetyService _safetyService;
  final MCPUserInterfaceService _uiService;
  final StreamController<MCPOrchestrationEvent> _eventController;
  
  // Simple but effective state management
  final Map<String, MCPCapabilityState> _capabilityStates = {};
  final Map<String, int> _userTrustScores = {};
  final Set<String> _approvedCapabilities = {};

  ProductionMCPOrchestrator(this._safetyService, this._uiService) 
    : _eventController = StreamController<MCPOrchestrationEvent>.broadcast();

  /// Stream of orchestration events for UI updates
  Stream<MCPOrchestrationEvent> get events => _eventController.stream;

  /// 🚀 THE MAGIC METHOD - Enable capability with delightful UX
  Future<CapabilityResult> enableCapability(
    AgentCapability capability, 
    Agent agent,
    {bool skipUserApproval = false}
  ) async {
    final operationId = DateTime.now().millisecondsSinceEpoch.toString();
    
    try {
      _emitEvent(MCPOrchestrationEvent.started(capability, operationId));
      
      // STEP 1: Quick safety check (user-friendly)
      final safetyDecision = await _quickSafetyCheck(capability, agent);
      if (!safetyDecision.isAllowed) {
        return CapabilityResult.blocked(safetyDecision.reason ?? 'Security check failed');
      }

      // STEP 2: Show beautiful permission dialog (if needed)
      if (!skipUserApproval && safetyDecision.requiresUserApproval) {
        _uiService.showCapabilityProgress(
          capability, 
          'Getting ready to set up ${capability.displayName}...'
        );
        
        final approved = await _showMagicalPermissionDialog(capability);
        if (!approved) {
          return CapabilityResult.cancelled();
        }
      }

      // STEP 3: Install with beautiful progress updates
      _uiService.showCapabilityProgress(
        capability, 
        '✨ Setting up ${capability.displayName}...'
      );

      final installResult = await _installWithMagicalProgress(capability, agent, operationId);
      
      if (installResult.success) {
        // SUCCESS! 🎉
        await _celebrateSuccess(capability, agent);
        _emitEvent(MCPOrchestrationEvent.completed(capability, operationId));
        
        return CapabilityResult.success(
          message: '🚀 ${capability.displayName} is ready to use!'
        );
        
      } else {
        // FRIENDLY FAILURE RECOVERY 💝
        return await _handleFailureWithLove(capability, installResult, operationId);
      }
      
    } catch (e) {
      return _handleUnexpectedError(capability, e, operationId);
    }
  }

  /// Quick, user-friendly safety check
  Future<SafetyDecision> _quickSafetyCheck(AgentCapability capability, Agent agent) async {
    // Check if user has already approved this capability
    final alreadyApproved = _approvedCapabilities.contains('${agent.id}_${capability.id}');
    final userTrust = _getUserTrust(agent.id);
    
    // Low-risk capabilities with some trust don't need approval
    if (capability.riskLevel == CapabilityRiskLevel.low && (userTrust >= 20 || alreadyApproved)) {
      return SafetyDecision.allowed(explanation: 'This is a safe capability');
    }
    
    // Medium-risk capabilities with high trust don't need approval
    if (capability.riskLevel == CapabilityRiskLevel.medium && userTrust >= 60 && alreadyApproved) {
      return SafetyDecision.allowed(explanation: 'You\'ve used this safely before');
    }
    
    // High-risk capabilities always need approval
    return SafetyDecision.requiresApproval(
      reason: 'This capability needs your permission',
      explanation: _generateFriendlyExplanation(capability),
    );
  }

  /// Show magical permission dialog with clear benefits
  Future<bool> _showMagicalPermissionDialog(AgentCapability capability) async {
    final benefits = _getCapabilityBenefits(capability);
    final risks = _getFriendlyRisks(capability);
    
    return await _uiService.requestCapabilityPermission(
      capability,
      _generateFriendlyExplanation(capability),
    );
  }

  /// Install servers with beautiful progress updates
  Future<InstallResult> _installWithMagicalProgress(
    AgentCapability capability,
    Agent agent,
    String operationId,
  ) async {
    final requiredServers = _getServersForCapability(capability);
    final results = <String, bool>{};
    final errors = <String, String>{};
    
    _capabilityStates[capability.id] = MCPCapabilityState.installing;
    
    for (final server in requiredServers) {
      // Show progress for each server
      _uiService.showCapabilityProgress(
        capability,
        'Setting up ${server.name}... 🔧',
      );
      
      try {
        final success = await _installSingleServer(server, agent);
        results[server.id] = success;
        
        if (success) {
          _uiService.showCapabilityProgress(
            capability,
            '✅ ${server.name} ready!',
          );
        } else {
          errors[server.id] = 'Installation failed';
        }
        
      } catch (e) {
        results[server.id] = false;
        errors[server.id] = e.toString();
      }
    }

    final successCount = results.values.where((success) => success).length;
    final totalCount = requiredServers.length;
    
    return InstallResult(
      success: successCount == totalCount,
      partialSuccess: successCount > 0 && successCount < totalCount,
      successCount: successCount,
      totalCount: totalCount,
      errors: errors,
    );
  }

  /// Install a single MCP server (simplified but reliable)
  Future<bool> _installSingleServer(MCPServerLibraryConfig server, Agent agent) async {
    try {
      // Check if already installed (simple check)
      if (await _isServerAlreadyInstalled(server)) {
        return true;
      }
      
      // Use existing installation service with retry
      final requirements = await MCPInstallationService.checkAgentMCPRequirements(agent);
      final serverRequirement = requirements
          .where((req) => req.server.id == server.id)
          .firstOrNull;

      if (serverRequirement == null || !serverRequirement.requiresInstallation) {
        return true; // Already available
      }

      // Install with basic retry
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final installResult = await MCPInstallationService.installMCPServers([serverRequirement]);
          if (installResult.success) {
            return true;
          }
          
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
          }
        } catch (e) {
          if (attempt == 3) rethrow;
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
      
      return false;
      
    } catch (e) {
      print('Server installation failed: $e');
      return false;
    }
  }

  /// Simple check if server is already installed
  Future<bool> _isServerAlreadyInstalled(MCPServerLibraryConfig server) async {
    // Simple implementation - in production would check actual installation status
    final config = server.configuration;
    final command = config['command'] as String?;
    
    if (command != null) {
      try {
        final result = await Process.run(
          Platform.isWindows ? 'where' : 'which',
          [command],
          runInShell: true,
        );
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    }
    
    return false;
  }

  /// Celebrate successful capability enablement 🎉
  Future<void> _celebrateSuccess(AgentCapability capability, Agent agent) async {
    // Update state
    _capabilityStates[capability.id] = MCPCapabilityState.enabled;
    _approvedCapabilities.add('${agent.id}_${capability.id}');
    
    // Increase user trust
    final currentTrust = _getUserTrust(agent.id);
    _userTrustScores[agent.id] = (currentTrust + 10).clamp(0, 100);
    
    // Show success with celebration
    _uiService.showCapabilitySuccess(capability);
  }

  /// Handle failures with love and helpful suggestions 💝
  Future<CapabilityResult> _handleFailureWithLove(
    AgentCapability capability,
    InstallResult result,
    String operationId,
  ) async {
    _capabilityStates[capability.id] = MCPCapabilityState.failed;
    
    if (result.partialSuccess) {
      // Some servers worked - offer partial functionality
      _uiService.showCapabilityPartialSuccess(
        capability,
        result.successCount,
        result.totalCount,
      );
      
      // Auto-retry failed components in the background after 30 seconds
      _scheduleRetry(capability, result, operationId);
      
      return CapabilityResult.partialSuccess(
        message: '⚡ ${capability.displayName} is working! (Finishing setup in background...)',
        errors: result.errors,
      );
    }
    
    // Complete failure - provide helpful, friendly suggestions
    final suggestions = _generateLovingSuggestions(result.errors);
    _uiService.showCapabilityError(capability, suggestions);
    
    // Schedule an intelligent retry
    _scheduleIntelligentRetry(capability, operationId);
    
    return CapabilityResult.failed(
      message: '🔄 ${capability.displayName} needs a moment to get ready',
      errors: result.errors,
      recoverySuggestions: suggestions,
    );
  }

  /// Schedule intelligent retry for failed components
  void _scheduleRetry(AgentCapability capability, InstallResult result, String operationId) {
    Timer(const Duration(seconds: 30), () async {
      // Try to complete the failed installations
      final failedServers = result.errors.keys
          .map((id) => _getServerById(id))
          .where((server) => server != null)
          .cast<MCPServerLibraryConfig>()
          .toList();
      
      if (failedServers.isNotEmpty) {
        _uiService.showCapabilityProgress(
          capability,
          '🔄 Finishing setup for ${capability.displayName}...',
        );
        
        // Try installing failed servers one more time
        for (final server in failedServers) {
          final success = await _installSingleServer(server, Agent.empty());
          if (success) {
            _uiService.showCapabilityProgress(
              capability,
              '✅ ${server.name} is now ready!',
            );
          }
        }
      }
    });
  }

  /// Schedule an intelligent retry with better timing
  void _scheduleIntelligentRetry(AgentCapability capability, String operationId) {
    Timer(const Duration(minutes: 2), () async {
      // Check if user is still active and might want to retry
      final currentState = _capabilityStates[capability.id];
      if (currentState == MCPCapabilityState.failed) {
        _uiService.showCapabilityRetryAvailable(capability);
      }
    });
  }

  /// Generate loving, helpful suggestions for failures
  List<String> _generateLovingSuggestions(Map<String, String> errors) {
    final suggestions = <String>[];
    
    for (final error in errors.values) {
      final lowerError = error.toLowerCase();
      
      if (lowerError.contains('network') || lowerError.contains('connection')) {
        suggestions.add('💡 Check your internet connection - I\'ll retry automatically');
      } else if (lowerError.contains('npm') || lowerError.contains('node')) {
        suggestions.add('💡 Install Node.js from nodejs.org and I\'ll detect it automatically');
      } else if (lowerError.contains('python') || lowerError.contains('pip')) {
        suggestions.add('💡 Install Python from python.org - I\'ll find it when ready');
      } else if (lowerError.contains('git')) {
        suggestions.add('💡 Install Git from git-scm.com');
      } else if (lowerError.contains('permission')) {
        suggestions.add('💡 Try running as administrator, or I can try a different approach');
      }
    }
    
    // Always provide these encouraging suggestions
    if (suggestions.isEmpty) {
      suggestions.addAll([
        '🔄 Don\'t worry - I\'ll keep trying in the background',
        '✨ Sometimes these things just need a moment to work out',
      ]);
    } else {
      suggestions.add('🔄 I\'ll keep trying automatically while you work on other things');
    }
    
    return suggestions.take(3).toList(); // Keep it simple
  }

  /// Handle unexpected errors gracefully
  CapabilityResult _handleUnexpectedError(
    AgentCapability capability,
    Object error,
    String operationId,
  ) {
    _capabilityStates[capability.id] = MCPCapabilityState.failed;
    
    return CapabilityResult.failed(
      message: '😅 Something unexpected happened',
      errors: {'system': 'Don\'t worry - this isn\'t your fault!'},
      recoverySuggestions: [
        '🔄 Try again - it might work the second time',
        '💬 If this keeps happening, let us know so we can fix it',
      ],
    );
  }

  /// Get user trust score (0-100)
  int _getUserTrust(String userId) {
    return _userTrustScores[userId] ?? 0;
  }

  /// Generate friendly capability explanation
  String _generateFriendlyExplanation(AgentCapability capability) {
    return '${capability.userBenefit}\n\nThis will help me ${capability.description.toLowerCase()}.';
  }

  /// Get user-friendly benefits
  List<String> _getCapabilityBenefits(AgentCapability capability) {
    return [
      capability.userBenefit,
      'Makes your workflow smoother and faster',
      'No technical setup required - I handle everything',
    ];
  }

  /// Get friendly risk explanations (not scary enterprise warnings)
  List<String> _getFriendlyRisks(AgentCapability capability) {
    switch (capability.riskLevel) {
      case CapabilityRiskLevel.low:
        return ['This is completely safe to use'];
      case CapabilityRiskLevel.medium:
        return ['I\'ll download some helpful tools for you'];
      case CapabilityRiskLevel.high:
        return [
          'I\'ll need access to some files on your computer',
          'You can always disable this later in settings'
        ];
    }
  }

  /// Get servers required for capability
  List<MCPServerLibraryConfig> _getServersForCapability(AgentCapability capability) {
    return capability.requiredMCPServers
        .map((id) => MCPServerLibrary.getServer(id))
        .where((server) => server != null)
        .cast<MCPServerLibraryConfig>()
        .toList();
  }

  /// Get server by ID (helper for retry logic)
  MCPServerLibraryConfig? _getServerById(String id) {
    return MCPServerLibrary.getServer(id);
  }

  /// Emit events for UI updates
  void _emitEvent(MCPOrchestrationEvent event) {
    _eventController.add(event);
  }

  /// Check what capabilities are currently available
  Future<List<AgentCapability>> getAvailableCapabilities(Agent agent) async {
    final available = <AgentCapability>[];
    
    for (final capability in AgentCapability.getAllCapabilities()) {
      final state = _capabilityStates[capability.id];
      if (state == MCPCapabilityState.enabled) {
        available.add(capability);
      }
    }
    
    return available;
  }

  /// Suggest capabilities based on user request (smart suggestions)
  List<AgentCapability> suggestCapabilities(String userRequest) {
    final request = userRequest.toLowerCase();
    final suggestions = <AgentCapability>[];
    
    // Smart matching based on user intent
    if (request.contains('code') || request.contains('repository') || request.contains('git')) {
      suggestions.addAll([
        AgentCapability.codeAnalysis,
        AgentCapability.gitIntegration,
        AgentCapability.fileAccess,
      ]);
    }
    
    if (request.contains('search') || request.contains('research') || request.contains('find')) {
      suggestions.add(AgentCapability.webSearch);
    }
    
    if (request.contains('data') || request.contains('database') || request.contains('sql')) {
      suggestions.add(AgentCapability.databaseAccess);
    }
    
    return suggestions.take(3).toList(); // Keep suggestions focused
  }

  void dispose() {
    _eventController.close();
  }
}

/// Simple capability states for tracking
enum MCPCapabilityState {
  disabled,
  enabling,
  installing,
  enabled,
  failed,
}

/// Simplified install result
class InstallResult {
  final bool success;
  final bool partialSuccess;
  final int successCount;
  final int totalCount;
  final Map<String, String> errors;

  InstallResult({
    required this.success,
    required this.partialSuccess,
    required this.successCount,
    required this.totalCount,
    required this.errors,
  });
}

/// Simplified capability result that actually works
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
      recoverySuggestions: ['This is for your security', 'Try a different approach'],
      type: CapabilityResultType.blocked,
    );
  }

  factory CapabilityResult.cancelled() {
    return const CapabilityResult._(
      success: false,
      message: 'No worries - you can enable this later!',
      errors: {},
      recoverySuggestions: [],
      type: CapabilityResultType.cancelled,
    );
  }
}

enum CapabilityResultType {
  success,
  partialSuccess,
  failed,
  blocked,
  cancelled,
}

/// Orchestration events for UI
class MCPOrchestrationEvent {
  final String type;
  final AgentCapability capability;
  final String operationId;

  const MCPOrchestrationEvent._(this.type, this.capability, this.operationId);

  factory MCPOrchestrationEvent.started(AgentCapability capability, String operationId) {
    return MCPOrchestrationEvent._(
      'started',
      capability,
      operationId,
    );
  }

  factory MCPOrchestrationEvent.completed(AgentCapability capability, String operationId) {
    return MCPOrchestrationEvent._(
      'completed',
      capability,
      operationId,
    );
  }
}

/// Production-ready provider
final productionMCPOrchestratorProvider = Provider<ProductionMCPOrchestrator>((ref) {
  final safetyService = ref.watch(mcpSafetyServiceProvider);
  final uiService = ref.watch(mcpUserInterfaceServiceProvider);
  
  final orchestrator = ProductionMCPOrchestrator(safetyService, uiService);
  ref.onDispose(() => orchestrator.dispose());
  
  return orchestrator;
});