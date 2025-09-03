import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'workflow_engine.dart';
import 'workflow_node.dart';
import 'base_agent.dart';
import 'models/workflow_models.dart';

/// Service for managing and instantiating workflow templates
class WorkflowTemplateService {
  final Map<String, WorkflowTemplate> _templates = {};
  final Map<String, WorkflowAgentFactory> _agentFactories = {};
  
  /// Register a workflow template
  void registerTemplate(WorkflowTemplate template) {
    print('📝 Registering workflow template: ${template.name} (id: ${template.id})');
    _templates[template.id] = template;
  }

  /// Register an agent factory
  void registerAgentFactory(String type, WorkflowAgentFactory factory) {
    print('🏭 Registering agent factory: $type');
    _agentFactories[type] = factory;
  }

  /// Get all registered templates
  List<WorkflowTemplate> getTemplates() {
    return _templates.values.toList();
  }

  /// Get a specific template by ID
  WorkflowTemplate? getTemplate(String id) {
    return _templates[id];
  }

  /// Create a workflow instance from a template
  Future<AgentWorkflow> createFromTemplate(
    String templateId, {
    Map<String, dynamic>? parameters,
    Map<String, Agent>? customAgents,
  }) async {
    final template = _templates[templateId];
    if (template == null) {
      throw TemplateException('Template not found: $templateId');
    }

    print('🏗️ Creating workflow from template: ${template.name}');

    final workflow = AgentWorkflow(
      name: template.name,
      description: template.description,
      version: template.version,
      metadata: Map.from(template.metadata),
    );

    // Create agents for nodes
    final agents = <String, Agent>{};
    for (final nodeTemplate in template.nodeTemplates) {
      if (nodeTemplate.type == WorkflowNodeType.agent && nodeTemplate.agentType != null) {
        // Try to get custom agent first
        Agent? agent = customAgents?[nodeTemplate.id];
        
        if (agent == null) {
          // Try to create agent from factory
          final factory = _agentFactories[nodeTemplate.agentType];
          if (factory != null) {
            agent = await factory.createAgent(
              nodeTemplate.agentType!,
              nodeTemplate.config.parameters,
            );
          }
        }
        
        if (agent == null) {
          throw TemplateException('Cannot create agent for node ${nodeTemplate.id} of type ${nodeTemplate.agentType}');
        }
        
        agents[nodeTemplate.id] = agent;
      }
    }

    // Create workflow nodes
    for (final nodeTemplate in template.nodeTemplates) {
      final node = _createNodeFromTemplate(nodeTemplate, agents, parameters);
      workflow.addNode(node);
    }

    // Add dependencies
    for (final entry in template.dependencies.entries) {
      final nodeId = entry.key;
      final dependencies = entry.value;
      
      for (final dependency in dependencies) {
        workflow.addDependency(dependency, nodeId);
      }
    }

    // Validate the created workflow
    if (!workflow.validate()) {
      throw const TemplateException('Created workflow failed validation');
    }

    print('✅ Workflow created successfully from template: ${template.name}');
    return workflow;
  }

  /// Create a node from a template
  WorkflowNode _createNodeFromTemplate(
    WorkflowNodeTemplate nodeTemplate,
    Map<String, Agent> agents,
    Map<String, dynamic>? parameters,
  ) {
    switch (nodeTemplate.type) {
      case WorkflowNodeType.agent:
        final agent = agents[nodeTemplate.id];
        if (agent == null) {
          throw TemplateException('Agent not found for node: ${nodeTemplate.id}');
        }
        return WorkflowNodeFactory.createAgentNode(
          id: nodeTemplate.id,
          agent: agent,
          config: _mergeParameters(nodeTemplate.config, parameters),
          metadata: nodeTemplate.metadata,
        );

      case WorkflowNodeType.condition:
        final condition = nodeTemplate.config.parameters['condition'] as String?;
        if (condition == null) {
          throw TemplateException('Condition node ${nodeTemplate.id} requires condition parameter');
        }
        return WorkflowNodeFactory.createConditionNode(
          id: nodeTemplate.id,
          condition: condition,
          config: _mergeParameters(nodeTemplate.config, parameters),
          metadata: nodeTemplate.metadata,
        );

      case WorkflowNodeType.transform:
        // Transform nodes need custom logic - this is a simplified implementation
        return WorkflowNodeFactory.createTransformNode(
          id: nodeTemplate.id,
          transformer: (input) => input, // Default passthrough
          config: _mergeParameters(nodeTemplate.config, parameters),
          metadata: nodeTemplate.metadata,
        );

      default:
        throw TemplateException('Unsupported node type in template: ${nodeTemplate.type}');
    }
  }

  /// Merge template configuration with runtime parameters
  NodeConfig _mergeParameters(NodeConfig templateConfig, Map<String, dynamic>? parameters) {
    if (parameters == null) return templateConfig;

    final mergedParameters = Map<String, dynamic>.from(templateConfig.parameters);
    mergedParameters.addAll(parameters);

    return NodeConfig(
      parameters: mergedParameters,
      timeout: templateConfig.timeout,
      retryAttempts: templateConfig.retryAttempts,
      retryDelay: templateConfig.retryDelay,
      continueOnError: templateConfig.continueOnError,
      requiredInputs: templateConfig.requiredInputs,
      defaultValues: templateConfig.defaultValues,
    );
  }

  /// Save templates to disk
  Future<void> saveTemplatesToFile(String filePath) async {
    print('💾 Saving ${_templates.length} templates to: $filePath');
    
    final templates = _templates.values.map((t) => t.toJson()).toList();
    final data = {
      'version': '1.0.0',
      'templates': templates,
      'exported_at': DateTime.now().toIso8601String(),
    };

    final file = File(filePath);
    await file.writeAsString(jsonEncode(data));
    print('✅ Templates saved successfully');
  }

  /// Load templates from disk
  Future<void> loadTemplatesFromFile(String filePath) async {
    print('📁 Loading templates from: $filePath');
    
    final file = File(filePath);
    if (!await file.exists()) {
      throw TemplateException('Template file not found: $filePath');
    }

    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    
    final templates = data['templates'] as List;
    int loadedCount = 0;
    
    for (final templateData in templates) {
      try {
        final template = WorkflowTemplate.fromJson(templateData);
        registerTemplate(template);
        loadedCount++;
      } catch (e) {
        print('⚠️ Failed to load template: $e');
      }
    }

    print('✅ Loaded $loadedCount templates from file');
  }

  /// Export a workflow as a reusable template
  WorkflowTemplate exportWorkflowAsTemplate(
    AgentWorkflow workflow, {
    String? templateId,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    print('📤 Exporting workflow as template: ${workflow.name}');

    final nodeTemplates = <WorkflowNodeTemplate>[];
    final dependencies = <String, List<String>>{};

    // Extract node templates
    for (final nodeId in workflow.graph.nodeIds) {
      final node = workflow.graph.getNode(nodeId)!;
      
      nodeTemplates.add(WorkflowNodeTemplate(
        id: node.id,
        type: node.type,
        agentType: node.agent?.id, // Use agent ID as type identifier
        config: node.config,
        metadata: node.metadata,
      ));

      // Extract dependencies
      final nodeDeps = workflow.graph.getParents(nodeId).toList();
      if (nodeDeps.isNotEmpty) {
        dependencies[nodeId] = nodeDeps;
      }
    }

    final template = WorkflowTemplate(
      id: templateId ?? 'template_${workflow.id}',
      name: '${workflow.name} Template',
      description: description ?? 'Template generated from ${workflow.name}',
      version: workflow.version,
      nodeTemplates: nodeTemplates,
      dependencies: dependencies,
      config: const WorkflowTemplateConfig(), // Use default config
      metadata: metadata ?? Map.from(workflow.metadata),
    );

    registerTemplate(template);
    return template;
  }

  /// Get template statistics
  TemplateServiceStats getStats() {
    final agentTypeCount = <String, int>{};
    final nodeTypeCount = <WorkflowNodeType, int>{};
    
    for (final template in _templates.values) {
      for (final nodeTemplate in template.nodeTemplates) {
        nodeTypeCount[nodeTemplate.type] = (nodeTypeCount[nodeTemplate.type] ?? 0) + 1;
        
        if (nodeTemplate.agentType != null) {
          agentTypeCount[nodeTemplate.agentType!] = (agentTypeCount[nodeTemplate.agentType!] ?? 0) + 1;
        }
      }
    }

    return TemplateServiceStats(
      totalTemplates: _templates.length,
      totalAgentFactories: _agentFactories.length,
      agentTypeCount: agentTypeCount,
      nodeTypeCount: nodeTypeCount,
    );
  }

  /// Clear all templates and factories
  void clear() {
    print('🧹 Clearing all templates and factories');
    _templates.clear();
    _agentFactories.clear();
  }
}

/// Abstract factory for creating agents
abstract class WorkflowAgentFactory {
  /// Create an agent of the specified type with the given configuration
  Future<Agent> createAgent(String type, Map<String, dynamic> config);
  
  /// Get supported agent types
  List<String> getSupportedTypes();
  
  /// Validate configuration for a specific agent type
  bool validateConfig(String type, Map<String, dynamic> config);
}

/// Built-in agent factory for common agent types
class BuiltInAgentFactory extends WorkflowAgentFactory {
  @override
  Future<Agent> createAgent(String type, Map<String, dynamic> config) async {
    switch (type) {
      case 'security':
        return CustomAgent(
          id: 'security_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Security Agent',
          description: 'Performs security analysis',
          processor: (input, context) async {
            // Simulate security analysis
            await Future.delayed(const Duration(seconds: 2));
            return SecurityAnalysisResult(
              vulnerabilities: [],
              overallSecurity: SecurityLevel.medium,
              metadata: config,
            );
          },
          requiredInputs: config['requiredInputs']?.cast<String>() ?? [],
          optionalInputs: Map<String, dynamic>.from(config['optionalInputs'] ?? {}),
        );

      case 'performance':
        return CustomAgent(
          id: 'performance_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Performance Agent',
          description: 'Performs performance analysis',
          processor: (input, context) async {
            // Simulate performance analysis
            await Future.delayed(const Duration(seconds: 3));
            return PerformanceAnalysisResult(
              issues: [],
              optimizations: [],
              metrics: const PerformanceMetrics(),
              metadata: config,
            );
          },
          requiredInputs: config['requiredInputs']?.cast<String>() ?? [],
          optionalInputs: Map<String, dynamic>.from(config['optionalInputs'] ?? {}),
        );

      case 'style':
        return CustomAgent(
          id: 'style_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Style Agent',
          description: 'Performs style analysis',
          processor: (input, context) async {
            // Simulate style analysis
            await Future.delayed(const Duration(seconds: 1));
            return StyleAnalysisResult(
              issues: [],
              metrics: const StyleMetrics(
                totalLines: 0,
                totalIssues: 0,
                styleScore: 1.0,
              ),
              metadata: config,
            );
          },
          requiredInputs: config['requiredInputs']?.cast<String>() ?? [],
          optionalInputs: Map<String, dynamic>.from(config['optionalInputs'] ?? {}),
        );

      case 'transform':
        return CustomAgent(
          id: 'transform_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Transform Agent',
          description: 'Transforms data',
          processor: (input, context) async {
            // Simple transformation - add timestamp
            if (input is Map<String, dynamic>) {
              return {
                ...input,
                'transformed_at': DateTime.now().toIso8601String(),
              };
            }
            return input;
          },
          requiredInputs: config['requiredInputs']?.cast<String>() ?? [],
          optionalInputs: Map<String, dynamic>.from(config['optionalInputs'] ?? {}),
        );

      default:
        throw ArgumentError('Unsupported agent type: $type');
    }
  }

  @override
  List<String> getSupportedTypes() {
    return ['security', 'performance', 'style', 'transform'];
  }

  @override
  bool validateConfig(String type, Map<String, dynamic> config) {
    if (!getSupportedTypes().contains(type)) {
      return false;
    }

    // Basic validation - ensure required fields exist
    return true; // Simplified validation
  }
}

/// Statistics for the template service
class TemplateServiceStats {
  final int totalTemplates;
  final int totalAgentFactories;
  final Map<String, int> agentTypeCount;
  final Map<WorkflowNodeType, int> nodeTypeCount;

  const TemplateServiceStats({
    required this.totalTemplates,
    required this.totalAgentFactories,
    required this.agentTypeCount,
    required this.nodeTypeCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalTemplates': totalTemplates,
      'totalAgentFactories': totalAgentFactories,
      'agentTypeCount': agentTypeCount,
      'nodeTypeCount': nodeTypeCount.map((k, v) => MapEntry(k.name, v)),
    };
  }

  @override
  String toString() {
    return '''TemplateServiceStats:
  Templates: $totalTemplates
  Agent Factories: $totalAgentFactories
  Agent Types: ${agentTypeCount.entries.map((e) => '${e.key}:${e.value}').join(', ')}
  Node Types: ${nodeTypeCount.entries.map((e) => '${e.key.name}:${e.value}').join(', ')}''';
  }
}

/// Exception for template-related errors
class TemplateException implements Exception {
  final String message;
  final String? templateId;
  final dynamic originalError;

  const TemplateException(
    this.message, {
    this.templateId,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('TemplateException: $message');
    if (templateId != null) {
      buffer.write(' (template: $templateId)');
    }
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}

/// Predefined workflow templates
class PredefinedTemplates {
  /// Create all predefined templates
  static List<WorkflowTemplate> createAll() {
    return [
      createCodeReviewTemplate(),
      createDataPipelineTemplate(),
      createTestingTemplate(),
      createDeploymentTemplate(),
    ];
  }

  /// Code review workflow template
  static WorkflowTemplate createCodeReviewTemplate() {
    return const WorkflowTemplate(
      id: 'code_review_template',
      name: 'Code Review Workflow',
      description: 'Parallel analysis workflow for comprehensive code review',
      nodeTemplates: [
        WorkflowNodeTemplate(
          id: 'security_check',
          type: WorkflowNodeType.agent,
          agentType: 'security',
          config: NodeConfig(
            timeout: Duration(minutes: 5),
            requiredInputs: ['code'],
          ),
        ),
        WorkflowNodeTemplate(
          id: 'performance_check',
          type: WorkflowNodeType.agent,
          agentType: 'performance',
          config: NodeConfig(
            timeout: Duration(minutes: 10),
            requiredInputs: ['code'],
          ),
        ),
        WorkflowNodeTemplate(
          id: 'style_check',
          type: WorkflowNodeType.agent,
          agentType: 'style',
          config: NodeConfig(
            timeout: Duration(minutes: 3),
            requiredInputs: ['code'],
          ),
        ),
        WorkflowNodeTemplate(
          id: 'combine',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            timeout: Duration(minutes: 2),
            parameters: {
              'operation': 'combine_analysis_results',
            },
          ),
        ),
      ],
      dependencies: {
        'combine': ['security_check', 'performance_check', 'style_check'],
      },
      config: WorkflowTemplateConfig(
        allowParallelExecution: true,
        stopOnFirstError: false,
      ),
    );
  }

  /// Data processing pipeline template
  static WorkflowTemplate createDataPipelineTemplate() {
    return const WorkflowTemplate(
      id: 'data_pipeline_template',
      name: 'Data Processing Pipeline',
      description: 'Sequential data processing workflow',
      nodeTemplates: [
        WorkflowNodeTemplate(
          id: 'ingest',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'operation': 'data_ingest'},
            timeout: Duration(minutes: 5),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'validate',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'operation': 'data_validate'},
            timeout: Duration(minutes: 3),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'transform',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'operation': 'data_transform'},
            timeout: Duration(minutes: 10),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'output',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'operation': 'data_output'},
            timeout: Duration(minutes: 2),
          ),
        ),
      ],
      dependencies: {
        'validate': ['ingest'],
        'transform': ['validate'],
        'output': ['transform'],
      },
      config: WorkflowTemplateConfig(
        allowParallelExecution: false,
        stopOnFirstError: true,
      ),
    );
  }

  /// Testing workflow template
  static WorkflowTemplate createTestingTemplate() {
    return const WorkflowTemplate(
      id: 'testing_template',
      name: 'Comprehensive Testing',
      description: 'Multi-stage testing workflow',
      nodeTemplates: [
        WorkflowNodeTemplate(
          id: 'unit_tests',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'test_type': 'unit'},
            timeout: Duration(minutes: 15),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'integration_tests',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'test_type': 'integration'},
            timeout: Duration(minutes: 30),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'coverage_check',
          type: WorkflowNodeType.condition,
          config: NodeConfig(
            parameters: {'condition': 'coverage >= 80'},
            timeout: Duration(minutes: 2),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'quality_gate',
          type: WorkflowNodeType.condition,
          config: NodeConfig(
            parameters: {'condition': 'all_tests_passed == true'},
            timeout: Duration(minutes: 1),
          ),
        ),
      ],
      dependencies: {
        'integration_tests': ['unit_tests'],
        'coverage_check': ['unit_tests', 'integration_tests'],
        'quality_gate': ['coverage_check'],
      },
      config: WorkflowTemplateConfig(
        allowParallelExecution: true,
        stopOnFirstError: true,
      ),
    );
  }

  /// Deployment workflow template
  static WorkflowTemplate createDeploymentTemplate() {
    return const WorkflowTemplate(
      id: 'deployment_template',
      name: 'Application Deployment',
      description: 'Automated deployment workflow',
      nodeTemplates: [
        WorkflowNodeTemplate(
          id: 'build',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'operation': 'build_application'},
            timeout: Duration(minutes: 20),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'security_scan',
          type: WorkflowNodeType.agent,
          agentType: 'security',
          config: NodeConfig(
            timeout: Duration(minutes: 10),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'deploy_staging',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'environment': 'staging'},
            timeout: Duration(minutes: 10),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'smoke_tests',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'test_type': 'smoke'},
            timeout: Duration(minutes: 5),
          ),
        ),
        WorkflowNodeTemplate(
          id: 'deploy_production',
          type: WorkflowNodeType.agent,
          agentType: 'transform',
          config: NodeConfig(
            parameters: {'environment': 'production'},
            timeout: Duration(minutes: 10),
          ),
        ),
      ],
      dependencies: {
        'security_scan': ['build'],
        'deploy_staging': ['build', 'security_scan'],
        'smoke_tests': ['deploy_staging'],
        'deploy_production': ['smoke_tests'],
      },
      config: WorkflowTemplateConfig(
        allowParallelExecution: true,
        stopOnFirstError: true,
      ),
    );
  }
}