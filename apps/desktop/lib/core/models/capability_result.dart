/// Result of a capability check or capability-related operation
class CapabilityResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final String? message;
  final List<String> capabilities;
  final Map<String, bool> capabilityStatus;

  const CapabilityResult({
    required this.success,
    this.data,
    this.error,
    this.message,
    this.capabilities = const [],
    this.capabilityStatus = const {},
  });

  /// Create a successful result
  factory CapabilityResult.successResult({
    Map<String, dynamic>? data,
    String? message,
    List<String> capabilities = const [],
    Map<String, bool> capabilityStatus = const {},
  }) {
    return CapabilityResult(
      success: true,
      data: data,
      message: message,
      capabilities: capabilities,
      capabilityStatus: capabilityStatus,
    );
  }

  /// Create a failure result
  factory CapabilityResult.failure({
    required String error,
    String? message,
    Map<String, dynamic>? data,
  }) {
    return CapabilityResult(
      success: false,
      error: error,
      message: message,
      data: data,
    );
  }

  /// Check if a specific capability is available
  bool hasCapability(String capability) {
    return capabilities.contains(capability) ||
           (capabilityStatus[capability] ?? false);
  }

  @override
  String toString() {
    if (success) {
      return 'CapabilityResult(success: $success, capabilities: ${capabilities.length})';
    } else {
      return 'CapabilityResult(success: $success, error: $error)';
    }
  }
}
