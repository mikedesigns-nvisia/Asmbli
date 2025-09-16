import 'package:json_annotation/json_annotation.dart';

part 'security_context.g.dart';

/// Security context for agent terminal operations
@JsonSerializable()
class SecurityContext {
  final String agentId;
  final List<String> allowedCommands;
  final List<String> blockedCommands;
  final Map<String, String> allowedPaths;
  final List<String> allowedNetworkHosts;
  final Map<String, APIPermission> apiPermissions;
  final ResourceLimits resourceLimits;
  final bool auditLogging;
  final TerminalPermissions terminalPermissions;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SecurityContext({
    required this.agentId,
    this.allowedCommands = const [],
    this.blockedCommands = const [],
    this.allowedPaths = const {},
    this.allowedNetworkHosts = const [],
    this.apiPermissions = const {},
    required this.resourceLimits,
    this.auditLogging = true,
    required this.terminalPermissions,
    required this.createdAt,
    this.updatedAt,
  });

  factory SecurityContext.fromJson(Map<String, dynamic> json) =>
      _$SecurityContextFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityContextToJson(this);

  /// Create a default security context for an agent
  factory SecurityContext.defaultForAgent(String agentId) {
    return SecurityContext(
      agentId: agentId,
      allowedCommands: _getDefaultAllowedCommands(),
      blockedCommands: _getDefaultBlockedCommands(),
      allowedPaths: _getDefaultAllowedPaths(),
      allowedNetworkHosts: _getDefaultAllowedHosts(),
      apiPermissions: _getDefaultAPIPermissions(),
      resourceLimits: ResourceLimits.defaultLimits(),
      terminalPermissions: TerminalPermissions.defaultPermissions(),
      createdAt: DateTime.now(),
    );
  }

  /// Create a restricted security context for untrusted operations
  factory SecurityContext.restricted(String agentId) {
    return SecurityContext(
      agentId: agentId,
      allowedCommands: _getRestrictedAllowedCommands(),
      blockedCommands: _getRestrictedBlockedCommands(),
      allowedPaths: _getRestrictedAllowedPaths(),
      allowedNetworkHosts: const [],
      apiPermissions: const {},
      resourceLimits: ResourceLimits.restrictedLimits(),
      terminalPermissions: TerminalPermissions.restrictedPermissions(),
      createdAt: DateTime.now(),
    );
  }

  /// Check if a command is allowed
  bool isCommandAllowed(String command) {
    final executable = command.split(' ').first;
    
    // Check blocked commands first
    if (blockedCommands.contains(executable)) {
      return false;
    }
    
    // If allowedCommands is empty, allow all non-blocked commands
    if (allowedCommands.isEmpty) {
      return true;
    }
    
    // Check if command is in allowed list
    return allowedCommands.contains(executable);
  }

  /// Check if a file path is accessible
  bool isPathAllowed(String path, {required bool isWrite}) {
    // Check each allowed path pattern
    for (final entry in allowedPaths.entries) {
      final allowedPath = entry.key;
      final permissions = entry.value;
      
      if (path.startsWith(allowedPath)) {
        if (isWrite) {
          return permissions.contains('w') || permissions.contains('rw');
        } else {
          return permissions.contains('r') || permissions.contains('rw');
        }
      }
    }
    
    return false;
  }

  /// Check if network access to host is allowed
  bool isNetworkHostAllowed(String host) {
    if (allowedNetworkHosts.isEmpty) {
      return false; // Default deny for network access
    }
    
    return allowedNetworkHosts.any((allowedHost) {
      // Support wildcards
      if (allowedHost.startsWith('*.')) {
        final domain = allowedHost.substring(2);
        return host.endsWith(domain);
      }
      return host == allowedHost;
    });
  }

  /// Check if API access is allowed for provider
  bool isAPIAccessAllowed(String provider, String model) {
    final permission = apiPermissions[provider];
    if (permission == null) {
      return false;
    }
    
    if (permission.allowedModels.isEmpty) {
      return true; // Allow all models if none specified
    }
    
    return permission.allowedModels.contains(model);
  }

  /// Update security context with new settings
  SecurityContext copyWith({
    List<String>? allowedCommands,
    List<String>? blockedCommands,
    Map<String, String>? allowedPaths,
    List<String>? allowedNetworkHosts,
    Map<String, APIPermission>? apiPermissions,
    ResourceLimits? resourceLimits,
    bool? auditLogging,
    TerminalPermissions? terminalPermissions,
  }) {
    return SecurityContext(
      agentId: agentId,
      allowedCommands: allowedCommands ?? this.allowedCommands,
      blockedCommands: blockedCommands ?? this.blockedCommands,
      allowedPaths: allowedPaths ?? this.allowedPaths,
      allowedNetworkHosts: allowedNetworkHosts ?? this.allowedNetworkHosts,
      apiPermissions: apiPermissions ?? this.apiPermissions,
      resourceLimits: resourceLimits ?? this.resourceLimits,
      auditLogging: auditLogging ?? this.auditLogging,
      terminalPermissions: terminalPermissions ?? this.terminalPermissions,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static List<String> _getDefaultAllowedCommands() {
    return [
      // Basic file operations
      'ls', 'dir', 'cat', 'type', 'head', 'tail', 'find', 'grep',
      'pwd', 'cd', 'mkdir', 'cp', 'copy', 'mv', 'move',
      
      // Development tools
      'git', 'npm', 'node', 'python', 'pip', 'dart', 'flutter',
      'cargo', 'rustc', 'go', 'java', 'javac', 'mvn', 'gradle',
      
      // Package managers
      'uvx', 'npx', 'yarn', 'pnpm', 'brew', 'apt', 'yum', 'dnf',
      
      // Text processing
      'echo', 'printf', 'sort', 'uniq', 'wc', 'cut', 'awk', 'sed',
      
      // System info
      'ps', 'top', 'htop', 'df', 'du', 'free', 'uname', 'whoami',
    ];
  }

  static List<String> _getDefaultBlockedCommands() {
    return [
      // System modification
      'rm', 'del', 'rmdir', 'format', 'fdisk', 'mkfs',
      'chmod', 'chown', 'chgrp', 'sudo', 'su', 'doas',
      
      // Network tools that could be dangerous
      'nc', 'netcat', 'nmap', 'telnet', 'ftp', 'tftp',
      
      // System control
      'shutdown', 'reboot', 'halt', 'systemctl', 'service',
      'kill', 'killall', 'pkill',
      
      // Dangerous utilities
      'dd', 'shred', 'wipe', 'eval', 'exec',
    ];
  }

  static List<String> _getRestrictedAllowedCommands() {
    return [
      'ls', 'dir', 'cat', 'type', 'head', 'tail', 'pwd',
      'echo', 'printf', 'git', 'npm', 'node', 'python', 'dart',
    ];
  }

  static List<String> _getRestrictedBlockedCommands() {
    return [
      // Block almost everything dangerous
      'rm', 'del', 'rmdir', 'format', 'fdisk', 'mkfs',
      'chmod', 'chown', 'chgrp', 'sudo', 'su', 'doas',
      'nc', 'netcat', 'nmap', 'telnet', 'ftp', 'tftp',
      'shutdown', 'reboot', 'halt', 'systemctl', 'service',
      'kill', 'killall', 'pkill', 'dd', 'shred', 'wipe',
      'eval', 'exec', 'curl', 'wget', 'ssh', 'scp', 'rsync',
    ];
  }

  static Map<String, String> _getDefaultAllowedPaths() {
    return {
      './': 'rw', // Current directory
      '../': 'r',  // Parent directory (read-only)
      '~/': 'rw',  // User home directory
      '/tmp/': 'rw', // Temp directory
      'C:\\temp\\': 'rw', // Windows temp
    };
  }

  static Map<String, String> _getRestrictedAllowedPaths() {
    return {
      './': 'r', // Current directory (read-only)
      '/tmp/agent_sandbox/': 'rw', // Restricted sandbox
      'C:\\temp\\agent_sandbox\\': 'rw', // Windows sandbox
    };
  }

  static List<String> _getDefaultAllowedHosts() {
    return [
      'api.anthropic.com',
      'api.openai.com',
      'localhost',
      '127.0.0.1',
      '*.github.com',
      '*.npmjs.org',
      '*.pypi.org',
    ];
  }

  static Map<String, APIPermission> _getDefaultAPIPermissions() {
    return {
      'anthropic': APIPermission(
        provider: 'anthropic',
        allowedModels: ['claude-3-sonnet-20240229', 'claude-3-haiku-20240307'],
        maxRequestsPerMinute: 60,
        maxTokensPerRequest: 4096,
        canMakeDirectCalls: true,
        requiredHeaders: {},
        secureCredentials: {},
      ),
      'openai': APIPermission(
        provider: 'openai',
        allowedModels: ['gpt-4', 'gpt-3.5-turbo'],
        maxRequestsPerMinute: 60,
        maxTokensPerRequest: 4096,
        canMakeDirectCalls: true,
        requiredHeaders: {},
        secureCredentials: {},
      ),
    };
  }
}

/// API access permissions for a specific provider
@JsonSerializable()
class APIPermission {
  final String provider;
  final List<String> allowedModels;
  final int maxRequestsPerMinute;
  final int maxTokensPerRequest;
  final bool canMakeDirectCalls;
  final Map<String, String> requiredHeaders;
  final Map<String, String> secureCredentials;

  const APIPermission({
    required this.provider,
    this.allowedModels = const [],
    this.maxRequestsPerMinute = 60,
    this.maxTokensPerRequest = 4096,
    this.canMakeDirectCalls = true,
    this.requiredHeaders = const {},
    this.secureCredentials = const {},
  });

  factory APIPermission.fromJson(Map<String, dynamic> json) =>
      _$APIPermissionFromJson(json);

  Map<String, dynamic> toJson() => _$APIPermissionToJson(this);
}

/// Resource limits for agent operations
@JsonSerializable()
class ResourceLimits {
  final int maxMemoryMB;
  final int maxCpuPercent;
  final int maxProcesses;
  final int maxOpenFiles;
  final int maxNetworkConnections;
  final Duration maxExecutionTime;
  final int maxDiskUsageMB;

  const ResourceLimits({
    this.maxMemoryMB = 512,
    this.maxCpuPercent = 50,
    this.maxProcesses = 10,
    this.maxOpenFiles = 100,
    this.maxNetworkConnections = 5,
    this.maxExecutionTime = const Duration(minutes: 5),
    this.maxDiskUsageMB = 100,
  });

  factory ResourceLimits.fromJson(Map<String, dynamic> json) =>
      _$ResourceLimitsFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceLimitsToJson(this);

  factory ResourceLimits.defaultLimits() {
    return const ResourceLimits();
  }

  factory ResourceLimits.restrictedLimits() {
    return const ResourceLimits(
      maxMemoryMB: 256,
      maxCpuPercent: 25,
      maxProcesses: 5,
      maxOpenFiles: 50,
      maxNetworkConnections: 2,
      maxExecutionTime: Duration(minutes: 2),
      maxDiskUsageMB: 50,
    );
  }
}

/// Terminal-specific permissions
@JsonSerializable()
class TerminalPermissions {
  final bool canExecuteShellCommands;
  final bool canInstallPackages;
  final bool canModifyEnvironment;
  final bool canAccessNetwork;
  final List<String> commandWhitelist;
  final List<String> commandBlacklist;
  final Map<String, String> secureEnvironmentVars;
  final bool requiresApprovalForAPICalls;

  const TerminalPermissions({
    this.canExecuteShellCommands = true,
    this.canInstallPackages = true,
    this.canModifyEnvironment = true,
    this.canAccessNetwork = true,
    this.commandWhitelist = const [],
    this.commandBlacklist = const [],
    this.secureEnvironmentVars = const {},
    this.requiresApprovalForAPICalls = false,
  });

  factory TerminalPermissions.fromJson(Map<String, dynamic> json) =>
      _$TerminalPermissionsFromJson(json);

  Map<String, dynamic> toJson() => _$TerminalPermissionsToJson(this);

  factory TerminalPermissions.defaultPermissions() {
    return const TerminalPermissions();
  }

  factory TerminalPermissions.restrictedPermissions() {
    return const TerminalPermissions(
      canExecuteShellCommands: true,
      canInstallPackages: false,
      canModifyEnvironment: false,
      canAccessNetwork: false,
      requiresApprovalForAPICalls: true,
    );
  }
}