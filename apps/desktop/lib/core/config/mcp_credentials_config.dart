import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'environment_config.dart';
import '../models/mcp_catalog_entry.dart';

/// Practical MCP credentials configuration for real usage
/// Handles the 4 auth types that MCP servers actually use
class MCPCredentialsConfig {
  
  /// 1. API Key configurations (most common)
  static const Map<String, MCPApiKeyConfig> _apiKeyConfigs = {
    'github': MCPApiKeyConfig(
      name: 'GitHub Personal Access Token',
      envKey: 'GITHUB_PERSONAL_ACCESS_TOKEN',
      displayName: 'GitHub PAT',
      description: 'Personal access token with repo permissions',
      placeholder: 'ghp_xxxxxxxxxxxxxxxxxxxx',
      signupUrl: 'https://github.com/settings/tokens',
      docUrl: 'https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token',
      validationPattern: r'^gh[pousr]_[A-Za-z0-9]{36}$',
      requiredScopes: ['repo', 'read:org', 'user:email'],
    ),
    
    'linear': MCPApiKeyConfig(
      name: 'Linear API Key',
      envKey: 'LINEAR_API_KEY',
      displayName: 'Linear API Key',
      description: 'Personal API key for Linear project management',
      placeholder: 'lin_api_xxxxxxxxxxxxxxxx',
      signupUrl: 'https://linear.app/settings/api',
      docUrl: 'https://developers.linear.app/docs/graphql/working-with-the-graphql-api',
      validationPattern: r'^lin_api_[A-Za-z0-9]{20,}$',
      requiredScopes: ['read', 'write'],
    ),
    
    'brave-search': MCPApiKeyConfig(
      name: 'Brave Search API Key',
      envKey: 'BRAVE_API_KEY',
      displayName: 'Brave Search API',
      description: 'API key for Brave Search web search functionality',
      placeholder: 'BSA-xxxxxxxxxxxxxxxxxxxxxxxx',
      signupUrl: 'https://api.search.brave.com/',
      docUrl: 'https://api.search.brave.com/app/documentation/web-search/get-started',
      validationPattern: r'^BSA-[A-Za-z0-9]{20,}$',
      requiredScopes: ['search'],
    ),
  };
  
  /// 2. OAuth Token configurations (for services that require full OAuth)
  static const Map<String, MCPOAuthConfig> _oauthConfigs = {
    'slack': MCPOAuthConfig(
      name: 'Slack Bot Token',
      envKey: 'SLACK_BOT_TOKEN',
      displayName: 'Slack Integration',
      description: 'Pre-generated bot token for Slack workspace access',
      placeholder: 'xoxb-xxxxxxxxxxxx-xxxxxxxxxxxx',
      authUrl: 'https://slack.com/oauth/v2/authorize',
      tokenUrl: 'https://slack.com/api/oauth.v2.access',
      scopes: ['channels:read', 'chat:write', 'files:read', 'users:read'],
      setupUrl: 'https://api.slack.com/apps',
    ),
    
    'notion': MCPOAuthConfig(
      name: 'Notion Integration Token',
      envKey: 'NOTION_API_TOKEN',
      displayName: 'Notion Integration',
      description: 'Pre-generated integration token for Notion workspace access',
      placeholder: 'secret_xxxxxxxxxxxxxxxxxxxx',
      authUrl: 'https://api.notion.com/v1/oauth/authorize',
      tokenUrl: 'https://api.notion.com/v1/oauth/token',
      scopes: ['read_content', 'update_content', 'insert_content'],
      setupUrl: 'https://www.notion.so/my-integrations',
    ),
  };
  
  /// 3. Database connection configurations
  static const Map<String, MCPDatabaseConfig> _databaseConfigs = {
    'postgres': MCPDatabaseConfig(
      name: 'PostgreSQL Database',
      envKey: 'POSTGRES_CONNECTION_STRING',
      displayName: 'PostgreSQL Connection',
      description: 'Read-only connection to PostgreSQL database',
      placeholder: 'postgresql://user:password@localhost:5432/dbname',
      docUrl: 'https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING',
      defaultPort: 5432,
      isReadOnly: true,
    ),
    
    'sqlite': MCPDatabaseConfig(
      name: 'SQLite Database',
      envKey: 'SQLITE_DATABASE_PATH',
      displayName: 'SQLite Database',
      description: 'Path to SQLite database file',
      placeholder: '/path/to/database.db',
      docUrl: 'https://sqlite.org/docs.html',
      isReadOnly: true,
    ),
  };
  
  /// 4. Cloud provider configurations (multi-credential)
  static const Map<String, MCPCloudConfig> _cloudConfigs = {
    'aws': MCPCloudConfig(
      name: 'AWS Services',
      displayName: 'AWS Integration',
      description: 'AWS credentials for S3, EC2, Lambda access',
      docUrl: 'https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html',
      fields: [
        MCPCredentialField(
          key: 'AWS_ACCESS_KEY_ID',
          displayName: 'Access Key ID',
          placeholder: 'AKIAIOSFODNN7EXAMPLE',
        ),
        MCPCredentialField(
          key: 'AWS_SECRET_ACCESS_KEY',
          displayName: 'Secret Access Key',
          placeholder: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
          isSecret: true,
        ),
        MCPCredentialField(
          key: 'AWS_DEFAULT_REGION',
          displayName: 'Default Region',
          placeholder: 'us-east-1',
        ),
      ],
    ),
  };

  /// Get API key configuration
  static MCPApiKeyConfig? getApiKeyConfig(String serviceId) {
    return _apiKeyConfigs[serviceId];
  }
  
  /// Get OAuth configuration
  static MCPOAuthConfig? getOAuthConfig(String serviceId) {
    return _oauthConfigs[serviceId];
  }
  
  /// Get database configuration
  static MCPDatabaseConfig? getDatabaseConfig(String serviceId) {
    return _databaseConfigs[serviceId];
  }
  
  /// Get cloud configuration
  static MCPCloudConfig? getCloudConfig(String serviceId) {
    return _cloudConfigs[serviceId];
  }
  
  /// Get all services requiring API keys
  static List<String> getApiKeyServices() {
    return _apiKeyConfigs.keys.toList();
  }
  
  /// Get all services requiring OAuth
  static List<String> getOAuthServices() {
    return _oauthConfigs.keys.toList();
  }
  
  /// Get all database services
  static List<String> getDatabaseServices() {
    return _databaseConfigs.keys.toList();
  }
  
  /// Get all cloud services
  static List<String> getCloudServices() {
    return _cloudConfigs.keys.toList();
  }
  
  /// Validate API key format
  static bool validateApiKey(String serviceId, String apiKey) {
    final config = _apiKeyConfigs[serviceId];
    if (config == null) return false;
    
    if (config.validationPattern != null) {
      final regex = RegExp(config.validationPattern!);
      return regex.hasMatch(apiKey);
    }
    
    return apiKey.trim().isNotEmpty && apiKey.length > 10;
  }
  
  /// Get credential status for a service
  static MCPCredentialStatus getCredentialStatus(String serviceId) {
    final env = EnvironmentConfig.instance;
    
    // Check API key services
    final apiConfig = _apiKeyConfigs[serviceId];
    if (apiConfig != null) {
      final apiKey = env.get<String>(apiConfig.envKey);
      if (apiKey != null && validateApiKey(serviceId, apiKey)) {
        return MCPCredentialStatus.configured;
      }
      return MCPCredentialStatus.notConfigured;
    }
    
    // Check OAuth services
    final oauthConfig = _oauthConfigs[serviceId];
    if (oauthConfig != null) {
      final token = env.get<String>(oauthConfig.envKey);
      if (token != null && token.trim().isNotEmpty) {
        return MCPCredentialStatus.configured;
      }
      return MCPCredentialStatus.notConfigured;
    }
    
    // Check database services
    final dbConfig = _databaseConfigs[serviceId];
    if (dbConfig != null) {
      final connectionString = env.get<String>(dbConfig.envKey);
      if (connectionString != null && connectionString.trim().isNotEmpty) {
        return MCPCredentialStatus.configured;
      }
      return MCPCredentialStatus.notConfigured;
    }
    
    // Check cloud services
    final cloudConfig = _cloudConfigs[serviceId];
    if (cloudConfig != null) {
      final allConfigured = cloudConfig.fields.every((field) {
        final value = env.get<String>(field.key);
        return value != null && value.trim().isNotEmpty;
      });
      return allConfigured ? MCPCredentialStatus.configured : MCPCredentialStatus.notConfigured;
    }
    
    return MCPCredentialStatus.notSupported;
  }
}

/// API Key configuration
class MCPApiKeyConfig {
  final String name;
  final String envKey;
  final String displayName;
  final String description;
  final String placeholder;
  final String signupUrl;
  final String docUrl;
  final String? validationPattern;
  final List<String> requiredScopes;
  
  const MCPApiKeyConfig({
    required this.name,
    required this.envKey,
    required this.displayName,
    required this.description,
    required this.placeholder,
    required this.signupUrl,
    required this.docUrl,
    this.validationPattern,
    this.requiredScopes = const [],
  });
}

/// OAuth configuration
class MCPOAuthConfig {
  final String name;
  final String envKey;
  final String displayName;
  final String description;
  final String placeholder;
  final String authUrl;
  final String tokenUrl;
  final List<String> scopes;
  final String setupUrl;
  
  const MCPOAuthConfig({
    required this.name,
    required this.envKey,
    required this.displayName,
    required this.description,
    required this.placeholder,
    required this.authUrl,
    required this.tokenUrl,
    required this.scopes,
    required this.setupUrl,
  });
}

/// Database connection configuration
class MCPDatabaseConfig {
  final String name;
  final String envKey;
  final String displayName;
  final String description;
  final String placeholder;
  final String docUrl;
  final int? defaultPort;
  final bool isReadOnly;
  
  const MCPDatabaseConfig({
    required this.name,
    required this.envKey,
    required this.displayName,
    required this.description,
    required this.placeholder,
    required this.docUrl,
    this.defaultPort,
    this.isReadOnly = true,
  });
}

/// Cloud provider configuration
class MCPCloudConfig {
  final String name;
  final String displayName;
  final String description;
  final String docUrl;
  final List<MCPCredentialField> fields;
  
  const MCPCloudConfig({
    required this.name,
    required this.displayName,
    required this.description,
    required this.docUrl,
    required this.fields,
  });
}

/// Individual credential field
class MCPCredentialField {
  final String key;
  final String displayName;
  final String placeholder;
  final bool isSecret;
  
  const MCPCredentialField({
    required this.key,
    required this.displayName,
    required this.placeholder,
    this.isSecret = false,
  });
}

/// Credential status
enum MCPCredentialStatus {
  configured,
  notConfigured,
  invalid,
  notSupported,
}