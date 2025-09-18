import 'package:equatable/equatable.dart';
import 'mcp_server_category.dart';

/// Pricing models for MCP servers
enum MCPPricingModel {
  free,
  freemium,
  paid,
  usageBased,
}

/// Transport types for MCP servers
enum MCPTransportType {
  stdio,
  sse,
  http,
}

/// MCP catalog entry representing an available MCP server
class MCPCatalogEntry extends Equatable {
  final String id;
  final String name;
  final String description;
  final String command;
  final List<String> args;
  final MCPTransportType transport;
  final String? version;
  final List<String> capabilities;
  final Map<String, String> requiredEnvVars;
  final Map<String, String> optionalEnvVars;
  final Map<String, String> defaultEnvVars;
  final String? remoteUrl;
  final String? setupInstructions;
  final bool isFeatured;
  final bool isOfficial;
  final MCPServerCategory? category;
  final MCPPricingModel? pricing;
  final List<Map<String, dynamic>> requiredAuth;
  final List<String> tags;
  final String? author;
  final String? homepage;
  final String? repository;
  final String? documentationUrl;\n  final DateTime? lastUpdated;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MCPCatalogEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.command,
    this.args = const [],
    this.transport = MCPTransportType.stdio,
    this.version,
    this.capabilities = const [],
    this.requiredEnvVars = const {},
    this.optionalEnvVars = const {},
    this.defaultEnvVars = const {},
    this.remoteUrl,
    this.setupInstructions,
    this.isFeatured = false,
    this.isOfficial = false,
    this.category,
    this.pricing,
    this.requiredAuth = const [],
    this.tags = const [],
    this.author,
    this.homepage,
    this.repository,
    this.documentationUrl,\n    this.lastUpdated,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if this server requires authentication
  bool get hasAuth => requiredAuth.isNotEmpty;

  MCPCatalogEntry copyWith({
    String? id,
    String? name,
    String? description,
    String? command,
    List<String>? args,
    MCPTransportType? transport,
    String? version,
    List<String>? capabilities,
    Map<String, String>? requiredEnvVars,
    Map<String, String>? optionalEnvVars,
    Map<String, String>? defaultEnvVars,
    String? remoteUrl,
    String? setupInstructions,
    bool? isFeatured,
    bool? isOfficial,
    MCPServerCategory? category,
    MCPPricingModel? pricing,
    List<Map<String, dynamic>>? requiredAuth,
    List<String>? tags,
    String? author,
    String? homepage,
    String? repository,
    String? documentationUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MCPCatalogEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      command: command ?? this.command,
      args: args ?? this.args,
      transport: transport ?? this.transport,
      version: version ?? this.version,
      capabilities: capabilities ?? this.capabilities,
      requiredEnvVars: requiredEnvVars ?? this.requiredEnvVars,
      optionalEnvVars: optionalEnvVars ?? this.optionalEnvVars,
      defaultEnvVars: defaultEnvVars ?? this.defaultEnvVars,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      setupInstructions: setupInstructions ?? this.setupInstructions,
      isFeatured: isFeatured ?? this.isFeatured,
      isOfficial: isOfficial ?? this.isOfficial,
      category: category ?? this.category,
      pricing: pricing ?? this.pricing,
      requiredAuth: requiredAuth ?? this.requiredAuth,
      tags: tags ?? this.tags,
      author: author ?? this.author,
      homepage: homepage ?? this.homepage,
      repository: repository ?? this.repository,
      documentationUrl: documentationUrl ?? this.documentationUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MCPCatalogEntry.fromJson(Map<String, dynamic> json) {
    return MCPCatalogEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      command: json['command'] as String,
      args: (json['args'] as List<dynamic>?)?.cast<String>() ?? [],
      transport: MCPTransportType.values.firstWhere(
        (t) => t.name == json['transport'],
        orElse: () => MCPTransportType.stdio,
      ),
      version: json['version'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? [],
      requiredEnvVars: Map<String, String>.from(json['requiredEnvVars'] as Map? ?? {}),
      optionalEnvVars: Map<String, String>.from(json['optionalEnvVars'] as Map? ?? {}),
      defaultEnvVars: Map<String, String>.from(json['defaultEnvVars'] as Map? ?? {}),
      remoteUrl: json['remoteUrl'] as String?,
      setupInstructions: json['setupInstructions'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isOfficial: json['isOfficial'] as bool? ?? false,
      category: json['category'] != null
          ? MCPServerCategory.values.firstWhere(
              (c) => c.name == json['category'],
              orElse: () => MCPServerCategory.custom,
            )
          : null,
      pricing: json['pricing'] != null
          ? MCPPricingModel.values.firstWhere(
              (p) => p.name == json['pricing'],
              orElse: () => MCPPricingModel.free,
            )
          : null,
      requiredAuth: (json['requiredAuth'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      author: json['author'] as String?,
      homepage: json['homepage'] as String?,
      repository: json['repository'] as String?,
      documentationUrl: json['documentationUrl'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'command': command,
      'args': args,
      'transport': transport.name,
      'version': version,
      'capabilities': capabilities,
      'requiredEnvVars': requiredEnvVars,
      'optionalEnvVars': optionalEnvVars,
      'defaultEnvVars': defaultEnvVars,
      'remoteUrl': remoteUrl,
      'setupInstructions': setupInstructions,
      'isFeatured': isFeatured,
      'isOfficial': isOfficial,
      'category': category?.name,
      'pricing': pricing?.name,
      'requiredAuth': requiredAuth,
      'tags': tags,
      'author': author,
      'homepage': homepage,
      'repository': repository,
      'documentationUrl': documentationUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        command,
        args,
        transport,
        version,
        capabilities,
        requiredEnvVars,
        optionalEnvVars,
        defaultEnvVars,
        remoteUrl,
        setupInstructions,
        isFeatured,
        isOfficial,
        category,
        pricing,
        requiredAuth,
        tags,
        author,
        homepage,
        repository,
        documentationUrl,
        createdAt,
        updatedAt,
      ];
}