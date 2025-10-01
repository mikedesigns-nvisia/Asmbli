import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/security_context.dart';

/// API access control and credential management service
class APIAccessControl {
  final Map<String, SecurityContext> _agentContexts = {};
  final Map<String, APIMonitor> _apiMonitors = {};
  final Map<String, RateLimiter> _rateLimiters = {};
  final SecureCredentialStore _credentialStore = SecureCredentialStore();
  final APICallLogger _callLogger = APICallLogger();

  /// Register an agent with its security context
  Future<void> registerAgent(String agentId, SecurityContext context) async {
    _agentContexts[agentId] = context;
    _apiMonitors[agentId] = APIMonitor(agentId);
    _rateLimiters[agentId] = RateLimiter();
    
    // Initialize credentials for the agent
    await _initializeAgentCredentials(agentId, context);
  }

  /// Update agent security context
  Future<void> updateAgentContext(String agentId, SecurityContext context) async {
    _agentContexts[agentId] = context;
    await _updateAgentCredentials(agentId, context);
  }

  /// Remove agent from API access control
  Future<void> unregisterAgent(String agentId) async {
    _agentContexts.remove(agentId);
    _apiMonitors.remove(agentId);
    _rateLimiters.remove(agentId);
    await _credentialStore.removeAgentCredentials(agentId);
  }

  /// Validate API access request
  Future<APIAccessResult> validateAPIAccess(
    String agentId,
    String provider,
    String model, {
    int estimatedTokens = 0,
    Map<String, dynamic> requestMetadata = const {},
  }) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return APIAccessResult.denied(
        reason: 'No security context found for agent',
        riskLevel: RiskLevel.high,
      );
    }

    try {
      // Check if API access is allowed for this provider/model
      if (!context.isAPIAccessAllowed(provider, model)) {
        _logAPIAttempt(agentId, provider, model, false, 'API access not permitted');
        return APIAccessResult.denied(
          reason: 'API access not permitted for $provider/$model',
          riskLevel: RiskLevel.medium,
        );
      }

      final permission = context.apiPermissions[provider];
      if (permission == null) {
        return APIAccessResult.denied(
          reason: 'No API permission configuration found for $provider',
          riskLevel: RiskLevel.medium,
        );
      }

      // Check rate limits
      final rateLimitCheck = _checkRateLimit(agentId, provider, permission);
      if (!rateLimitCheck.isAllowed) {
        _logAPIAttempt(agentId, provider, model, false, rateLimitCheck.reason);
        return rateLimitCheck;
      }

      // Check token limits
      if (estimatedTokens > permission.maxTokensPerRequest) {
        _logAPIAttempt(agentId, provider, model, false, 'Token limit exceeded');
        return APIAccessResult.denied(
          reason: 'Token limit exceeded: $estimatedTokens > ${permission.maxTokensPerRequest}',
          riskLevel: RiskLevel.medium,
        );
      }

      // Check if credentials are available
      final hasCredentials = await _credentialStore.hasCredentials(agentId, provider);
      if (!hasCredentials) {
        _logAPIAttempt(agentId, provider, model, false, 'No credentials available');
        return APIAccessResult.denied(
          reason: 'No credentials available for $provider',
          riskLevel: RiskLevel.medium,
        );
      }

      // Check for suspicious request patterns
      final suspiciousCheck = _checkSuspiciousPatterns(agentId, provider, model, requestMetadata);
      if (suspiciousCheck.requiresApproval) {
        _logAPIAttempt(agentId, provider, model, true, 'Suspicious pattern detected');
        return APIAccessResult.allowed(
          riskLevel: RiskLevel.high,
          requiresApproval: true,
          monitoringLevel: MonitoringLevel.comprehensive,
        );
      }

      // Check if approval is required by policy
      final requiresApproval = context.terminalPermissions.requiresApprovalForAPICalls;
      
      _logAPIAttempt(agentId, provider, model, true, 'API access granted');
      
      return APIAccessResult.allowed(
        riskLevel: _calculateAPIRiskLevel(provider, model, estimatedTokens),
        requiresApproval: requiresApproval,
        monitoringLevel: _getAPIMonitoringLevel(provider, model),
      );

    } catch (e) {
      _logAPIAttempt(agentId, provider, model, false, 'Access validation error: $e');
      return APIAccessResult.denied(
        reason: 'API access validation failed: $e',
        riskLevel: RiskLevel.high,
      );
    }
  }

  /// Make a secure API call with credential injection
  Future<APICallResult> makeSecureAPICall(
    String agentId,
    String provider,
    String model,
    Map<String, dynamic> request, {
    Map<String, String> additionalHeaders = const {},
  }) async {
    // Validate access first
    final accessResult = await validateAPIAccess(
      agentId,
      provider,
      model,
      estimatedTokens: _estimateTokens(request),
      requestMetadata: request,
    );

    if (!accessResult.isAllowed) {
      return APICallResult.failed(
        reason: accessResult.reason,
        statusCode: 403,
      );
    }

    try {
      // Get secure credentials
      final credentials = await _credentialStore.getCredentials(agentId, provider);
      if (credentials == null) {
        return APICallResult.failed(
          reason: 'Failed to retrieve credentials',
          statusCode: 401,
        );
      }

      // Prepare secure request
      final secureRequest = await _prepareSecureRequest(
        provider,
        model,
        request,
        credentials,
        additionalHeaders,
      );

      // Record rate limit usage
      _rateLimiters[agentId]?.recordRequest(provider);

      // Make the API call
      final startTime = DateTime.now();
      final result = await _executeAPICall(provider, secureRequest);
      final duration = DateTime.now().difference(startTime);

      // Log the call
      _callLogger.logAPICall(APICallLog(
        agentId: agentId,
        provider: provider,
        model: model,
        success: result.isSuccess,
        statusCode: result.statusCode,
        duration: duration,
        tokenCount: _extractTokenCount(result.response),
        timestamp: DateTime.now(),
      ));

      // Update monitoring
      _apiMonitors[agentId]?.recordAPICall(provider, model, result.isSuccess, duration);

      return result;

    } catch (e) {
      _logAPIAttempt(agentId, provider, model, false, 'API call execution failed: $e');
      
      return APICallResult.failed(
        reason: 'API call failed: $e',
        statusCode: 500,
      );
    }
  }

  /// Inject secure credentials into terminal environment
  Future<Map<String, String>> injectSecureCredentials(
    String agentId,
    Map<String, String> environment,
  ) async {
    final context = _agentContexts[agentId];
    if (context == null) {
      return environment;
    }

    final secureEnv = Map<String, String>.from(environment);

    // Inject credentials for each configured API provider
    for (final provider in context.apiPermissions.keys) {
      final credentials = await _credentialStore.getCredentials(agentId, provider);
      if (credentials != null) {
        final envVars = _getEnvironmentVariablesForProvider(provider, credentials);
        secureEnv.addAll(envVars);
      }
    }

    // Add secure environment variables from terminal permissions
    secureEnv.addAll(context.terminalPermissions.secureEnvironmentVars);

    return secureEnv;
  }

  /// Get API usage statistics for an agent
  APIUsageStats getAPIUsageStats(String agentId) {
    final monitor = _apiMonitors[agentId];
    if (monitor == null) {
      return APIUsageStats.empty();
    }

    return monitor.getStats();
  }

  /// Get API call logs for an agent
  List<APICallLog> getAPICallLogs(String agentId) {
    return _callLogger.getLogsForAgent(agentId);
  }

  /// Get rate limit status for an agent
  Map<String, RateLimitStatus> getRateLimitStatus(String agentId) {
    final rateLimiter = _rateLimiters[agentId];
    if (rateLimiter == null) {
      return {};
    }

    final context = _agentContexts[agentId];
    if (context == null) {
      return {};
    }

    final status = <String, RateLimitStatus>{};
    for (final provider in context.apiPermissions.keys) {
      final permission = context.apiPermissions[provider]!;
      status[provider] = rateLimiter.getStatus(provider, permission.maxRequestsPerMinute);
    }

    return status;
  }

  /// Initialize credentials for an agent
  Future<void> _initializeAgentCredentials(String agentId, SecurityContext context) async {
    for (final entry in context.apiPermissions.entries) {
      final provider = entry.key;
      final permission = entry.value;
      
      // Store secure credentials if provided
      if (permission.secureCredentials.isNotEmpty) {
        await _credentialStore.storeCredentials(
          agentId,
          provider,
          APICredentials(
            provider: provider,
            credentials: permission.secureCredentials,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
        );
      }
    }
  }

  /// Update credentials for an agent
  Future<void> _updateAgentCredentials(String agentId, SecurityContext context) async {
    // Remove old credentials
    await _credentialStore.removeAgentCredentials(agentId);
    
    // Initialize new credentials
    await _initializeAgentCredentials(agentId, context);
  }

  /// Check rate limits
  APIAccessResult _checkRateLimit(String agentId, String provider, APIPermission permission) {
    final rateLimiter = _rateLimiters[agentId];
    if (rateLimiter == null) {
      return APIAccessResult.allowed(
        riskLevel: RiskLevel.low,
        requiresApproval: false,
        monitoringLevel: MonitoringLevel.basic,
      );
    }

    if (!rateLimiter.checkRateLimit(provider, permission.maxRequestsPerMinute)) {
      return APIAccessResult.denied(
        reason: 'Rate limit exceeded for $provider (${permission.maxRequestsPerMinute}/min)',
        riskLevel: RiskLevel.medium,
      );
    }

    return APIAccessResult.allowed(
      riskLevel: RiskLevel.low,
      requiresApproval: false,
      monitoringLevel: MonitoringLevel.basic,
    );
  }

  /// Check for suspicious request patterns
  SuspiciousPatternResult _checkSuspiciousPatterns(
    String agentId,
    String provider,
    String model,
    Map<String, dynamic> requestMetadata,
  ) {
    // Check for suspicious prompt patterns
    final prompt = requestMetadata['prompt']?.toString() ?? '';
    final suspiciousPromptPatterns = [
      'ignore previous instructions',
      'system prompt',
      'jailbreak',
      'pretend you are',
      'act as if',
    ];

    for (final pattern in suspiciousPromptPatterns) {
      if (prompt.toLowerCase().contains(pattern)) {
        return SuspiciousPatternResult(
          isSuspicious: true,
          requiresApproval: true,
          reason: 'Suspicious prompt pattern detected: $pattern',
        );
      }
    }

    // Check for unusual model usage
    final monitor = _apiMonitors[agentId];
    if (monitor != null) {
      final recentCalls = monitor.getRecentCalls(const Duration(minutes: 5));
      if (recentCalls.length > 10) {
        return SuspiciousPatternResult(
          isSuspicious: true,
          requiresApproval: true,
          reason: 'Unusual API call frequency detected',
        );
      }
    }

    return SuspiciousPatternResult(
      isSuspicious: false,
      requiresApproval: false,
      reason: 'No suspicious patterns detected',
    );
  }

  /// Calculate API risk level
  RiskLevel _calculateAPIRiskLevel(String provider, String model, int tokenCount) {
    // High risk for large token counts
    if (tokenCount > 8000) {
      return RiskLevel.high;
    }

    // Medium risk for powerful models
    final powerfulModels = ['gpt-4', 'claude-3-opus', 'claude-3-sonnet'];
    if (powerfulModels.any((m) => model.toLowerCase().contains(m.toLowerCase()))) {
      return RiskLevel.medium;
    }

    return RiskLevel.low;
  }

  /// Get API monitoring level
  MonitoringLevel _getAPIMonitoringLevel(String provider, String model) {
    // Comprehensive monitoring for powerful models
    final powerfulModels = ['gpt-4', 'claude-3-opus'];
    if (powerfulModels.any((m) => model.toLowerCase().contains(m.toLowerCase()))) {
      return MonitoringLevel.comprehensive;
    }

    // Enhanced monitoring for mid-tier models
    final midTierModels = ['claude-3-sonnet', 'gpt-3.5-turbo'];
    if (midTierModels.any((m) => model.toLowerCase().contains(m.toLowerCase()))) {
      return MonitoringLevel.enhanced;
    }

    return MonitoringLevel.basic;
  }

  /// Prepare secure API request
  Future<SecureAPIRequest> _prepareSecureRequest(
    String provider,
    String model,
    Map<String, dynamic> request,
    APICredentials credentials,
    Map<String, String> additionalHeaders,
  ) async {
    final headers = <String, String>{};
    
    // Add provider-specific authentication headers
    switch (provider.toLowerCase()) {
      case 'anthropic':
        headers['x-api-key'] = credentials.credentials['api_key'] ?? '';
        headers['anthropic-version'] = '2023-06-01';
        break;
      case 'openai':
        headers['Authorization'] = 'Bearer ${credentials.credentials['api_key'] ?? ''}';
        break;
      default:
        // Generic API key header
        headers['Authorization'] = 'Bearer ${credentials.credentials['api_key'] ?? ''}';
    }

    // Add additional headers
    headers.addAll(additionalHeaders);

    // Add security headers
    headers['User-Agent'] = 'AgentEngine/1.0';
    headers['Content-Type'] = 'application/json';

    return SecureAPIRequest(
      provider: provider,
      model: model,
      headers: headers,
      body: request,
      url: _getAPIEndpoint(provider),
    );
  }

  /// Execute API call
  Future<APICallResult> _executeAPICall(String provider, SecureAPIRequest request) async {
    // This would integrate with actual HTTP client
    // For now, simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulate success/failure
    final random = Random();
    final isSuccess = random.nextDouble() > 0.1; // 90% success rate
    
    if (isSuccess) {
      return APICallResult.success(
        response: {'result': 'API call successful', 'tokens': 150},
        statusCode: 200,
      );
    } else {
      return APICallResult.failed(
        reason: 'Simulated API failure',
        statusCode: 500,
      );
    }
  }

  /// Get API endpoint for provider
  String _getAPIEndpoint(String provider) {
    switch (provider.toLowerCase()) {
      case 'anthropic':
        return 'https://api.anthropic.com/v1/messages';
      case 'openai':
        return 'https://api.openai.com/v1/chat/completions';
      default:
        return 'https://api.example.com/v1/completions';
    }
  }

  /// Get environment variables for provider
  Map<String, String> _getEnvironmentVariablesForProvider(
    String provider,
    APICredentials credentials,
  ) {
    final envVars = <String, String>{};
    
    switch (provider.toLowerCase()) {
      case 'anthropic':
        envVars['ANTHROPIC_API_KEY'] = credentials.credentials['api_key'] ?? '';
        break;
      case 'openai':
        envVars['OPENAI_API_KEY'] = credentials.credentials['api_key'] ?? '';
        break;
      default:
        envVars['${provider.toUpperCase()}_API_KEY'] = credentials.credentials['api_key'] ?? '';
    }
    
    return envVars;
  }

  /// Estimate token count from request
  int _estimateTokens(Map<String, dynamic> request) {
    // Simple token estimation based on text length
    final text = request.toString();
    return (text.length / 4).ceil(); // Rough approximation
  }

  /// Extract token count from response
  int _extractTokenCount(Map<String, dynamic>? response) {
    if (response == null) return 0;
    return response['tokens'] as int? ?? 0;
  }

  /// Log API access attempt
  void _logAPIAttempt(
    String agentId,
    String provider,
    String model,
    bool success,
    String reason,
  ) {
    final monitor = _apiMonitors[agentId];
    if (monitor != null) {
      monitor.logAccessAttempt(provider, model, success, reason);
    }

    if (kDebugMode) {
      final status = success ? 'ALLOWED' : 'DENIED';
      debugPrint('API Access [$agentId]: $status - $provider/$model - $reason');
    }
  }
}

/// API access result
class APIAccessResult {
  final bool isAllowed;
  final String reason;
  final RiskLevel riskLevel;
  final bool requiresApproval;
  final MonitoringLevel monitoringLevel;

  const APIAccessResult._({
    required this.isAllowed,
    required this.reason,
    required this.riskLevel,
    this.requiresApproval = false,
    this.monitoringLevel = MonitoringLevel.basic,
  });

  factory APIAccessResult.allowed({
    required RiskLevel riskLevel,
    bool requiresApproval = false,
    MonitoringLevel monitoringLevel = MonitoringLevel.basic,
  }) {
    return APIAccessResult._(
      isAllowed: true,
      reason: 'API access allowed',
      riskLevel: riskLevel,
      requiresApproval: requiresApproval,
      monitoringLevel: monitoringLevel,
    );
  }

  factory APIAccessResult.denied({
    required String reason,
    required RiskLevel riskLevel,
  }) {
    return APIAccessResult._(
      isAllowed: false,
      reason: reason,
      riskLevel: riskLevel,
    );
  }
}

/// API call result
class APICallResult {
  final bool isSuccess;
  final Map<String, dynamic>? response;
  final String? error;
  final int statusCode;

  const APICallResult._({
    required this.isSuccess,
    this.response,
    this.error,
    required this.statusCode,
  });

  factory APICallResult.success({
    required Map<String, dynamic> response,
    required int statusCode,
  }) {
    return APICallResult._(
      isSuccess: true,
      response: response,
      statusCode: statusCode,
    );
  }

  factory APICallResult.failed({
    required String reason,
    required int statusCode,
  }) {
    return APICallResult._(
      isSuccess: false,
      error: reason,
      statusCode: statusCode,
    );
  }
}

/// Secure API request
class SecureAPIRequest {
  final String provider;
  final String model;
  final Map<String, String> headers;
  final Map<String, dynamic> body;
  final String url;

  const SecureAPIRequest({
    required this.provider,
    required this.model,
    required this.headers,
    required this.body,
    required this.url,
  });
}

/// API credentials storage
class APICredentials {
  final String provider;
  final Map<String, String> credentials;
  final DateTime expiresAt;

  const APICredentials({
    required this.provider,
    required this.credentials,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Secure credential store
class SecureCredentialStore {
  final Map<String, Map<String, APICredentials>> _credentials = {};

  Future<void> storeCredentials(String agentId, String provider, APICredentials credentials) async {
    _credentials[agentId] ??= {};
    _credentials[agentId]![provider] = credentials;
  }

  Future<APICredentials?> getCredentials(String agentId, String provider) async {
    final agentCreds = _credentials[agentId];
    if (agentCreds == null) return null;

    final creds = agentCreds[provider];
    if (creds == null || creds.isExpired) return null;

    return creds;
  }

  Future<bool> hasCredentials(String agentId, String provider) async {
    final creds = await getCredentials(agentId, provider);
    return creds != null;
  }

  Future<void> removeAgentCredentials(String agentId) async {
    _credentials.remove(agentId);
  }

  Future<void> removeProviderCredentials(String agentId, String provider) async {
    _credentials[agentId]?.remove(provider);
  }
}

/// Rate limiter
class RateLimiter {
  final Map<String, List<DateTime>> _requestHistory = {};

  bool checkRateLimit(String provider, int maxRequestsPerMinute) {
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));
    
    // Clean old requests
    final requests = _requestHistory[provider] ?? <DateTime>[];
    requests.removeWhere((time) => time.isBefore(windowStart));
    
    // Check limit
    return requests.length < maxRequestsPerMinute;
  }

  void recordRequest(String provider) {
    final requests = _requestHistory[provider] ?? <DateTime>[];
    requests.add(DateTime.now());
    _requestHistory[provider] = requests;
  }

  RateLimitStatus getStatus(String provider, int maxRequestsPerMinute) {
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));
    
    final requests = _requestHistory[provider] ?? <DateTime>[];
    final recentRequests = requests.where((time) => time.isAfter(windowStart)).length;
    
    return RateLimitStatus(
      provider: provider,
      currentRequests: recentRequests,
      maxRequests: maxRequestsPerMinute,
      windowStart: windowStart,
      windowEnd: now,
    );
  }
}

/// Rate limit status
class RateLimitStatus {
  final String provider;
  final int currentRequests;
  final int maxRequests;
  final DateTime windowStart;
  final DateTime windowEnd;

  const RateLimitStatus({
    required this.provider,
    required this.currentRequests,
    required this.maxRequests,
    required this.windowStart,
    required this.windowEnd,
  });

  bool get isLimitExceeded => currentRequests >= maxRequests;
  int get remainingRequests => maxRequests - currentRequests;
  double get utilizationPercent => (currentRequests / maxRequests) * 100;
}

/// API monitor
class APIMonitor {
  final String agentId;
  final List<APIAccessAttempt> _accessAttempts = [];
  final List<APICallRecord> _callRecords = [];

  APIMonitor(this.agentId);

  void logAccessAttempt(String provider, String model, bool success, String reason) {
    final attempt = APIAccessAttempt(
      agentId: agentId,
      provider: provider,
      model: model,
      success: success,
      reason: reason,
      timestamp: DateTime.now(),
    );

    _accessAttempts.add(attempt);
    
    // Keep only last 1000 attempts
    if (_accessAttempts.length > 1000) {
      _accessAttempts.removeRange(0, _accessAttempts.length - 1000);
    }
  }

  void recordAPICall(String provider, String model, bool success, Duration duration) {
    final record = APICallRecord(
      agentId: agentId,
      provider: provider,
      model: model,
      success: success,
      duration: duration,
      timestamp: DateTime.now(),
    );

    _callRecords.add(record);
    
    // Keep only last 1000 records
    if (_callRecords.length > 1000) {
      _callRecords.removeRange(0, _callRecords.length - 1000);
    }
  }

  List<APICallRecord> getRecentCalls(Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return _callRecords.where((record) => record.timestamp.isAfter(cutoff)).toList();
  }

  APIUsageStats getStats() {
    final totalCalls = _callRecords.length;
    final successfulCalls = _callRecords.where((r) => r.success).length;
    final failedCalls = totalCalls - successfulCalls;
    
    final providerCounts = <String, int>{};
    final modelCounts = <String, int>{};
    
    for (final record in _callRecords) {
      providerCounts[record.provider] = (providerCounts[record.provider] ?? 0) + 1;
      modelCounts[record.model] = (modelCounts[record.model] ?? 0) + 1;
    }

    final totalDuration = _callRecords.fold<Duration>(
      Duration.zero,
      (sum, record) => sum + record.duration,
    );

    return APIUsageStats(
      agentId: agentId,
      totalCalls: totalCalls,
      successfulCalls: successfulCalls,
      failedCalls: failedCalls,
      providerCounts: providerCounts,
      modelCounts: modelCounts,
      averageDuration: totalCalls > 0 
          ? Duration(milliseconds: totalDuration.inMilliseconds ~/ totalCalls)
          : Duration.zero,
      lastCall: _callRecords.isNotEmpty ? _callRecords.last.timestamp : null,
    );
  }
}

/// API access attempt
class APIAccessAttempt {
  final String agentId;
  final String provider;
  final String model;
  final bool success;
  final String reason;
  final DateTime timestamp;

  const APIAccessAttempt({
    required this.agentId,
    required this.provider,
    required this.model,
    required this.success,
    required this.reason,
    required this.timestamp,
  });
}

/// API call record
class APICallRecord {
  final String agentId;
  final String provider;
  final String model;
  final bool success;
  final Duration duration;
  final DateTime timestamp;

  const APICallRecord({
    required this.agentId,
    required this.provider,
    required this.model,
    required this.success,
    required this.duration,
    required this.timestamp,
  });
}

/// API usage statistics
class APIUsageStats {
  final String agentId;
  final int totalCalls;
  final int successfulCalls;
  final int failedCalls;
  final Map<String, int> providerCounts;
  final Map<String, int> modelCounts;
  final Duration averageDuration;
  final DateTime? lastCall;

  const APIUsageStats({
    required this.agentId,
    required this.totalCalls,
    required this.successfulCalls,
    required this.failedCalls,
    required this.providerCounts,
    required this.modelCounts,
    required this.averageDuration,
    this.lastCall,
  });

  factory APIUsageStats.empty() {
    return const APIUsageStats(
      agentId: '',
      totalCalls: 0,
      successfulCalls: 0,
      failedCalls: 0,
      providerCounts: {},
      modelCounts: {},
      averageDuration: Duration.zero,
    );
  }

  double get successRate {
    if (totalCalls == 0) return 0.0;
    return successfulCalls / totalCalls;
  }
}

/// API call logger
class APICallLogger {
  final List<APICallLog> _logs = [];

  void logAPICall(APICallLog log) {
    _logs.add(log);
    
    // Keep only last 10000 logs
    if (_logs.length > 10000) {
      _logs.removeRange(0, _logs.length - 10000);
    }
  }

  List<APICallLog> getLogsForAgent(String agentId) {
    return _logs.where((log) => log.agentId == agentId).toList();
  }

  List<APICallLog> getAllLogs() => List.unmodifiable(_logs);
}

/// API call log
class APICallLog {
  final String agentId;
  final String provider;
  final String model;
  final bool success;
  final int statusCode;
  final Duration duration;
  final int tokenCount;
  final DateTime timestamp;

  const APICallLog({
    required this.agentId,
    required this.provider,
    required this.model,
    required this.success,
    required this.statusCode,
    required this.duration,
    required this.tokenCount,
    required this.timestamp,
  });
}

/// Suspicious pattern result (reused from other services)
class SuspiciousPatternResult {
  final bool isSuspicious;
  final bool requiresApproval;
  final String reason;

  const SuspiciousPatternResult({
    required this.isSuspicious,
    required this.requiresApproval,
    required this.reason,
  });
}

/// Risk levels (reused from other security services)
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Monitoring levels (reused from other security services)
enum MonitoringLevel {
  basic,
  enhanced,
  comprehensive,
}