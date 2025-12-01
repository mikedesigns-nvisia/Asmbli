class MCPToolResult {
  final String agentId;
  final String serverId;
  final String toolName;
  final bool success;
  final Map<String, dynamic>? result;
  final String? error;
  final Duration executionTime;
  final DateTime timestamp;

  const MCPToolResult({
    required this.agentId,
    required this.serverId,
    required this.toolName,
    required this.success,
    this.result,
    this.error,
    required this.executionTime,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    'serverId': serverId,
    'toolName': toolName,
    'success': success,
    'result': result,
    'error': error,
    'executionTime': executionTime.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MCPToolResult.fromJson(Map<String, dynamic> json) => MCPToolResult(
    agentId: json['agentId'] as String,
    serverId: json['serverId'] as String,
    toolName: json['toolName'] as String,
    success: json['success'] as bool,
    result: json['result'] as Map<String, dynamic>?,
    error: json['error'] as String?,
    executionTime: Duration(milliseconds: json['executionTime'] as int),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
