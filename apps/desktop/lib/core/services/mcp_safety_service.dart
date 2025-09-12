import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../models/mcp_capability.dart';
import '../data/mcp_server_configs.dart';

/// Anthropic PM-style Trust & Safety Service
/// 
/// This service implements safety-first principles:
/// - Constitutional AI approach to command evaluation
/// - Progressive trust model
/// - Clear explanation of risks and benefits
/// - User empowerment through informed consent
class MCPSafetyService {
  final Map<String, int> _userTrustScore = {};
  final Set<String> _approvedCapabilities = {};
  final Set<String> _blockedCommands = {
    // Dangerous system commands
    'rm -rf',
    'del /s /q',
    'format',
    'fdisk',
    // Network security risks
    'nc -l',
    'netcat',
    // Process manipulation
    'kill -9',
    'taskkill /f',
    // Registry modification
    'regedit',
    'reg delete',
  };

  /// Check if a capability can be enabled for an agent
  Future<SafetyDecision> canEnableCapability(
    AgentCapability capability, 
    Agent agent
  ) async {
    // Step 1: Check if capability is globally safe
    final globalSafety = _checkGlobalCapabilitySafety(capability);
    if (!globalSafety.isAllowed) {
      return globalSafety;
    }

    // Step 2: Check user trust level
    final userTrust = _getUserTrustLevel(agent.id);
    final trustDecision = _checkTrustRequirements(capability, userTrust);
    if (!trustDecision.isAllowed) {
      return trustDecision;
    }

    // Step 3: Check required MCP servers safety
    final serverSafety = await _checkMCPServersSafety(capability);
    if (!serverSafety.isAllowed) {
      return serverSafety;
    }

    // Step 4: Determine approval requirements
    final requiresApproval = _requiresUserApproval(capability, userTrust);
    
    return SafetyDecision.allowed(
      explanation: _generateCapabilityExplanation(capability),
      requiresUserApproval: requiresApproval,
      trustLevel: userTrust,
    );
  }

  /// Evaluate if a command is safe to execute
  Future<CommandDecision> evaluateCommand(String command, {
    required String context,
    String? userId,
  }) async {
    final cleanCommand = command.trim().toLowerCase();
    
    // Step 1: Check against blocked commands
    for (final blocked in _blockedCommands) {
      if (cleanCommand.contains(blocked)) {
        return CommandDecision.blocked(
          reason: 'Command contains potentially dangerous operation: $blocked',
          suggestion: 'Please verify this action is intentional',
        );
      }
    }

    // Step 2: Analyze command intent
    final intent = _analyzeCommandIntent(cleanCommand);
    
    // Step 3: Check if command matches user context
    final contextMatch = _checkContextMatch(cleanCommand, context);
    if (!contextMatch) {
      return CommandDecision.requiresApproval(
        reason: 'Command doesn\'t match current conversation context',
        explanation: 'This command seems unrelated to what we\'re working on',
      );
    }

    // Step 4: Check risk level based on command type
    final riskLevel = _assessCommandRisk(cleanCommand, intent);
    
    switch (riskLevel) {
      case CommandRisk.safe:
        return CommandDecision.allowed(
          explanation: 'This is a safe, read-only operation',
        );
        
      case CommandRisk.moderate:
        return CommandDecision.requiresApproval(
          reason: 'This command will make changes to your system',
          explanation: _generateCommandExplanation(cleanCommand, intent),
        );
        
      case CommandRisk.high:
        return CommandDecision.blocked(
          reason: 'This command has high security risk',
          suggestion: 'Consider using a safer alternative or enable Developer Mode',
        );
    }
  }

  /// Increase user trust based on successful interactions
  void increaseTrust(String userId, AgentCapability capability) {
    final currentTrust = _userTrustScore[userId] ?? 0;
    final trustIncrease = _getTrustIncrease(capability);
    _userTrustScore[userId] = (currentTrust + trustIncrease).clamp(0, 100);
    
    // Remember approved capabilities for faster future approval
    _approvedCapabilities.add('${userId}_${capability.id}');
  }

  /// Decrease trust if something goes wrong
  void decreaseTrust(String userId, String reason) {
    final currentTrust = _userTrustScore[userId] ?? 0;
    final trustDecrease = _getTrustDecrease(reason);
    _userTrustScore[userId] = (currentTrust - trustDecrease).clamp(0, 100);
  }

  /// Check global safety of a capability
  SafetyDecision _checkGlobalCapabilitySafety(AgentCapability capability) {
    // Some capabilities might be globally disabled for security
    // This is where we'd check enterprise policies, etc.
    
    // For now, all capabilities are allowed globally
    return SafetyDecision.allowed(
      explanation: 'Capability is globally permitted',
    );
  }

  /// Get user's trust level (0-100)
  int _getUserTrustLevel(String userId) {
    return _userTrustScore[userId] ?? 0;
  }

  /// Check if user trust level is sufficient for capability
  SafetyDecision _checkTrustRequirements(AgentCapability capability, int trustLevel) {
    final requiredTrust = _getRequiredTrustLevel(capability);
    
    if (trustLevel < requiredTrust) {
      return SafetyDecision.requiresApproval(
        reason: 'This capability requires higher trust level',
        explanation: 'As you use the system more, fewer approvals will be needed',
      );
    }
    
    return SafetyDecision.allowed(
      explanation: 'User has sufficient trust level',
    );
  }

  /// Check safety of required MCP servers
  Future<SafetyDecision> _checkMCPServersSafety(AgentCapability capability) async {
    final requiredServers = capability.requiredMCPServers;
    
    for (final serverId in requiredServers) {
      final server = MCPServerLibrary.getServer(serverId);
      if (server == null) {
        return SafetyDecision.blocked(
          reason: 'Required MCP server not found: $serverId',
        );
      }
      
      // Check if server has known security issues
      final serverSafety = _checkServerSafety(server);
      if (!serverSafety.isAllowed) {
        return serverSafety;
      }
    }
    
    return SafetyDecision.allowed(
      explanation: 'All required MCP servers are safe',
    );
  }

  /// Check if individual MCP server is safe
  SafetyDecision _checkServerSafety(MCPServerLibraryConfig server) {
    // Check server reputation
    if (server.status == MCPServerStatus.deprecated) {
      return SafetyDecision.blocked(
        reason: 'Server is deprecated and may have security issues',
      );
    }
    
    // Official servers are generally safer
    if (server.type == MCPServerType.official) {
      return SafetyDecision.allowed(
        explanation: 'Official Anthropic server - verified safe',
      );
    }
    
    // Community servers require more scrutiny
    if (server.type == MCPServerType.community) {
      return SafetyDecision.allowed(
        explanation: 'Community server - generally safe but requires approval',
        requiresUserApproval: true,
      );
    }
    
    // Experimental servers are risky
    if (server.type == MCPServerType.experimental) {
      return SafetyDecision.requiresApproval(
        reason: 'Experimental server may be unstable',
        explanation: 'This server is in early development and may not work as expected',
      );
    }
    
    return SafetyDecision.allowed(explanation: 'Server passed safety checks');
  }

  /// Determine if capability requires user approval
  bool _requiresUserApproval(AgentCapability capability, int trustLevel) {
    // High-risk capabilities always require approval
    if (capability.riskLevel == CapabilityRiskLevel.high) {
      return true;
    }
    
    // Medium-risk capabilities require approval for low-trust users
    if (capability.riskLevel == CapabilityRiskLevel.medium && trustLevel < 50) {
      return true;
    }
    
    // Check if user has previously approved this capability
    final hasApproved = _approvedCapabilities.contains('agent_${capability.id}');
    if (hasApproved && trustLevel >= 30) {
      return false; // Skip approval for trusted repeat usage
    }
    
    // Low-risk capabilities with some trust don't need approval
    if (capability.riskLevel == CapabilityRiskLevel.low && trustLevel >= 20) {
      return false;
    }
    
    return true; // Default to requiring approval
  }

  /// Generate user-friendly explanation of capability
  String _generateCapabilityExplanation(AgentCapability capability) {
    final explanation = StringBuffer();
    explanation.writeln(capability.userBenefit);
    explanation.writeln();
    explanation.writeln('This will enable:');
    
    // Explain what each required server does in user terms
    for (final serverId in capability.requiredMCPServers) {
      final server = MCPServerLibrary.getServer(serverId);
      if (server != null) {
        explanation.writeln('• ${server.name}: ${server.description}');
      }
    }
    
    // Add risk information
    if (capability.riskLevel == CapabilityRiskLevel.high) {
      explanation.writeln();
      explanation.writeln('⚠️ This capability can access sensitive data or make system changes.');
    } else if (capability.riskLevel == CapabilityRiskLevel.medium) {
      explanation.writeln();
      explanation.writeln('ℹ️ This capability will install additional software components.');
    }
    
    return explanation.toString();
  }

  /// Analyze what a command is trying to do
  CommandIntent _analyzeCommandIntent(String command) {
    if (command.contains('install') || command.contains('npm') || command.contains('pip')) {
      return CommandIntent.install;
    }
    if (command.contains('rm') || command.contains('delete') || command.contains('del')) {
      return CommandIntent.delete;
    }
    if (command.contains('read') || command.contains('cat') || command.contains('type')) {
      return CommandIntent.read;
    }
    if (command.contains('write') || command.contains('echo') || command.contains('>')) {
      return CommandIntent.write;
    }
    if (command.contains('git') || command.contains('clone') || command.contains('commit')) {
      return CommandIntent.git;
    }
    return CommandIntent.other;
  }

  /// Check if command matches current conversation context
  bool _checkContextMatch(String command, String context) {
    // Simple heuristic - in a real system this would be more sophisticated
    final contextWords = context.toLowerCase().split(' ');
    final commandWords = command.split(' ');
    
    // Look for overlap in key terms
    final overlap = contextWords.toSet().intersection(commandWords.toSet());
    return overlap.isNotEmpty || context.contains('terminal') || context.contains('command');
  }

  /// Assess risk level of a command
  CommandRisk _assessCommandRisk(String command, CommandIntent intent) {
    // High risk commands
    if (intent == CommandIntent.delete) return CommandRisk.high;
    if (command.contains('sudo') || command.contains('admin')) return CommandRisk.high;
    if (command.contains('format') || command.contains('fdisk')) return CommandRisk.high;
    
    // Moderate risk commands
    if (intent == CommandIntent.install) return CommandRisk.moderate;
    if (intent == CommandIntent.write) return CommandRisk.moderate;
    if (command.contains('chmod') || command.contains('chown')) return CommandRisk.moderate;
    
    // Safe commands
    if (intent == CommandIntent.read) return CommandRisk.safe;
    if (intent == CommandIntent.git && !command.contains('rm')) return CommandRisk.safe;
    
    return CommandRisk.moderate; // Default to moderate
  }

  /// Generate explanation of what a command will do
  String _generateCommandExplanation(String command, CommandIntent intent) {
    switch (intent) {
      case CommandIntent.install:
        return 'This will download and install software packages on your system';
      case CommandIntent.delete:
        return 'This will permanently delete files or folders';
      case CommandIntent.read:
        return 'This will read and display file contents';
      case CommandIntent.write:
        return 'This will create or modify files on your system';
      case CommandIntent.git:
        return 'This will perform Git repository operations';
      case CommandIntent.other:
        return 'This command will make changes to your system';
    }
  }

  /// Get required trust level for a capability
  int _getRequiredTrustLevel(AgentCapability capability) {
    switch (capability.riskLevel) {
      case CapabilityRiskLevel.low:
        return 0;
      case CapabilityRiskLevel.medium:
        return 30;
      case CapabilityRiskLevel.high:
        return 60;
    }
  }

  /// Get trust increase for successful capability usage
  int _getTrustIncrease(AgentCapability capability) {
    switch (capability.riskLevel) {
      case CapabilityRiskLevel.low:
        return 5;
      case CapabilityRiskLevel.medium:
        return 10;
      case CapabilityRiskLevel.high:
        return 20;
    }
  }

  /// Get trust decrease for failures
  int _getTrustDecrease(String reason) {
    if (reason.contains('security')) return 30;
    if (reason.contains('error')) return 10;
    return 5;
  }
}

/// Decision about capability safety
class SafetyDecision {
  final bool isAllowed;
  final String explanation;
  final bool requiresUserApproval;
  final String? reason;
  final int? trustLevel;

  const SafetyDecision._({
    required this.isAllowed,
    required this.explanation,
    this.requiresUserApproval = false,
    this.reason,
    this.trustLevel,
  });

  factory SafetyDecision.allowed({
    required String explanation,
    bool requiresUserApproval = false,
    int? trustLevel,
  }) {
    return SafetyDecision._(
      isAllowed: true,
      explanation: explanation,
      requiresUserApproval: requiresUserApproval,
      trustLevel: trustLevel,
    );
  }

  factory SafetyDecision.blocked({
    required String reason,
    String? explanation,
  }) {
    return SafetyDecision._(
      isAllowed: false,
      explanation: explanation ?? 'Not allowed for security reasons',
      reason: reason,
    );
  }

  factory SafetyDecision.requiresApproval({
    required String reason,
    required String explanation,
  }) {
    return SafetyDecision._(
      isAllowed: true,
      explanation: explanation,
      requiresUserApproval: true,
      reason: reason,
    );
  }
}

/// Decision about command execution
class CommandDecision {
  final bool isAllowed;
  final String explanation;
  final bool requiresApproval;
  final String? reason;
  final String? suggestion;

  const CommandDecision._({
    required this.isAllowed,
    required this.explanation,
    this.requiresApproval = false,
    this.reason,
    this.suggestion,
  });

  factory CommandDecision.allowed({required String explanation}) {
    return CommandDecision._(
      isAllowed: true,
      explanation: explanation,
    );
  }

  factory CommandDecision.blocked({
    required String reason,
    String? suggestion,
  }) {
    return CommandDecision._(
      isAllowed: false,
      explanation: 'Command blocked: $reason',
      reason: reason,
      suggestion: suggestion,
    );
  }

  factory CommandDecision.requiresApproval({
    required String reason,
    required String explanation,
  }) {
    return CommandDecision._(
      isAllowed: true,
      explanation: explanation,
      requiresApproval: true,
      reason: reason,
    );
  }
}

enum CommandIntent {
  install,
  delete,
  read,
  write,
  git,
  other,
}

enum CommandRisk {
  safe,
  moderate,
  high,
}

/// Provider for MCP Safety Service
final mcpSafetyServiceProvider = Provider<MCPSafetyService>((ref) {
  return MCPSafetyService();
});