// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_mcp_registry_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MCPRegistryPackage _$MCPRegistryPackageFromJson(Map<String, dynamic> json) =>
    MCPRegistryPackage(
      registryType:
          $enumDecode(_$PackageRegistryTypeEnumMap, json['registry_type']),
      identifier: json['identifier'] as String,
      version: json['version'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$MCPRegistryPackageToJson(MCPRegistryPackage instance) =>
    <String, dynamic>{
      'registry_type': _$PackageRegistryTypeEnumMap[instance.registryType]!,
      'identifier': instance.identifier,
      'version': instance.version,
      'url': instance.url,
    };

const _$PackageRegistryTypeEnumMap = {
  PackageRegistryType.npm: 'npm',
  PackageRegistryType.pypi: 'pypi',
  PackageRegistryType.docker: 'docker',
  PackageRegistryType.github: 'github',
  PackageRegistryType.custom: 'custom',
};

GitHubMCPRegistryEntry _$GitHubMCPRegistryEntryFromJson(
        Map<String, dynamic> json) =>
    GitHubMCPRegistryEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      status: $enumDecode(_$MCPServerStatusEnumMap, json['status']),
      version: json['version'] as String?,
      packages: (json['packages'] as List<dynamic>?)
              ?.map(
                  (e) => MCPRegistryPackage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      meta: json['_meta'] as Map<String, dynamic>?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$GitHubMCPRegistryEntryToJson(
        GitHubMCPRegistryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'status': _$MCPServerStatusEnumMap[instance.status]!,
      'version': instance.version,
      'packages': instance.packages,
      '_meta': instance.meta,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$MCPServerStatusEnumMap = {
  MCPServerStatus.active: 'active',
  MCPServerStatus.inactive: 'inactive',
  MCPServerStatus.deprecated: 'deprecated',
};

GitHubMCPRegistryResponse _$GitHubMCPRegistryResponseFromJson(
        Map<String, dynamic> json) =>
    GitHubMCPRegistryResponse(
      servers: (json['servers'] as List<dynamic>)
          .map(
              (e) => GitHubMCPRegistryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$GitHubMCPRegistryResponseToJson(
        GitHubMCPRegistryResponse instance) =>
    <String, dynamic>{
      'servers': instance.servers,
      'total': instance.total,
      'nextCursor': instance.nextCursor,
    };
