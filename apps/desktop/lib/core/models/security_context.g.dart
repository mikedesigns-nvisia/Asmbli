// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityContext _$SecurityContextFromJson(Map<String, dynamic> json) =>
    SecurityContext(
      agentId: json['agentId'] as String,
      allowedCommands: (json['allowedCommands'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      blockedCommands: (json['blockedCommands'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      allowedPaths: (json['allowedPaths'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      allowedNetworkHosts: (json['allowedNetworkHosts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      apiPermissions: (json['apiPermissions'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, APIPermission.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      resourceLimits: ResourceLimits.fromJson(
          json['resourceLimits'] as Map<String, dynamic>),
      auditLogging: json['auditLogging'] as bool? ?? true,
      terminalPermissions: TerminalPermissions.fromJson(
          json['terminalPermissions'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SecurityContextToJson(SecurityContext instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'allowedCommands': instance.allowedCommands,
      'blockedCommands': instance.blockedCommands,
      'allowedPaths': instance.allowedPaths,
      'allowedNetworkHosts': instance.allowedNetworkHosts,
      'apiPermissions': instance.apiPermissions,
      'resourceLimits': instance.resourceLimits,
      'auditLogging': instance.auditLogging,
      'terminalPermissions': instance.terminalPermissions,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

APIPermission _$APIPermissionFromJson(Map<String, dynamic> json) =>
    APIPermission(
      provider: json['provider'] as String,
      allowedModels: (json['allowedModels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maxRequestsPerMinute:
          (json['maxRequestsPerMinute'] as num?)?.toInt() ?? 60,
      maxTokensPerRequest:
          (json['maxTokensPerRequest'] as num?)?.toInt() ?? 4096,
      canMakeDirectCalls: json['canMakeDirectCalls'] as bool? ?? true,
      requiredHeaders: (json['requiredHeaders'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      secureCredentials:
          (json['secureCredentials'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, e as String),
              ) ??
              const {},
    );

Map<String, dynamic> _$APIPermissionToJson(APIPermission instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'allowedModels': instance.allowedModels,
      'maxRequestsPerMinute': instance.maxRequestsPerMinute,
      'maxTokensPerRequest': instance.maxTokensPerRequest,
      'canMakeDirectCalls': instance.canMakeDirectCalls,
      'requiredHeaders': instance.requiredHeaders,
      'secureCredentials': instance.secureCredentials,
    };

ResourceLimits _$ResourceLimitsFromJson(Map<String, dynamic> json) =>
    ResourceLimits(
      maxMemoryMB: (json['maxMemoryMB'] as num?)?.toInt() ?? 512,
      maxCpuPercent: (json['maxCpuPercent'] as num?)?.toInt() ?? 50,
      maxProcesses: (json['maxProcesses'] as num?)?.toInt() ?? 10,
      maxOpenFiles: (json['maxOpenFiles'] as num?)?.toInt() ?? 100,
      maxNetworkConnections:
          (json['maxNetworkConnections'] as num?)?.toInt() ?? 5,
      maxExecutionTime: json['maxExecutionTime'] == null
          ? const Duration(minutes: 5)
          : Duration(microseconds: (json['maxExecutionTime'] as num).toInt()),
      maxDiskUsageMB: (json['maxDiskUsageMB'] as num?)?.toInt() ?? 100,
    );

Map<String, dynamic> _$ResourceLimitsToJson(ResourceLimits instance) =>
    <String, dynamic>{
      'maxMemoryMB': instance.maxMemoryMB,
      'maxCpuPercent': instance.maxCpuPercent,
      'maxProcesses': instance.maxProcesses,
      'maxOpenFiles': instance.maxOpenFiles,
      'maxNetworkConnections': instance.maxNetworkConnections,
      'maxExecutionTime': instance.maxExecutionTime.inMicroseconds,
      'maxDiskUsageMB': instance.maxDiskUsageMB,
    };

TerminalPermissions _$TerminalPermissionsFromJson(Map<String, dynamic> json) =>
    TerminalPermissions(
      canExecuteShellCommands: json['canExecuteShellCommands'] as bool? ?? true,
      canInstallPackages: json['canInstallPackages'] as bool? ?? true,
      canModifyEnvironment: json['canModifyEnvironment'] as bool? ?? true,
      canAccessNetwork: json['canAccessNetwork'] as bool? ?? true,
      commandWhitelist: (json['commandWhitelist'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      commandBlacklist: (json['commandBlacklist'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      secureEnvironmentVars:
          (json['secureEnvironmentVars'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, e as String),
              ) ??
              const {},
      requiresApprovalForAPICalls:
          json['requiresApprovalForAPICalls'] as bool? ?? false,
    );

Map<String, dynamic> _$TerminalPermissionsToJson(
        TerminalPermissions instance) =>
    <String, dynamic>{
      'canExecuteShellCommands': instance.canExecuteShellCommands,
      'canInstallPackages': instance.canInstallPackages,
      'canModifyEnvironment': instance.canModifyEnvironment,
      'canAccessNetwork': instance.canAccessNetwork,
      'commandWhitelist': instance.commandWhitelist,
      'commandBlacklist': instance.commandBlacklist,
      'secureEnvironmentVars': instance.secureEnvironmentVars,
      'requiresApprovalForAPICalls': instance.requiresApprovalForAPICalls,
    };
