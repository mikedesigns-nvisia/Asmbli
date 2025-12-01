import 'package:uuid/uuid.dart';

/// Categories of actions that can require verification
enum VerificationCategory {
  fileOperations,
  shellCommands,
  apiCalls,
  dataModification,
  externalCommunication,
  codeExecution,
  systemChanges,
  financialOperations,
  custom,
}

/// Risk level thresholds for automatic verification triggers
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// A rule that determines when human verification is required
class VerificationRule {
  final String id;
  final String name;
  final String description;
  final VerificationCategory category;
  final RiskLevel minimumRiskLevel;
  final bool enabled;
  final List<String> patterns; // Regex patterns to match against action descriptions
  final List<String> exemptSources; // Agent/workflow names exempt from this rule
  final Duration? autoApproveTimeout; // If set, auto-approve after timeout
  final DateTime createdAt;
  final DateTime updatedAt;

  const VerificationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.minimumRiskLevel = RiskLevel.medium,
    this.enabled = true,
    this.patterns = const [],
    this.exemptSources = const [],
    this.autoApproveTimeout,
    required this.createdAt,
    required this.updatedAt,
  });

  VerificationRule copyWith({
    String? id,
    String? name,
    String? description,
    VerificationCategory? category,
    RiskLevel? minimumRiskLevel,
    bool? enabled,
    List<String>? patterns,
    List<String>? exemptSources,
    Duration? autoApproveTimeout,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VerificationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      minimumRiskLevel: minimumRiskLevel ?? this.minimumRiskLevel,
      enabled: enabled ?? this.enabled,
      patterns: patterns ?? this.patterns,
      exemptSources: exemptSources ?? this.exemptSources,
      autoApproveTimeout: autoApproveTimeout ?? this.autoApproveTimeout,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'minimumRiskLevel': minimumRiskLevel.name,
      'enabled': enabled,
      'patterns': patterns,
      'exemptSources': exemptSources,
      'autoApproveTimeout': autoApproveTimeout?.inSeconds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VerificationRule.fromJson(Map<String, dynamic> json) {
    return VerificationRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: VerificationCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => VerificationCategory.custom,
      ),
      minimumRiskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['minimumRiskLevel'],
        orElse: () => RiskLevel.medium,
      ),
      enabled: json['enabled'] as bool? ?? true,
      patterns: (json['patterns'] as List<dynamic>?)?.cast<String>() ?? [],
      exemptSources: (json['exemptSources'] as List<dynamic>?)?.cast<String>() ?? [],
      autoApproveTimeout: json['autoApproveTimeout'] != null
          ? Duration(seconds: json['autoApproveTimeout'] as int)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Default rules that ship with the app
  static List<VerificationRule> get defaultRules {
    final now = DateTime.now();
    const uuid = Uuid();

    return [
      VerificationRule(
        id: uuid.v4(),
        name: 'File Deletion',
        description: 'Verify before deleting files or directories',
        category: VerificationCategory.fileOperations,
        minimumRiskLevel: RiskLevel.medium,
        patterns: [r'delete', r'remove', r'rm\s', r'unlink', r'rmdir'],
        createdAt: now,
        updatedAt: now,
      ),
      VerificationRule(
        id: uuid.v4(),
        name: 'Shell Commands',
        description: 'Verify before executing shell/terminal commands',
        category: VerificationCategory.shellCommands,
        minimumRiskLevel: RiskLevel.medium,
        patterns: [r'exec', r'shell', r'terminal', r'command', r'bash', r'sh\s'],
        createdAt: now,
        updatedAt: now,
      ),
      VerificationRule(
        id: uuid.v4(),
        name: 'External API Calls',
        description: 'Verify before making calls to external services',
        category: VerificationCategory.apiCalls,
        minimumRiskLevel: RiskLevel.low,
        patterns: [r'api', r'http', r'request', r'fetch', r'webhook'],
        createdAt: now,
        updatedAt: now,
      ),
      VerificationRule(
        id: uuid.v4(),
        name: 'Database Modifications',
        description: 'Verify before modifying database records',
        category: VerificationCategory.dataModification,
        minimumRiskLevel: RiskLevel.high,
        patterns: [r'database', r'sql', r'insert', r'update', r'delete.*record', r'drop'],
        createdAt: now,
        updatedAt: now,
      ),
      VerificationRule(
        id: uuid.v4(),
        name: 'Email & Messaging',
        description: 'Verify before sending emails or messages',
        category: VerificationCategory.externalCommunication,
        minimumRiskLevel: RiskLevel.medium,
        patterns: [r'email', r'send.*message', r'notify', r'slack', r'discord'],
        createdAt: now,
        updatedAt: now,
      ),
      VerificationRule(
        id: uuid.v4(),
        name: 'Code Execution',
        description: 'Verify before executing generated or dynamic code',
        category: VerificationCategory.codeExecution,
        minimumRiskLevel: RiskLevel.high,
        patterns: [r'eval', r'execute.*code', r'run.*script', r'compile'],
        createdAt: now,
        updatedAt: now,
      ),
      VerificationRule(
        id: uuid.v4(),
        name: 'System Configuration',
        description: 'Verify before changing system settings',
        category: VerificationCategory.systemChanges,
        minimumRiskLevel: RiskLevel.critical,
        patterns: [r'config', r'setting', r'environment', r'system', r'install', r'uninstall'],
        createdAt: now,
        updatedAt: now,
      ),
      VerificationRule(
        id: uuid.v4(),
        name: 'Financial Operations',
        description: 'Verify before any financial transactions or modifications',
        category: VerificationCategory.financialOperations,
        minimumRiskLevel: RiskLevel.critical,
        patterns: [r'payment', r'transaction', r'transfer', r'purchase', r'invoice', r'billing'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

/// Extension for category display names and icons
extension VerificationCategoryExtension on VerificationCategory {
  String get displayName {
    switch (this) {
      case VerificationCategory.fileOperations:
        return 'File Operations';
      case VerificationCategory.shellCommands:
        return 'Shell Commands';
      case VerificationCategory.apiCalls:
        return 'API Calls';
      case VerificationCategory.dataModification:
        return 'Data Modification';
      case VerificationCategory.externalCommunication:
        return 'External Communication';
      case VerificationCategory.codeExecution:
        return 'Code Execution';
      case VerificationCategory.systemChanges:
        return 'System Changes';
      case VerificationCategory.financialOperations:
        return 'Financial Operations';
      case VerificationCategory.custom:
        return 'Custom Rule';
    }
  }

  String get iconName {
    switch (this) {
      case VerificationCategory.fileOperations:
        return 'folder_delete';
      case VerificationCategory.shellCommands:
        return 'terminal';
      case VerificationCategory.apiCalls:
        return 'api';
      case VerificationCategory.dataModification:
        return 'storage';
      case VerificationCategory.externalCommunication:
        return 'send';
      case VerificationCategory.codeExecution:
        return 'code';
      case VerificationCategory.systemChanges:
        return 'settings';
      case VerificationCategory.financialOperations:
        return 'payments';
      case VerificationCategory.custom:
        return 'tune';
    }
  }
}

extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.critical:
        return 'Critical';
    }
  }
}
