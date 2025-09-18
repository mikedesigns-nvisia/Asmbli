import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'environment_config.dart';

/// OAuth 2.0 client configurations for production use
/// These should be loaded from secure environment variables or config files
class OAuthConfig {
  // Base OAuth App Configurations (client secrets loaded from environment)
  static const Map<String, OAuthClientConfig> _baseConfigs = {
    'github': OAuthClientConfig(
      clientId: '', // Loaded from environment: GITHUB_CLIENT_ID
      clientSecret: '', // Loaded from environment: GITHUB_CLIENT_SECRET
      redirectUri: '', // Loaded from environment: GITHUB_REDIRECT_URI or default
      authUrl: 'https://github.com/login/oauth/authorize',
      tokenUrl: 'https://github.com/login/oauth/access_token',
      scopes: ['user:email', 'repo', 'read:org'],
      additionalParams: {
        'allow_signup': 'true',
      },
    ),
    
    'slack': OAuthClientConfig(
      clientId: '', // Loaded from environment: SLACK_CLIENT_ID
      clientSecret: '', // Loaded from environment: SLACK_CLIENT_SECRET
      redirectUri: '', // Loaded from environment: SLACK_REDIRECT_URI or default
      authUrl: 'https://slack.com/oauth/v2/authorize',
      tokenUrl: 'https://slack.com/api/oauth.v2.access',
      scopes: ['channels:read', 'chat:write', 'files:read', 'users:read'],
      additionalParams: {
        'user_scope': 'openid,profile,email',
      },
    ),
    
    'linear': OAuthClientConfig(
      clientId: '', // Loaded from environment: LINEAR_CLIENT_ID
      clientSecret: '', // Loaded from environment: LINEAR_CLIENT_SECRET
      redirectUri: '', // Loaded from environment: LINEAR_REDIRECT_URI or default
      authUrl: 'https://linear.app/oauth/authorize',
      tokenUrl: 'https://api.linear.app/oauth/token',
      scopes: ['read', 'write'],
      additionalParams: {
        'prompt': 'consent',
      },
    ),
    
    'microsoft': OAuthClientConfig(
      clientId: '', // Loaded from environment: MICROSOFT_CLIENT_ID
      clientSecret: '', // Loaded from environment: MICROSOFT_CLIENT_SECRET  
      redirectUri: '', // Loaded from environment: MICROSOFT_REDIRECT_URI or default
      authUrl: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
      tokenUrl: 'https://login.microsoftonline.com/common/oauth2/v2.0/token',
      scopes: ['https://graph.microsoft.com/User.Read', 'https://graph.microsoft.com/Mail.Read'],
      additionalParams: {
        'response_mode': 'query',
        'prompt': 'select_account',
      },
    ),
    
    'notion': OAuthClientConfig(
      clientId: '', // Loaded from environment: NOTION_CLIENT_ID
      clientSecret: '', // Loaded from environment: NOTION_CLIENT_SECRET
      redirectUri: '', // Loaded from environment: NOTION_REDIRECT_URI or default
      authUrl: 'https://api.notion.com/v1/oauth/authorize',
      tokenUrl: 'https://api.notion.com/v1/oauth/token',
      scopes: ['read_content', 'update_content', 'insert_content'],
      additionalParams: {
        'owner': 'user',
      },
    ),
    
    'brave-search': OAuthClientConfig(
      clientId: '', // Not OAuth - uses API key directly
      clientSecret: '', // Not used for Brave Search
      redirectUri: '', // Not used
      authUrl: '', // Not OAuth-based
      tokenUrl: '', // Not OAuth-based
      scopes: [],
      additionalParams: {
        'auth_type': 'api_key', // Custom flag to indicate API key auth
      },
    ),
  };

  /// Get OAuth configuration for a service with environment loading
  static OAuthClientConfig getConfig(String service) {
    final config = _baseConfigs[service.toLowerCase()];
    
    if (config == null) {
      throw Exception('OAuth configuration not found for service: $service');
    }

    // Load from environment configuration
    final env = EnvironmentConfig.instance;
    final oauthConfig = env.getOAuthConfig(service);
    
    final clientId = oauthConfig['client_id'] ?? 
                    env.get<String>('${service.toUpperCase()}_CLIENT_ID') ?? 
                    _getDefaultClientId(service);
                    
    final clientSecret = oauthConfig['client_secret'] ?? 
                        env.get<String>('${service.toUpperCase()}_CLIENT_SECRET') ?? '';
                        
    final redirectUri = oauthConfig['redirect_uri'] ?? 
                       env.get<String>('${service.toUpperCase()}_REDIRECT_URI') ?? 
                       _getDefaultRedirectUri();

    if (clientId.isEmpty) {
      throw Exception('OAuth client ID not configured for $service. Set ${service.toUpperCase()}_CLIENT_ID environment variable or config.');
    }
    
    if (clientSecret.isEmpty && env.isProduction) {
      throw Exception('OAuth client secret required for $service in production. Set ${service.toUpperCase()}_CLIENT_SECRET environment variable.');
    }

    return config.copyWith(
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUri: redirectUri,
    );
  }
  
  /// Get default client ID for development
  static String _getDefaultClientId(String service) {
    // Only provide defaults for development - production must be explicitly configured
    if (!EnvironmentConfig.instance.isDevelopment) return '';
    
    switch (service.toLowerCase()) {
      case 'github':
        return 'Iv23liDevGitHubClientId'; // Development GitHub App ID
      case 'slack':
        return '7842031847.dev'; // Development Slack App ID
      case 'linear':
        return 'asmbli-desktop-dev'; // Development Linear App ID
      case 'microsoft':
        return '12345678-dev-client-id'; // Development Azure App ID
      case 'notion':
        return 'notion-dev-client-id'; // Development Notion App ID
      case 'brave-search':
        return 'dev-api-key-placeholder'; // Development Brave API key placeholder
      default:
        return '';
    }
  }
  
  /// Get default redirect URI based on environment
  static String _getDefaultRedirectUri() {
    final env = EnvironmentConfig.instance;
    
    if (env.isDevelopment) {
      return 'http://localhost:8080/oauth/callback';
    } else if (env.isStaging) {
      return 'https://staging.asmbli.com/oauth/callback';
    } else {
      return 'https://app.asmbli.com/oauth/callback';
    }
  }

  /// Get all available OAuth services
  static List<String> getAvailableServices() {
    return _baseConfigs.keys.toList();
  }

  /// Check if service is configured
  static bool isServiceConfigured(String service) {
    try {
      getConfig(service);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load custom configuration from file (for enterprise deployments)
  static Future<OAuthClientConfig?> loadCustomConfig(String service) async {
    try {
      final configFile = File('oauth_config.json');
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final Map<String, dynamic> configs = json.decode(content);
        
        if (configs.containsKey(service)) {
          return OAuthClientConfig.fromJson(configs[service]);
        }
      }
    } catch (e) {
      print('Failed to load custom OAuth config for $service: $e');
    }
    return null;
  }

  /// Validate OAuth configuration
  static bool validateConfig(OAuthClientConfig config) {
    // Check required fields
    if (config.clientId.isEmpty) return false;
    if (config.authUrl.isEmpty) return false;
    if (config.tokenUrl.isEmpty) return false;
    if (config.redirectUri.isEmpty) return false;
    
    // Validate URLs
    try {
      Uri.parse(config.authUrl);
      Uri.parse(config.tokenUrl);
      Uri.parse(config.redirectUri);
    } catch (e) {
      return false;
    }
    
    return true;
  }
}

/// OAuth client configuration model
class OAuthClientConfig {
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final String authUrl;
  final String tokenUrl;
  final List<String> scopes;
  final Map<String, String> additionalParams;
  final String? revokeUrl;
  final String? userInfoUrl;

  const OAuthClientConfig({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.authUrl,
    required this.tokenUrl,
    required this.scopes,
    this.additionalParams = const {},
    this.revokeUrl,
    this.userInfoUrl,
  });

  /// Create copy with updated values
  OAuthClientConfig copyWith({
    String? clientId,
    String? clientSecret,
    String? redirectUri,
    String? authUrl,
    String? tokenUrl,
    List<String>? scopes,
    Map<String, String>? additionalParams,
    String? revokeUrl,
    String? userInfoUrl,
  }) {
    return OAuthClientConfig(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      redirectUri: redirectUri ?? this.redirectUri,
      authUrl: authUrl ?? this.authUrl,
      tokenUrl: tokenUrl ?? this.tokenUrl,
      scopes: scopes ?? this.scopes,
      additionalParams: additionalParams ?? this.additionalParams,
      revokeUrl: revokeUrl ?? this.revokeUrl,
      userInfoUrl: userInfoUrl ?? this.userInfoUrl,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'clientSecret': clientSecret,
      'redirectUri': redirectUri,
      'authUrl': authUrl,
      'tokenUrl': tokenUrl,
      'scopes': scopes,
      'additionalParams': additionalParams,
      'revokeUrl': revokeUrl,
      'userInfoUrl': userInfoUrl,
    };
  }

  /// Create from JSON
  factory OAuthClientConfig.fromJson(Map<String, dynamic> json) {
    return OAuthClientConfig(
      clientId: json['clientId'] ?? '',
      clientSecret: json['clientSecret'] ?? '',
      redirectUri: json['redirectUri'] ?? '',
      authUrl: json['authUrl'] ?? '',
      tokenUrl: json['tokenUrl'] ?? '',
      scopes: List<String>.from(json['scopes'] ?? []),
      additionalParams: Map<String, String>.from(json['additionalParams'] ?? {}),
      revokeUrl: json['revokeUrl'],
      userInfoUrl: json['userInfoUrl'],
    );
  }

  /// Get authorization URL with PKCE
  Uri buildAuthUrl({
    required String state,
    String? codeChallenge,
    String? codeChallengeMethod,
  }) {
    final params = <String, String>{
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes.join(' '),
      'state': state,
      ...additionalParams,
    };

    // Add PKCE parameters if provided
    if (codeChallenge != null && codeChallengeMethod != null) {
      params['code_challenge'] = codeChallenge;
      params['code_challenge_method'] = codeChallengeMethod;
    }

    return Uri.parse(authUrl).replace(queryParameters: params);
  }

  /// Build token exchange request body
  Map<String, String> buildTokenRequest({
    required String code,
    String? codeVerifier,
  }) {
    final body = <String, String>{
      'grant_type': 'authorization_code',
      'client_id': clientId,
      'client_secret': clientSecret,
      'code': code,
      'redirect_uri': redirectUri,
    };

    // Add PKCE code verifier if provided
    if (codeVerifier != null) {
      body['code_verifier'] = codeVerifier;
    }

    return body;
  }

  /// Build refresh token request body
  Map<String, String> buildRefreshRequest(String refreshToken) {
    return {
      'grant_type': 'refresh_token',
      'client_id': clientId,
      'client_secret': clientSecret,
      'refresh_token': refreshToken,
    };
  }

  @override
  String toString() {
    return 'OAuthClientConfig(clientId: $clientId, authUrl: $authUrl, scopes: $scopes)';
  }
}