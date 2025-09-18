import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/oauth_provider.dart';
import 'oauth_integration_service.dart';

/// Extensions to the OAuth integration service for enhanced functionality
extension OAuthIntegrationServiceExtensions on OAuthIntegrationService {
  
  /// Get stored token for provider
  Future<String?> getStoredToken(OAuthProvider provider) async {
    return await getValidAccessToken(provider);
  }

  /// Parse token string into data map
  Map<String, dynamic> parseToken(String token) {
    // For now, return a minimal token representation
    // In a real implementation, you'd decode the JWT or stored token format
    return {
      'access_token': token,
      'token_type': 'Bearer',
      'expires_in': 3600, // Default 1 hour
    };
  }

  /// Get detailed token information for a provider
  Future<OAuthTokenInfo?> getTokenInfo(OAuthProvider provider) async {
    try {
      final keyPrefix = 'oauth:${provider.name}';
      
      // Get stored token components using the service's built-in methods
      final accessToken = await getValidAccessToken(provider);
      if (accessToken == null) return null;
      
      // Since we can't directly access _authService, we'll use a workaround
      // In a real implementation, these would be exposed through the main service
      final refreshToken = await _getStoredRefreshToken(provider);
      final expiresAt = await _getStoredExpirationTime(provider);
      
      return OAuthTokenInfo(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: 'Bearer',
        expiresAt: expiresAt,
        issuedAt: expiresAt?.subtract(const Duration(hours: 1)),
        scopes: _getDefaultScopes(provider),
        lastRefresh: null, // Would be tracked separately
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all granted scopes for a provider
  Future<List<String>> getGrantedScopes(OAuthProvider provider) async {
    try {
      return _getDefaultScopes(provider);
    } catch (e) {
      return [];
    }
  }

  /// Helper methods for token storage access
  Future<String?> _getStoredRefreshToken(OAuthProvider provider) async {
    // This would ideally access the auth service directly
    // For now, return null since we can't access private fields
    return null;
  }

  Future<DateTime?> _getStoredExpirationTime(OAuthProvider provider) async {
    // This would ideally access the auth service directly
    // For now, return a default expiration time
    return DateTime.now().add(const Duration(hours: 1));
  }

  /// Get stored refresh token (requires auth service access)
  Future<String?> getStoredRefreshToken(OAuthProvider provider) async {
    return await _getStoredRefreshToken(provider);
  }

  /// Get stored expiration time (requires auth service access)  
  Future<DateTime?> getStoredExpirationTime(OAuthProvider provider) async {
    return await _getStoredExpirationTime(provider);
  }

  List<String> _getDefaultScopes(OAuthProvider provider) {
    // Return required scopes for each provider
    final availableScopes = getAvailableScopes(provider);
    return availableScopes
        .where((scope) => scope.isRequired)
        .map((scope) => scope.id)
        .toList();
  }

  /// Test if the OAuth connection is working
  Future<OAuthConnectionTest> testConnection(OAuthProvider provider) async {
    final startTime = DateTime.now();
    
    try {
      final token = await getStoredToken(provider);
      if (token == null) {
        return OAuthConnectionTest(
          success: false,
          duration: DateTime.now().difference(startTime),
          error: 'No token found',
        );
      }

      // Make a test API call based on provider
      final testResult = await _makeTestApiCall(provider, token);
      
      return OAuthConnectionTest(
        success: testResult.success,
        duration: DateTime.now().difference(startTime),
        error: testResult.error,
        responseData: testResult.data,
      );
    } catch (e) {
      return OAuthConnectionTest(
        success: false,
        duration: DateTime.now().difference(startTime),
        error: e.toString(),
      );
    }
  }

  /// Get available scopes for a provider
  List<OAuthScope> getAvailableScopes(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return _githubScopes;
      case OAuthProvider.slack:
        return _slackScopes;
      case OAuthProvider.linear:
        return _linearScopes;
      case OAuthProvider.microsoft:
        return _microsoftScopes;
      default:
        return [];
    }
  }

  /// Update scopes for an existing connection
  Future<bool> updateScopes(OAuthProvider provider, List<String> newScopes) async {
    try {
      // This would typically require re-authorization
      // For now, we'll simulate the process
      // Check if provider is supported
      if (!OAuthProvider.values.contains(provider)) return false;

      // Start new authorization with updated scopes
      final result = await authorize(provider, scopes: newScopes);
      return result != null;
    } catch (e) {
      return false;
    }
  }

  // Private helper methods
  DateTime? _parseExpirationTime(Map<String, dynamic> tokenData) {
    final expiresIn = tokenData['expires_in'];
    if (expiresIn is int) {
      return DateTime.now().add(Duration(seconds: expiresIn));
    }
    
    final expiresAt = tokenData['expires_at'];
    if (expiresAt is String) {
      return DateTime.tryParse(expiresAt);
    }
    
    return null;
  }

  DateTime? _parseIssuedTime(Map<String, dynamic> tokenData) {
    final issuedAt = tokenData['issued_at'];
    if (issuedAt is String) {
      return DateTime.tryParse(issuedAt);
    }
    
    // Fallback to current time minus default token lifetime
    return DateTime.now().subtract(const Duration(hours: 1));
  }

  List<String> _parseScopes(Map<String, dynamic> tokenData) {
    final scopes = tokenData['scope'];
    if (scopes is String) {
      return scopes.split(' ').where((s) => s.isNotEmpty).toList();
    }
    
    if (scopes is List) {
      return scopes.map((s) => s.toString()).toList();
    }
    
    return [];
  }

  DateTime? _getLastRefreshTime(OAuthProvider provider) {
    // This would be stored separately in your token storage
    // For now, return null
    return null;
  }

  Future<ApiTestResult> _makeTestApiCall(OAuthProvider provider, String token) async {
    switch (provider) {
      case OAuthProvider.github:
        return await _testGitHubApi(token);
      case OAuthProvider.slack:
        return await _testSlackApi(token);
      case OAuthProvider.linear:
        return await _testLinearApi(token);
      case OAuthProvider.microsoft:
        return await _testMicrosoftApi(token);
      default:
        return ApiTestResult(success: false, error: 'Unknown provider');
    }
  }

  Future<ApiTestResult> _testGitHubApi(String token) async {
    try {
      // Test GitHub API with user endpoint
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiTestResult(
          success: true,
          data: {'user': data['login'], 'id': data['id']},
        );
      } else {
        return ApiTestResult(
          success: false,
          error: 'API returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiTestResult(success: false, error: e.toString());
    }
  }

  Future<ApiTestResult> _testSlackApi(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://slack.com/api/auth.test'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return ApiTestResult(
            success: true,
            data: {'team': data['team'], 'user': data['user']},
          );
        } else {
          return ApiTestResult(
            success: false,
            error: data['error'] ?? 'Unknown Slack API error',
          );
        }
      } else {
        return ApiTestResult(
          success: false,
          error: 'API returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiTestResult(success: false, error: e.toString());
    }
  }

  Future<ApiTestResult> _testLinearApi(String token) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.linear.app/graphql'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': 'query { viewer { id name email } }',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return ApiTestResult(
            success: true,
            data: data['data']['viewer'],
          );
        } else {
          return ApiTestResult(
            success: false,
            error: data['errors']?.first['message'] ?? 'GraphQL error',
          );
        }
      } else {
        return ApiTestResult(
          success: false,
          error: 'API returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiTestResult(success: false, error: e.toString());
    }
  }

  Future<ApiTestResult> _testMicrosoftApi(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiTestResult(
          success: true,
          data: {'displayName': data['displayName'], 'id': data['id']},
        );
      } else {
        return ApiTestResult(
          success: false,
          error: 'API returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiTestResult(success: false, error: e.toString());
    }
  }
}

// OAuth scope definitions for each provider
final List<OAuthScope> _githubScopes = [
  const OAuthScope(
    id: 'repo',
    displayName: 'Repository Access',
    description: 'Full access to public and private repositories',
    category: 'Repository',
    isRequired: false,
    riskLevel: OAuthRiskLevel.high,
  ),
  const OAuthScope(
    id: 'repo:status',
    displayName: 'Repository Status',
    description: 'Access commit status',
    category: 'Repository',
    isRequired: false,
    riskLevel: OAuthRiskLevel.medium,
  ),
  const OAuthScope(
    id: 'public_repo',
    displayName: 'Public Repositories',
    description: 'Access public repositories only',
    category: 'Repository',
    isRequired: false,
    riskLevel: OAuthRiskLevel.low,
  ),
  const OAuthScope(
    id: 'user',
    displayName: 'User Information',
    description: 'Access user profile information',
    category: 'User',
    isRequired: true,
    riskLevel: OAuthRiskLevel.low,
  ),
  const OAuthScope(
    id: 'user:email',
    displayName: 'User Email',
    description: 'Access user email addresses',
    category: 'User',
    isRequired: false,
    riskLevel: OAuthRiskLevel.medium,
  ),
];

final List<OAuthScope> _slackScopes = [
  const OAuthScope(
    id: 'channels:read',
    displayName: 'Read Channels',
    description: 'View basic information about public channels',
    category: 'Channels',
    isRequired: false,
    riskLevel: OAuthRiskLevel.low,
  ),
  const OAuthScope(
    id: 'chat:write',
    displayName: 'Send Messages',
    description: 'Send messages as the user',
    category: 'Chat',
    isRequired: false,
    riskLevel: OAuthRiskLevel.high,
  ),
  const OAuthScope(
    id: 'files:read',
    displayName: 'Read Files',
    description: 'View files shared in channels and conversations',
    category: 'Files',
    isRequired: false,
    riskLevel: OAuthRiskLevel.medium,
  ),
  const OAuthScope(
    id: 'users:read',
    displayName: 'Read User Info',
    description: 'View people in the workspace',
    category: 'Users',
    isRequired: true,
    riskLevel: OAuthRiskLevel.low,
  ),
];

final List<OAuthScope> _linearScopes = [
  const OAuthScope(
    id: 'read',
    displayName: 'Read Access',
    description: 'Read issues, projects, and other data',
    category: 'General',
    isRequired: true,
    riskLevel: OAuthRiskLevel.low,
  ),
  const OAuthScope(
    id: 'write',
    displayName: 'Write Access',
    description: 'Create and update issues and comments',
    category: 'General',
    isRequired: false,
    riskLevel: OAuthRiskLevel.high,
  ),
];

final List<OAuthScope> _microsoftScopes = [
  const OAuthScope(
    id: 'User.Read',
    displayName: 'Read User Profile',
    description: 'Sign you in and read your profile',
    category: 'User',
    isRequired: true,
    riskLevel: OAuthRiskLevel.low,
  ),
  const OAuthScope(
    id: 'Files.ReadWrite',
    displayName: 'Access Files',
    description: 'Read and write access to your files',
    category: 'Files',
    isRequired: false,
    riskLevel: OAuthRiskLevel.high,
  ),
  const OAuthScope(
    id: 'Mail.Read',
    displayName: 'Read Email',
    description: 'Read your email',
    category: 'Email',
    isRequired: false,
    riskLevel: OAuthRiskLevel.medium,
  ),
  const OAuthScope(
    id: 'Calendars.ReadWrite',
    displayName: 'Manage Calendar',
    description: 'Read and write access to your calendars',
    category: 'Calendar',
    isRequired: false,
    riskLevel: OAuthRiskLevel.medium,
  ),
];

// Supporting classes
class OAuthTokenInfo {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final DateTime? expiresAt;
  final DateTime? issuedAt;
  final DateTime? lastRefresh;
  final List<String> scopes;

  const OAuthTokenInfo({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
    this.expiresAt,
    this.issuedAt,
    this.lastRefresh,
    this.scopes = const [],
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isExpiringSoon => expiresAt != null && 
      DateTime.now().add(const Duration(days: 7)).isAfter(expiresAt!);
}

class OAuthConnectionTest {
  final bool success;
  final Duration duration;
  final String? error;
  final Map<String, dynamic>? responseData;

  const OAuthConnectionTest({
    required this.success,
    required this.duration,
    this.error,
    this.responseData,
  });
}

class ApiTestResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  const ApiTestResult({
    required this.success,
    this.error,
    this.data,
  });
}

class OAuthScope {
  final String id;
  final String displayName;
  final String description;
  final String category;
  final bool isRequired;
  final OAuthRiskLevel riskLevel;

  const OAuthScope({
    required this.id,
    required this.displayName,
    required this.description,
    required this.category,
    this.isRequired = false,
    this.riskLevel = OAuthRiskLevel.low,
  });
}

enum OAuthRiskLevel {
  low,
  medium,
  high,
}