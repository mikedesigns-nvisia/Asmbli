import 'dart:async';
import 'models/workflow_models.dart';

/// Abstract base class for all agents in the workflow system
abstract class Agent {
  /// Unique identifier for this agent
  String get id;
  
  /// Human-readable name for this agent
  String get name;
  
  /// Description of what this agent does
  String get description;
  
  /// Version of this agent
  String get version => '1.0.0';
  
  /// Agent capabilities and metadata
  Map<String, dynamic> get metadata => {};

  /// Process input and return output
  Future<dynamic> process(dynamic input, [ExecutionContext? context]);

  /// Validate that the input is acceptable for this agent
  bool canProcess(dynamic input) => true;

  /// Get required input parameters
  List<String> get requiredInputs => [];

  /// Get optional input parameters with defaults
  Map<String, dynamic> get optionalInputs => {};

  /// Initialize the agent (called once before first use)
  Future<void> initialize() async {}

  /// Cleanup resources when agent is no longer needed
  Future<void> dispose() async {}

  /// Health check for the agent
  Future<bool> healthCheck() async => true;
}

/// Specialized agent for security analysis
abstract class SecurityAgent extends Agent {
  @override
  String get name => 'Security Analyzer';
  
  @override
  String get description => 'Analyzes code for security vulnerabilities';

  /// Analyze code for security issues
  Future<SecurityAnalysisResult> analyzeCode(String code, [Map<String, dynamic>? context]);

  /// Check for common vulnerability patterns
  Future<List<SecurityVulnerability>> checkVulnerabilities(String code);
}

/// Specialized agent for performance analysis
abstract class PerformanceAgent extends Agent {
  @override
  String get name => 'Performance Analyzer';
  
  @override
  String get description => 'Analyzes code for performance issues';

  /// Analyze code for performance bottlenecks
  Future<PerformanceAnalysisResult> analyzePerformance(String code, [Map<String, dynamic>? context]);

  /// Suggest performance optimizations
  Future<List<PerformanceOptimization>> suggestOptimizations(String code);
}

/// Specialized agent for code style analysis
abstract class StyleAgent extends Agent {
  @override
  String get name => 'Style Analyzer';
  
  @override
  String get description => 'Analyzes code for style and formatting issues';

  /// Check code style and formatting
  Future<StyleAnalysisResult> analyzeStyle(String code, [Map<String, dynamic>? context]);

  /// Apply automatic style fixes
  Future<String> applyStyleFixes(String code);
}

/// Generic implementation of Agent for custom logic
class CustomAgent extends Agent {
  final String _id;
  final String _name;
  final String _description;
  final Future<dynamic> Function(dynamic input, ExecutionContext? context) _processor;
  final bool Function(dynamic input)? _validator;
  final List<String> _requiredInputs;
  final Map<String, dynamic> _optionalInputs;
  final Map<String, dynamic> _metadata;

  CustomAgent({
    required String id,
    required String name,
    required String description,
    required Future<dynamic> Function(dynamic input, ExecutionContext? context) processor,
    bool Function(dynamic input)? validator,
    List<String> requiredInputs = const [],
    Map<String, dynamic> optionalInputs = const {},
    Map<String, dynamic> metadata = const {},
  }) : _id = id,
       _name = name,
       _description = description,
       _processor = processor,
       _validator = validator,
       _requiredInputs = requiredInputs,
       _optionalInputs = optionalInputs,
       _metadata = metadata;

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  List<String> get requiredInputs => _requiredInputs;

  @override
  Map<String, dynamic> get optionalInputs => _optionalInputs;

  @override
  Map<String, dynamic> get metadata => _metadata;

  @override
  Future<dynamic> process(dynamic input, [ExecutionContext? context]) {
    return _processor(input, context);
  }

  @override
  bool canProcess(dynamic input) {
    return _validator?.call(input) ?? super.canProcess(input);
  }
}

/// Results from security analysis
class SecurityAnalysisResult {
  final List<SecurityVulnerability> vulnerabilities;
  final SecurityLevel overallSecurity;
  final Map<String, dynamic> metadata;

  const SecurityAnalysisResult({
    required this.vulnerabilities,
    required this.overallSecurity,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'vulnerabilities': vulnerabilities.map((v) => v.toJson()).toList(),
      'overallSecurity': overallSecurity.name,
      'metadata': metadata,
    };
  }
}

/// Security vulnerability information
class SecurityVulnerability {
  final String type;
  final String description;
  final SecuritySeverity severity;
  final String location;
  final String? suggestion;

  const SecurityVulnerability({
    required this.type,
    required this.description,
    required this.severity,
    required this.location,
    this.suggestion,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'severity': severity.name,
      'location': location,
      'suggestion': suggestion,
    };
  }
}

enum SecurityLevel { low, medium, high, critical }
enum SecuritySeverity { info, low, medium, high, critical }

/// Results from performance analysis
class PerformanceAnalysisResult {
  final List<PerformanceIssue> issues;
  final List<PerformanceOptimization> optimizations;
  final PerformanceMetrics metrics;
  final Map<String, dynamic> metadata;

  const PerformanceAnalysisResult({
    required this.issues,
    required this.optimizations,
    required this.metrics,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'issues': issues.map((i) => i.toJson()).toList(),
      'optimizations': optimizations.map((o) => o.toJson()).toList(),
      'metrics': metrics.toJson(),
      'metadata': metadata,
    };
  }
}

/// Performance issue information
class PerformanceIssue {
  final String type;
  final String description;
  final PerformanceSeverity severity;
  final String location;
  final double? impact;

  const PerformanceIssue({
    required this.type,
    required this.description,
    required this.severity,
    required this.location,
    this.impact,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'severity': severity.name,
      'location': location,
      'impact': impact,
    };
  }
}

/// Performance optimization suggestion
class PerformanceOptimization {
  final String type;
  final String description;
  final String location;
  final double? estimatedImprovement;
  final String? codeExample;

  const PerformanceOptimization({
    required this.type,
    required this.description,
    required this.location,
    this.estimatedImprovement,
    this.codeExample,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'location': location,
      'estimatedImprovement': estimatedImprovement,
      'codeExample': codeExample,
    };
  }
}

/// Performance metrics
class PerformanceMetrics {
  final double? complexity;
  final int? linesOfCode;
  final int? cyclomaticComplexity;
  final Map<String, double> customMetrics;

  const PerformanceMetrics({
    this.complexity,
    this.linesOfCode,
    this.cyclomaticComplexity,
    this.customMetrics = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'complexity': complexity,
      'linesOfCode': linesOfCode,
      'cyclomaticComplexity': cyclomaticComplexity,
      'customMetrics': customMetrics,
    };
  }
}

enum PerformanceSeverity { info, low, medium, high, critical }

/// Results from style analysis
class StyleAnalysisResult {
  final List<StyleIssue> issues;
  final StyleMetrics metrics;
  final Map<String, dynamic> metadata;

  const StyleAnalysisResult({
    required this.issues,
    required this.metrics,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'issues': issues.map((i) => i.toJson()).toList(),
      'metrics': metrics.toJson(),
      'metadata': metadata,
    };
  }
}

/// Style issue information
class StyleIssue {
  final String type;
  final String description;
  final StyleSeverity severity;
  final String location;
  final String? suggestion;
  final bool autoFixable;

  const StyleIssue({
    required this.type,
    required this.description,
    required this.severity,
    required this.location,
    this.suggestion,
    this.autoFixable = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'severity': severity.name,
      'location': location,
      'suggestion': suggestion,
      'autoFixable': autoFixable,
    };
  }
}

/// Style metrics
class StyleMetrics {
  final int totalLines;
  final int totalIssues;
  final double styleScore;
  final Map<String, int> issuesByType;

  const StyleMetrics({
    required this.totalLines,
    required this.totalIssues,
    required this.styleScore,
    this.issuesByType = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'totalLines': totalLines,
      'totalIssues': totalIssues,
      'styleScore': styleScore,
      'issuesByType': issuesByType,
    };
  }
}

enum StyleSeverity { info, warning, error }

/// Factory for creating common agent types
class AgentFactory {
  static CustomAgent createSimple({
    required String id,
    required String name,
    required Future<dynamic> Function(dynamic) processor,
  }) {
    return CustomAgent(
      id: id,
      name: name,
      description: 'Simple agent: $name',
      processor: (input, context) => processor(input),
    );
  }

  static CustomAgent createTransform({
    required String id,
    required String name,
    required dynamic Function(dynamic) transformer,
  }) {
    return CustomAgent(
      id: id,
      name: name,
      description: 'Transform agent: $name',
      processor: (input, context) async => transformer(input),
    );
  }

  static CustomAgent createCondition({
    required String id,
    required String name,
    required bool Function(dynamic) condition,
  }) {
    return CustomAgent(
      id: id,
      name: name,
      description: 'Condition agent: $name',
      processor: (input, context) async => ConditionResult(
        passed: condition(input),
        reason: 'Condition evaluated',
      ),
    );
  }
}