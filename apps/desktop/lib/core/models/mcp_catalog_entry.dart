import 'package:equatable/equatable.dart';

/// MCP Catalog Entry representing an available MCP server template
class MCPCatalogEntry extends Equatable {
  final String id;
  final String name;
  final String description;
  final MCPTransportType transport;
  final String? command; // For stdio servers (uvx/npx command)
  final List<String> args; // Default command arguments
  final String? remoteUrl; // For SSE/HTTP servers
  final List<MCPAuthRequirement> requiredAuth;
  final Map<String, String>? defaultEnvVars;
  final List<String> capabilities;
  final MCPServerCategory category;
  final bool isOfficial;
  final String version;
  final List<String> supportedPlatforms;
  final MCPPricingModel? pricing;
  final String? setupInstructions;
  final String? documentationUrl;
  final bool isFeatured;
  final Map<String, dynamic>? metadata;
  final DateTime? lastUpdated;

  const MCPCatalogEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.transport,
    this.command,
    this.args = const [],
    this.remoteUrl,
    this.requiredAuth = const [],
    this.defaultEnvVars,
    this.capabilities = const [],
    this.category = MCPServerCategory.productivity,
    this.isOfficial = false,
    this.version = '1.0.0',
    this.supportedPlatforms = const ['web', 'desktop'],
    this.pricing,
    this.setupInstructions,
    this.documentationUrl,
    this.isFeatured = false,
    this.metadata,
    this.lastUpdated,
  });

  bool get hasAuth => requiredAuth.isNotEmpty;
  bool get isLocal => transport == MCPTransportType.stdio;
  bool get isRemote => transport == MCPTransportType.sse || transport == MCPTransportType.http;

  factory MCPCatalogEntry.fromJson(Map<String, dynamic> json) {
    return MCPCatalogEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      transport: MCPTransportType.values.byName(json['transport'] as String),
      command: json['command'] as String?,
      args: List<String>.from(json['args'] ?? []),
      remoteUrl: json['remoteUrl'] as String?,
      requiredAuth: (json['requiredAuth'] as List?)
          ?.map((auth) => MCPAuthRequirement.fromJson(auth))
          .toList() ?? [],
      defaultEnvVars: json['defaultEnvVars']?.cast<String, String>(),
      capabilities: List<String>.from(json['capabilities'] ?? []),
      category: MCPServerCategory.values.byName(json['category'] ?? 'productivity'),
      isOfficial: json['isOfficial'] as bool? ?? false,
      version: json['version'] as String? ?? '1.0.0',
      supportedPlatforms: List<String>.from(json['supportedPlatforms'] ?? ['web', 'desktop']),
      pricing: json['pricing'] != null ? MCPPricingModel.values.byName(json['pricing']) : null,
      setupInstructions: json['setupInstructions'] as String?,
      documentationUrl: json['documentationUrl'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'transport': transport.name,
      'command': command,
      'args': args,
      'remoteUrl': remoteUrl,
      'requiredAuth': requiredAuth.map((auth) => auth.toJson()).toList(),
      'defaultEnvVars': defaultEnvVars,
      'capabilities': capabilities,
      'category': category.name,
      'isOfficial': isOfficial,
      'version': version,
      'supportedPlatforms': supportedPlatforms,
      'pricing': pricing?.name,
      'setupInstructions': setupInstructions,
      'documentationUrl': documentationUrl,
      'isFeatured': isFeatured,
      'metadata': metadata,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  MCPCatalogEntry copyWith({
    String? id,
    String? name,
    String? description,
    MCPTransportType? transport,
    String? command,
    List<String>? args,
    String? remoteUrl,
    List<MCPAuthRequirement>? requiredAuth,
    Map<String, String>? defaultEnvVars,
    List<String>? capabilities,
    MCPServerCategory? category,
    bool? isOfficial,
    String? version,
    List<String>? supportedPlatforms,
    MCPPricingModel? pricing,
    String? setupInstructions,
    String? documentationUrl,
    bool? isFeatured,
    Map<String, dynamic>? metadata,
    DateTime? lastUpdated,
  }) {
    return MCPCatalogEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      transport: transport ?? this.transport,
      command: command ?? this.command,
      args: args ?? this.args,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      requiredAuth: requiredAuth ?? this.requiredAuth,
      defaultEnvVars: defaultEnvVars ?? this.defaultEnvVars,
      capabilities: capabilities ?? this.capabilities,
      category: category ?? this.category,
      isOfficial: isOfficial ?? this.isOfficial,
      version: version ?? this.version,
      supportedPlatforms: supportedPlatforms ?? this.supportedPlatforms,
      pricing: pricing ?? this.pricing,
      setupInstructions: setupInstructions ?? this.setupInstructions,
      documentationUrl: documentationUrl ?? this.documentationUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      metadata: metadata ?? this.metadata,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Authentication requirement for MCP server
class MCPAuthRequirement extends Equatable {
  final MCPAuthType type;
  final String name;
  final String displayName;
  final bool required;
  final String description;
  final String? placeholder;
  final bool isSecret;
  final List<String>? allowedValues;

  const MCPAuthRequirement({
    required this.type,
    required this.name,
    required this.displayName,
    this.required = true,
    this.description = '',
    this.placeholder,
    this.isSecret = true,
    this.allowedValues,
  });

  factory MCPAuthRequirement.fromJson(Map<String, dynamic> json) {
    return MCPAuthRequirement(
      type: MCPAuthType.values.byName(json['type'] as String),
      name: json['name'] as String,
      displayName: json['displayName'] as String? ?? json['name'] as String,
      required: json['required'] as bool? ?? true,
      description: json['description'] as String? ?? '',
      placeholder: json['placeholder'] as String?,
      isSecret: json['isSecret'] as bool? ?? true,
      allowedValues: json['allowedValues']?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'displayName': displayName,
      'required': required,
      'description': description,
      'placeholder': placeholder,
      'isSecret': isSecret,
      'allowedValues': allowedValues,
    };
  }

  @override
  List<Object?> get props => [type, name];
}

/// Agent-specific MCP server configuration
class AgentMCPServerConfig extends Equatable {
  final String catalogEntryId;
  final bool enabled;
  final Map<String, String> authConfig; // Auth credentials
  final Map<String, String>? customEnvVars; // Custom environment variables
  final Map<String, dynamic>? customConfig; // Custom configuration
  final DateTime createdAt;
  final DateTime? lastUsed;

  const AgentMCPServerConfig({
    required this.catalogEntryId,
    this.enabled = true,
    this.authConfig = const {},
    this.customEnvVars,
    this.customConfig,
    required this.createdAt,
    this.lastUsed,
  });

  bool get isConfigured => authConfig.isNotEmpty;

  factory AgentMCPServerConfig.fromJson(Map<String, dynamic> json) {
    return AgentMCPServerConfig(
      catalogEntryId: json['catalogEntryId'] as String,
      enabled: json['enabled'] as bool? ?? true,
      authConfig: Map<String, String>.from(json['authConfig'] ?? {}),
      customEnvVars: json['customEnvVars']?.cast<String, String>(),
      customConfig: json['customConfig'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catalogEntryId': catalogEntryId,
      'enabled': enabled,
      'authConfig': authConfig,
      'customEnvVars': customEnvVars,
      'customConfig': customConfig,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  AgentMCPServerConfig copyWith({
    String? catalogEntryId,
    bool? enabled,
    Map<String, String>? authConfig,
    Map<String, String>? customEnvVars,
    Map<String, dynamic>? customConfig,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return AgentMCPServerConfig(
      catalogEntryId: catalogEntryId ?? this.catalogEntryId,
      enabled: enabled ?? this.enabled,
      authConfig: authConfig ?? this.authConfig,
      customEnvVars: customEnvVars ?? this.customEnvVars,
      customConfig: customConfig ?? this.customConfig,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  List<Object?> get props => [catalogEntryId];
}

/// Enumerations
enum MCPTransportType {
  stdio,
  sse,
  http,
}

enum MCPAuthType {
  apiKey,
  bearerToken,
  basicAuth,
  oauth,
  database,
  complex,
  custom,
}

enum MCPServerCategory {
  ai,
  cloud,
  communication,
  database,
  design,
  development,
  filesystem,
  productivity,
  security,
  web,
}

enum MCPPricingModel {
  free,
  freemium,
  paid,
  usageBased,
}