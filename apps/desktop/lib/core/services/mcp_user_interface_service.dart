import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_capability.dart';

/// Anthropic PM-style User Interface Service for MCP
/// 
/// This service handles all user communication with friendly, non-technical language:
/// - Beautiful progress updates instead of terminal output
/// - Clear permission requests with benefits explained
/// - Helpful error messages with recovery suggestions
/// - Progressive disclosure of technical details
class MCPUserInterfaceService {
  final StreamController<MCPUIEvent> _eventController;
  final Map<String, MCPProgressState> _activeProgress = {};

  MCPUserInterfaceService() : _eventController = StreamController<MCPUIEvent>.broadcast();

  /// Stream of UI events for components to listen to
  Stream<MCPUIEvent> get events => _eventController.stream;

  /// Request user permission to enable a capability
  /// This shows a beautiful modal with clear benefits and risks
  Future<bool> requestCapabilityPermission(
    AgentCapability capability, 
    String explanation
  ) async {
    final completer = Completer<bool>();
    
    final event = MCPUIEvent.permissionRequest(
      capability: capability,
      title: 'Enable ${capability.displayName}?',
      message: explanation,
      benefits: _getCapabilityBenefits(capability),
      risks: _getCapabilityRisks(capability),
      onApprove: () => completer.complete(true),
      onDeny: () => completer.complete(false),
    );
    
    _eventController.add(event);
    return completer.future;
  }

  /// Show friendly progress for capability enablement
  void showCapabilityProgress(AgentCapability capability, String message) {
    final progressId = capability.id;
    
    final progress = MCPProgressState(
      id: progressId,
      capability: capability,
      message: message,
      status: MCPProgressStatus.inProgress,
      startTime: DateTime.now(),
    );
    
    _activeProgress[progressId] = progress;
    
    final event = MCPUIEvent.progress(
      progress: progress,
      showAsToast: false, // Show in dedicated progress area
    );
    
    _eventController.add(event);
  }

  /// Show success message when capability is fully enabled
  void showCapabilitySuccess(AgentCapability capability) {
    final progressId = capability.id;
    
    final progress = _activeProgress[progressId]?.copyWith(
      message: '🚀 ${capability.displayName} is ready to use!',
      status: MCPProgressStatus.completed,
      completedTime: DateTime.now(),
    ) ?? MCPProgressState(
      id: progressId,
      capability: capability,
      message: '🚀 ${capability.displayName} is ready to use!',
      status: MCPProgressStatus.completed,
      startTime: DateTime.now(),
      completedTime: DateTime.now(),
    );
    
    _activeProgress[progressId] = progress;
    
    final event = MCPUIEvent.success(
      capability: capability,
      message: progress.message,
      showAsToast: true,
    );
    
    _eventController.add(event);
    
    // Auto-hide success message after delay
    Timer(const Duration(seconds: 5), () {
      _hideProgress(progressId);
    });
  }

  /// Show partial success when some servers installed
  void showCapabilityPartialSuccess(
    AgentCapability capability, 
    int successCount, 
    int totalCount
  ) {
    final progressId = capability.id;
    
    final message = '⚠️ ${capability.displayName} is partially available ($successCount/$totalCount components ready)';
    
    final progress = _activeProgress[progressId]?.copyWith(
      message: message,
      status: MCPProgressStatus.partialSuccess,
      completedTime: DateTime.now(),
    ) ?? MCPProgressState(
      id: progressId,
      capability: capability,
      message: message,
      status: MCPProgressStatus.partialSuccess,
      startTime: DateTime.now(),
      completedTime: DateTime.now(),
    );
    
    _activeProgress[progressId] = progress;
    
    final event = MCPUIEvent.warning(
      capability: capability,
      message: message,
      showAsToast: true,
    );
    
    _eventController.add(event);
  }

  /// Show error with helpful recovery suggestions
  void showCapabilityError(
    AgentCapability capability, 
    List<String> recoverySuggestions
  ) {
    final progressId = capability.id;
    
    final message = '❌ Could not set up ${capability.displayName}';
    
    final progress = _activeProgress[progressId]?.copyWith(
      message: message,
      status: MCPProgressStatus.failed,
      completedTime: DateTime.now(),
      recoverySuggestions: recoverySuggestions,
    ) ?? MCPProgressState(
      id: progressId,
      capability: capability,
      message: message,
      status: MCPProgressStatus.failed,
      startTime: DateTime.now(),
      completedTime: DateTime.now(),
      recoverySuggestions: recoverySuggestions,
    );
    
    _activeProgress[progressId] = progress;
    
    final event = MCPUIEvent.error(
      capability: capability,
      message: message,
      recoverySuggestions: recoverySuggestions,
      showAsToast: false, // Keep error visible
    );
    
    _eventController.add(event);
  }

  /// Show command approval request (for Developer Mode)
  Future<bool> requestCommandApproval(
    String command, 
    String explanation,
    {String? risk}
  ) async {
    final completer = Completer<bool>();
    
    final event = MCPUIEvent.commandApproval(
      command: command,
      explanation: explanation,
      risk: risk,
      onApprove: () => completer.complete(true),
      onDeny: () => completer.complete(false),
    );
    
    _eventController.add(event);
    return completer.future;
  }

  /// Show terminal output in a user-friendly way
  void showTerminalOutput(String output, {bool isError = false}) {
    final event = MCPUIEvent.terminalOutput(
      output: output,
      isError: isError,
      timestamp: DateTime.now(),
    );
    
    _eventController.add(event);
  }

  /// Get current progress for a capability
  MCPProgressState? getProgress(String capabilityId) {
    return _activeProgress[capabilityId];
  }

  /// Get all active progress states
  List<MCPProgressState> getAllProgress() {
    return _activeProgress.values.toList();
  }

  /// Hide progress for a capability
  void _hideProgress(String progressId) {
    _activeProgress.remove(progressId);
    
    final event = MCPUIEvent.progressHidden(progressId: progressId);
    _eventController.add(event);
  }

  /// Get user-friendly benefits for a capability
  List<String> _getCapabilityBenefits(AgentCapability capability) {
    final benefits = <String>[];
    
    // Add capability-specific benefits
    benefits.add(capability.userBenefit);
    
    // Add category-specific benefits
    switch (capability.category) {
      case CapabilityCategory.development:
        benefits.add('Streamline your development workflow');
        break;
      case CapabilityCategory.productivity:
        benefits.add('Save time on routine tasks');
        break;
      case CapabilityCategory.research:
        benefits.add('Get information faster and more accurately');
        break;
      case CapabilityCategory.data:
        benefits.add('Work with data without technical complexity');
        break;
      case CapabilityCategory.communication:
        benefits.add('Stay connected without switching apps');
        break;
      case CapabilityCategory.intelligence:
        benefits.add('Get more personalized and context-aware assistance');
        break;
      case CapabilityCategory.design:
        benefits.add('Bridge the gap between design and implementation');
        break;
    }
    
    return benefits;
  }

  /// Get user-friendly risks for a capability
  List<String> _getCapabilityRisks(AgentCapability capability) {
    final risks = <String>[];
    
    switch (capability.riskLevel) {
      case CapabilityRiskLevel.low:
        risks.add('This is generally safe and doesn\'t access sensitive data');
        break;
        
      case CapabilityRiskLevel.medium:
        risks.add('This will install additional software components');
        risks.add('Some internet access may be required');
        break;
        
      case CapabilityRiskLevel.high:
        risks.add('This can access and modify files on your computer');
        risks.add('Requires elevated permissions');
        risks.add('You can revoke access at any time in settings');
        break;
    }
    
    // Add capability-specific risks
    if (capability.requiredMCPServers.contains('filesystem')) {
      risks.add('Can read and write files in allowed directories');
    }
    
    if (capability.requiredMCPServers.contains('git')) {
      risks.add('Can view and modify Git repositories');
    }
    
    if (capability.requiredMCPServers.any((s) => s.contains('database'))) {
      risks.add('Can query and potentially modify database contents');
    }
    
    return risks;
  }

  void dispose() {
    _eventController.close();
  }
}

/// UI events that components can listen to
class MCPUIEvent {
  final MCPUIEventType type;
  final AgentCapability? capability;
  final String? message;
  final Map<String, dynamic> data;

  const MCPUIEvent._({
    required this.type,
    this.capability,
    this.message,
    this.data = const {},
  });

  factory MCPUIEvent.permissionRequest({
    required AgentCapability capability,
    required String title,
    required String message,
    required List<String> benefits,
    required List<String> risks,
    required VoidCallback onApprove,
    required VoidCallback onDeny,
  }) {
    return MCPUIEvent._(
      type: MCPUIEventType.permissionRequest,
      capability: capability,
      message: message,
      data: {
        'title': title,
        'benefits': benefits,
        'risks': risks,
        'onApprove': onApprove,
        'onDeny': onDeny,
      },
    );
  }

  factory MCPUIEvent.progress({
    required MCPProgressState progress,
    bool showAsToast = false,
  }) {
    return MCPUIEvent._(
      type: MCPUIEventType.progress,
      capability: progress.capability,
      message: progress.message,
      data: {
        'progress': progress,
        'showAsToast': showAsToast,
      },
    );
  }

  factory MCPUIEvent.success({
    required AgentCapability capability,
    required String message,
    bool showAsToast = true,
  }) {
    return MCPUIEvent._(
      type: MCPUIEventType.success,
      capability: capability,
      message: message,
      data: {'showAsToast': showAsToast},
    );
  }

  factory MCPUIEvent.warning({
    required AgentCapability capability,
    required String message,
    bool showAsToast = true,
  }) {
    return MCPUIEvent._(
      type: MCPUIEventType.warning,
      capability: capability,
      message: message,
      data: {'showAsToast': showAsToast},
    );
  }

  factory MCPUIEvent.error({
    required AgentCapability capability,
    required String message,
    required List<String> recoverySuggestions,
    bool showAsToast = false,
  }) {
    return MCPUIEvent._(
      type: MCPUIEventType.error,
      capability: capability,
      message: message,
      data: {
        'recoverySuggestions': recoverySuggestions,
        'showAsToast': showAsToast,
      },
    );
  }

  factory MCPUIEvent.commandApproval({
    required String command,
    required String explanation,
    String? risk,
    required VoidCallback onApprove,
    required VoidCallback onDeny,
  }) {
    return MCPUIEvent._(
      type: MCPUIEventType.commandApproval,
      message: explanation,
      data: {
        'command': command,
        'risk': risk,
        'onApprove': onApprove,
        'onDeny': onDeny,
      },
    );
  }

  factory MCPUIEvent.terminalOutput({
    required String output,
    required bool isError,
    required DateTime timestamp,
  }) {
    return MCPUIEvent._(
      type: MCPUIEventType.terminalOutput,
      message: output,
      data: {
        'isError': isError,
        'timestamp': timestamp,
      },
    );
  }

  factory MCPUIEvent.progressHidden({required String progressId}) {
    return MCPUIEvent._(
      type: MCPUIEventType.progressHidden,
      data: {'progressId': progressId},
    );
  }
}

enum MCPUIEventType {
  permissionRequest,
  progress,
  success,
  warning,
  error,
  commandApproval,
  terminalOutput,
  progressHidden,
}

/// Progress state for capability enablement
class MCPProgressState {
  final String id;
  final AgentCapability capability;
  final String message;
  final MCPProgressStatus status;
  final DateTime startTime;
  final DateTime? completedTime;
  final List<String> recoverySuggestions;

  const MCPProgressState({
    required this.id,
    required this.capability,
    required this.message,
    required this.status,
    required this.startTime,
    this.completedTime,
    this.recoverySuggestions = const [],
  });

  Duration get duration {
    final endTime = completedTime ?? DateTime.now();
    return endTime.difference(startTime);
  }

  bool get isCompleted => status == MCPProgressStatus.completed || 
                         status == MCPProgressStatus.failed ||
                         status == MCPProgressStatus.partialSuccess;

  MCPProgressState copyWith({
    String? id,
    AgentCapability? capability,
    String? message,
    MCPProgressStatus? status,
    DateTime? startTime,
    DateTime? completedTime,
    List<String>? recoverySuggestions,
  }) {
    return MCPProgressState(
      id: id ?? this.id,
      capability: capability ?? this.capability,
      message: message ?? this.message,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      completedTime: completedTime ?? this.completedTime,
      recoverySuggestions: recoverySuggestions ?? this.recoverySuggestions,
    );
  }
}

enum MCPProgressStatus {
  inProgress,
  completed,
  partialSuccess,
  failed,
}

/// Provider for MCP User Interface Service
final mcpUserInterfaceServiceProvider = Provider<MCPUserInterfaceService>((ref) {
  return MCPUserInterfaceService();
});