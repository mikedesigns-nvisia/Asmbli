import 'dart:convert';
import 'extension.dart';

enum AgentRole { developer, analyst, assistant, creative, specialist, custom }

enum TargetEnvironment { development, staging, production }

enum DeploymentFormat { desktop, docker, kubernetes, json }

class AgentConfig {
  final String agentName;
  final String agentDescription;
  final String primaryPurpose;
  final AgentRole role;
  final TargetEnvironment targetEnvironment;
  final List<String> deploymentTargets;
  final List<Extension> extensions;
  final SecurityConfig security;
  final String? tone;
  final int responseLength;
  final List<String> constraints;
  final Map<String, String> constraintDocs;
  final DeploymentFormat deploymentFormat;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgentConfig({
    required this.agentName,
    required this.agentDescription,
    required this.primaryPurpose,
    required this.role,
    required this.targetEnvironment,
    required this.deploymentTargets,
    required this.extensions,
    required this.security,
    this.tone,
    this.responseLength = 500,
    required this.constraints,
    required this.constraintDocs,
    this.deploymentFormat = DeploymentFormat.json,
    required this.createdAt,
    required this.updatedAt,
  });

  AgentConfig copyWith({
    String? agentName,
    String? agentDescription,
    String? primaryPurpose,
    AgentRole? role,
    TargetEnvironment? targetEnvironment,
    List<String>? deploymentTargets,
    List<Extension>? extensions,
    SecurityConfig? security,
    String? tone,
    int? responseLength,
    List<String>? constraints,
    Map<String, String>? constraintDocs,
    DeploymentFormat? deploymentFormat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentConfig(
      agentName: agentName ?? this.agentName,
      agentDescription: agentDescription ?? this.agentDescription,
      primaryPurpose: primaryPurpose ?? this.primaryPurpose,
      role: role ?? this.role,
      targetEnvironment: targetEnvironment ?? this.targetEnvironment,
      deploymentTargets: deploymentTargets ?? this.deploymentTargets,
      extensions: extensions ?? this.extensions,
      security: security ?? this.security,
      tone: tone ?? this.tone,
      responseLength: responseLength ?? this.responseLength,
      constraints: constraints ?? this.constraints,
      constraintDocs: constraintDocs ?? this.constraintDocs,
      deploymentFormat: deploymentFormat ?? this.deploymentFormat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AgentConfig.fromJson(Map<String, dynamic> json) {
    return AgentConfig(
      agentName: json['agentName'] as String,
      agentDescription: json['agentDescription'] as String,
      primaryPurpose: json['primaryPurpose'] as String,
      role: _parseRole(json['role'] as String),
      targetEnvironment: _parseEnvironment(json['targetEnvironment'] as String),
      deploymentTargets: List<String>.from(json['deploymentTargets'] as List),
      extensions: (json['extensions'] as List)
          .map((ext) => Extension.fromJson(ext as Map<String, dynamic>))
          .toList(),
      security: SecurityConfig.fromJson(json['security'] as Map<String, dynamic>),
      tone: json['tone'] as String?,
      responseLength: json['responseLength'] as int? ?? 500,
      constraints: List<String>.from(json['constraints'] as List),
      constraintDocs: Map<String, String>.from(json['constraintDocs'] as Map),
      deploymentFormat: _parseDeploymentFormat(json['deploymentFormat'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentName': agentName,
      'agentDescription': agentDescription,
      'primaryPurpose': primaryPurpose,
      'role': role.name,
      'targetEnvironment': targetEnvironment.name,
      'deploymentTargets': deploymentTargets,
      'extensions': extensions.map((ext) => ext.toJson()).toList(),
      'security': security.toJson(),
      'tone': tone,
      'responseLength': responseLength,
      'constraints': constraints,
      'constraintDocs': constraintDocs,
      'deploymentFormat': deploymentFormat.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJsonString() => json.encode(toJson());

  static AgentConfig fromJsonString(String jsonString) =>
      AgentConfig.fromJson(json.decode(jsonString));

  static AgentRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'developer':
        return AgentRole.developer;
      case 'analyst':
        return AgentRole.analyst;
      case 'assistant':
        return AgentRole.assistant;
      case 'creative':
        return AgentRole.creative;
      case 'specialist':
        return AgentRole.specialist;
      case 'custom':
        return AgentRole.custom;
      default:
        return AgentRole.assistant;
    }
  }

  static TargetEnvironment _parseEnvironment(String environment) {
    switch (environment.toLowerCase()) {
      case 'development':
        return TargetEnvironment.development;
      case 'staging':
        return TargetEnvironment.staging;
      case 'production':
        return TargetEnvironment.production;
      default:
        return TargetEnvironment.development;
    }
  }

  static DeploymentFormat _parseDeploymentFormat(String format) {
    switch (format.toLowerCase()) {
      case 'desktop':
        return DeploymentFormat.desktop;
      case 'docker':
        return DeploymentFormat.docker;
      case 'kubernetes':
        return DeploymentFormat.kubernetes;
      case 'json':
        return DeploymentFormat.json;
      default:
        return DeploymentFormat.json;
    }
  }
}

class SecurityConfig {
  final String? authMethod;
  final List<String> permissions;
  final String vaultIntegration;
  final bool auditLogging;
  final bool rateLimiting;
  final int sessionTimeout;

  const SecurityConfig({
    this.authMethod,
    required this.permissions,
    this.vaultIntegration = 'none',
    this.auditLogging = false,
    this.rateLimiting = true,
    this.sessionTimeout = 3600,
  });

  SecurityConfig copyWith({
    String? authMethod,
    List<String>? permissions,
    String? vaultIntegration,
    bool? auditLogging,
    bool? rateLimiting,
    int? sessionTimeout,
  }) {
    return SecurityConfig(
      authMethod: authMethod ?? this.authMethod,
      permissions: permissions ?? this.permissions,
      vaultIntegration: vaultIntegration ?? this.vaultIntegration,
      auditLogging: auditLogging ?? this.auditLogging,
      rateLimiting: rateLimiting ?? this.rateLimiting,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
    );
  }

  factory SecurityConfig.fromJson(Map<String, dynamic> json) {
    return SecurityConfig(
      authMethod: json['authMethod'] as String?,
      permissions: List<String>.from(json['permissions'] as List),
      vaultIntegration: json['vaultIntegration'] as String? ?? 'none',
      auditLogging: json['auditLogging'] as bool? ?? false,
      rateLimiting: json['rateLimiting'] as bool? ?? true,
      sessionTimeout: json['sessionTimeout'] as int? ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authMethod': authMethod,
      'permissions': permissions,
      'vaultIntegration': vaultIntegration,
      'auditLogging': auditLogging,
      'rateLimiting': rateLimiting,
      'sessionTimeout': sessionTimeout,
    };
  }
}

// MCP Server configuration generated from extensions
class MCPServerConfig {
  final String command;
  final List<String> args;
  final Map<String, String>? env;
  final String? description;

  const MCPServerConfig({
    required this.command,
    required this.args,
    this.env,
    this.description,
  });

  factory MCPServerConfig.fromJson(Map<String, dynamic> json) {
    return MCPServerConfig(
      command: json['command'] as String,
      args: List<String>.from(json['args'] as List),
      env: json['env'] != null ? Map<String, String>.from(json['env'] as Map) : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'command': command,
      'args': args,
    };
    if (env != null) result['env'] = env;
    if (description != null) result['description'] = description;
    return result;
  }
}

// Complete ChatMCP configuration
class ChatMCPConfig {
  final Map<String, MCPServerConfig> mcpServers;
  final AgentMetadata agentMetadata;

  const ChatMCPConfig({
    required this.mcpServers,
    required this.agentMetadata,
  });

  factory ChatMCPConfig.fromJson(Map<String, dynamic> json) {
    return ChatMCPConfig(
      mcpServers: (json['mcpServers'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, MCPServerConfig.fromJson(value))),
      agentMetadata: AgentMetadata.fromJson(json['agentMetadata'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mcpServers': mcpServers.map((key, value) => MapEntry(key, value.toJson())),
      'agentMetadata': agentMetadata.toJson(),
    };
  }

  String toJsonString() => json.encode(toJson());
}

class AgentMetadata {
  final String name;
  final String description;
  final String role;
  final String version;
  final String createdAt;
  final String generator;

  const AgentMetadata({
    required this.name,
    required this.description,
    required this.role,
    this.version = '1.0.0',
    required this.createdAt,
    this.generator = 'AgentEngine ChatMCP',
  });

  factory AgentMetadata.fromJson(Map<String, dynamic> json) {
    return AgentMetadata(
      name: json['name'] as String,
      description: json['description'] as String,
      role: json['role'] as String,
      version: json['version'] as String? ?? '1.0.0',
      createdAt: json['createdAt'] as String,
      generator: json['generator'] as String? ?? 'AgentEngine ChatMCP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'role': role,
      'version': version,
      'createdAt': createdAt,
      'generator': generator,
    };
  }
}