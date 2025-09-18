import 'package:equatable/equatable.dart';

/// Status of an MCP server in the registry
enum MCPServerStatus {
  active,
  inactive,
  deprecated,
}

/// Package registry type
enum PackageRegistryType {
  npm,
  pypi,
  docker,
  github,
  custom,
}

/// Installation difficulty levels
enum InstallationDifficulty {
  beginner,    // One command, no setup
  intermediate, // Some configuration needed
  advanced,    // Complex setup, compilation, etc.
}

/// Package information from the registry
class MCPRegistryPackage extends Equatable {
  final PackageRegistryType registryType;
  final String identifier;
  final String? version;
  final String? url;

  const MCPRegistryPackage({
    required this.registryType,
    required this.identifier,
    this.version,
    this.url,
  });

  factory MCPRegistryPackage.fromJson(Map<String, dynamic> json) {
    return MCPRegistryPackage(
      registryType: _parseRegistryType(json['registry_type'] as String?),
      identifier: json['identifier'] as String,
      version: json['version'] as String?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registry_type': registryType.name,
      'identifier': identifier,
      'version': version,
      'url': url,
    };
  }

  static PackageRegistryType _parseRegistryType(String? type) {
    switch (type) {
      case 'npm': return PackageRegistryType.npm;
      case 'pypi': return PackageRegistryType.pypi;
      case 'docker': return PackageRegistryType.docker;
      case 'github': return PackageRegistryType.github;
      case 'custom': return PackageRegistryType.custom;
      default: return PackageRegistryType.custom;
    }
  }

  @override
  List<Object?> get props => [registryType, identifier, version, url];
}

/// Server entry from the GitHub MCP Registry
class GitHubMCPRegistryEntry extends Equatable {
  final String id;
  final String name;
  final String description;
  final MCPServerStatus status;
  final String? version;
  final List<MCPRegistryPackage> packages;
  final Map<String, dynamic>? meta;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GitHubMCPRegistryEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.version,
    this.packages = const [],
    this.meta,
    this.createdAt,
    this.updatedAt,
  });

  factory GitHubMCPRegistryEntry.fromJson(Map<String, dynamic> json) {
    // Extract and preserve repository info in meta if not already there
    Map<String, dynamic>? enhancedMeta = Map<String, dynamic>.from(json['_meta'] as Map<String, dynamic>? ?? {});

    if (json.containsKey('repository') && !enhancedMeta.containsKey('repository')) {
      enhancedMeta['repository'] = json['repository'];
    }

    return GitHubMCPRegistryEntry(
      id: json['id'] as String? ?? json['name'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      status: _parseStatus(json['status'] as String?),
      version: json['version'] as String?,
      packages: (json['packages'] as List<dynamic>?)
          ?.map((e) => MCPRegistryPackage.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      meta: enhancedMeta,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.name,
      'version': version,
      'packages': packages.map((e) => e.toJson()).toList(),
      '_meta': meta,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static MCPServerStatus _parseStatus(String? status) {
    switch (status) {
      case 'active': return MCPServerStatus.active;
      case 'inactive': return MCPServerStatus.inactive;
      case 'deprecated': return MCPServerStatus.deprecated;
      default: return MCPServerStatus.active;
    }
  }

  /// Check if this server is active
  bool get isActive => status == MCPServerStatus.active;

  /// Get the primary package for installation
  MCPRegistryPackage? get primaryPackage => packages.isNotEmpty ? packages.first : null;

  /// Get installation command based on package type
  String? get installationCommand {
    final package = primaryPackage;
    if (package == null) return null;

    switch (package.registryType) {
      case PackageRegistryType.npm:
        return 'npx ${package.identifier}';
      case PackageRegistryType.pypi:
        return 'uvx ${package.identifier}';
      case PackageRegistryType.docker:
        return 'docker run ${package.identifier}';
      case PackageRegistryType.github:
        return 'git clone ${package.url ?? package.identifier}';
      case PackageRegistryType.custom:
        return package.url;
    }
  }

  /// Get repository URL if available
  String? get repositoryUrl {
    // Check meta for repository info
    if (meta?.containsKey('repository') == true) {
      final repo = meta!['repository'];
      if (repo is Map && repo.containsKey('url')) {
        return repo['url'] as String?;
      } else if (repo is String) {
        return repo;
      }
    }

    // Check packages for GitHub URLs
    for (final package in packages) {
      if (package.registryType == PackageRegistryType.github) {
        return package.url ?? 'https://github.com/${package.identifier}';
      }
    }

    return null;
  }

  /// Get tags from meta or derive from name
  List<String> get tags {
    if (meta?.containsKey('tags') == true) {
      final tagsData = meta!['tags'];
      if (tagsData is List) {
        return tagsData.cast<String>();
      }
    }

    // Derive basic tags from name
    final nameParts = name.toLowerCase().split(RegExp(r'[/\-_\s]+'));
    return nameParts.where((part) => part.isNotEmpty && part.length > 2).toList();
  }

  @override
  List<Object?> get props => [
    id, name, description, status, version, packages, meta, createdAt, updatedAt
  ];
}

/// Response from the GitHub MCP Registry API
class GitHubMCPRegistryResponse extends Equatable {
  final List<GitHubMCPRegistryEntry> servers;
  final int? total;
  final String? nextCursor;

  const GitHubMCPRegistryResponse({
    required this.servers,
    this.total,
    this.nextCursor,
  });

  factory GitHubMCPRegistryResponse.fromJson(Map<String, dynamic> json) {
    return GitHubMCPRegistryResponse(
      servers: (json['servers'] as List<dynamic>?)
          ?.map((e) => GitHubMCPRegistryEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      total: json['total'] as int?,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'servers': servers.map((e) => e.toJson()).toList(),
      'total': total,
      'nextCursor': nextCursor,
    };
  }

  @override
  List<Object?> get props => [servers, total, nextCursor];
}