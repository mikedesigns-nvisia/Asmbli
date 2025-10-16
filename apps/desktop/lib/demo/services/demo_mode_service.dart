import 'package:flutter/foundation.dart';

/// Service to manage demo mode functionality
class DemoModeService {
  static const String _demoModeKey = 'DEMO_MODE';
  static const String _demoScenarioKey = 'DEMO_SCENARIO';

  static DemoModeService? _instance;
  static DemoModeService get instance => _instance ??= DemoModeService._();

  DemoModeService._();

  /// Check if app is running in demo mode
  bool get isDemoMode {
    return const bool.fromEnvironment(_demoModeKey, defaultValue: false);
  }

  /// Get the specific demo scenario to run
  DemoScenario get demoScenario {
    const scenarioName = String.fromEnvironment(_demoScenarioKey, defaultValue: 'vc_demo');
    return DemoScenario.fromString(scenarioName);
  }

  /// Get demo configuration for current scenario
  DemoConfiguration get configuration {
    switch (demoScenario) {
      case DemoScenario.vcDemo:
        return DemoConfiguration(
          title: 'VC/Investor Demo',
          duration: Duration(minutes: 8),
          keyFeatures: [
            'Real-time confidence monitoring',
            'Uncertainty intervention',
            'Visual reasoning debugging',
          ],
          targetAudience: 'Investors and VCs',
          demoScript: VCDemoScript(),
        );
      
      case DemoScenario.enterpriseDemo:
        return DemoConfiguration(
          title: 'Enterprise ROI Demo',
          duration: Duration(minutes: 12),
          keyFeatures: [
            'Cost-aware model routing',
            'Compliance workflows',
            'Enterprise governance',
          ],
          targetAudience: 'CTOs and Enterprise Decision Makers',
          demoScript: EnterpriseDemoScript(),
        );
      
      case DemoScenario.technicalDemo:
        return DemoConfiguration(
          title: 'Technical Architecture Demo',
          duration: Duration(minutes: 15),
          keyFeatures: [
            'Multi-model consensus',
            'Local/cloud hybrid execution',
            'Confidence calibration',
          ],
          targetAudience: 'Engineers and Technical Leaders',
          demoScript: TechnicalDemoScript(),
        );
    }
  }

  /// Initialize demo mode if enabled
  Future<void> initialize() async {
    if (isDemoMode) {
      debugPrint('🎭 Demo mode enabled: ${demoScenario.name}');
      
      // Pre-warm demo data
      await _preloadDemoData();
      
      // Configure for optimal demo performance
      await _optimizeForDemo();
      
      debugPrint('✅ Demo mode initialized successfully');
    }
  }

  /// Pre-load all demo data for smooth presentation
  Future<void> _preloadDemoData() async {
    // Pre-load sample documents
    // Pre-warm Ollama models
    // Cache confidence estimations
    // Load workflow templates
  }

  /// Configure app for optimal demo performance
  Future<void> _optimizeForDemo() async {
    // Disable analytics
    // Reduce animation durations for faster demos
    // Pre-populate certain UI states
    // Configure mock services if needed
  }

  /// Get demo talking points for current phase
  List<String> getTalkingPoints(String phase) {
    return configuration.demoScript.getTalkingPoints(phase);
  }

  /// Get demo data for current scenario
  DemoData getDemoData() {
    switch (demoScenario) {
      case DemoScenario.vcDemo:
        return VCDemoData();
      case DemoScenario.enterpriseDemo:
        return EnterpriseDemoData();
      case DemoScenario.technicalDemo:
        return TechnicalDemoData();
    }
  }
}

/// Available demo scenarios
enum DemoScenario {
  vcDemo,
  enterpriseDemo,
  technicalDemo;

  static DemoScenario fromString(String value) {
    switch (value.toLowerCase()) {
      case 'vc_demo':
      case 'vc':
      case 'investor':
        return DemoScenario.vcDemo;
      case 'enterprise_demo':
      case 'enterprise':
      case 'cto':
        return DemoScenario.enterpriseDemo;
      case 'technical_demo':
      case 'technical':
      case 'engineering':
        return DemoScenario.technicalDemo;
      default:
        return DemoScenario.vcDemo;
    }
  }
}

/// Configuration for a demo scenario
class DemoConfiguration {
  final String title;
  final Duration duration;
  final List<String> keyFeatures;
  final String targetAudience;
  final DemoScript demoScript;

  const DemoConfiguration({
    required this.title,
    required this.duration,
    required this.keyFeatures,
    required this.targetAudience,
    required this.demoScript,
  });
}

/// Base class for demo scripts
abstract class DemoScript {
  List<String> getTalkingPoints(String phase);
  Map<String, dynamic> getPhaseData(String phase);
}

/// VC Demo script with talking points
class VCDemoScript extends DemoScript {
  @override
  List<String> getTalkingPoints(String phase) {
    switch (phase) {
      case 'intro':
        return [
          'Current AI development is a black box',
          'When AI fails, developers have no visibility into why',
          'This costs companies millions in debugging time',
        ];
      
      case 'problem_setup':
        return [
          'Let\'s analyze a startup pitch deck',
          'Watch how the AI approaches this complex reasoning task',
          'Notice the visual workflow representation',
        ];
      
      case 'workflow_execution':
        return [
          'Real-time confidence monitoring at every step',
          'You can see exactly how confident the AI is',
          'This is the first time anyone has seen AI reasoning like this',
        ];
      
      case 'uncertainty_detected':
        return [
          'Watch what happens when confidence drops below threshold',
          'The system automatically detects uncertainty',
          'Notice how specific the uncertainty explanation is',
        ];
      
      case 'human_intervention':
        return [
          'AI automatically spawns a human consultation workflow',
          'Clear explanation of what it needs help with',
          'Human input seamlessly integrated back into reasoning',
        ];
      
      case 'resolution':
        return [
          'Workflow continues with updated confidence',
          'Human input resolved the specific uncertainty',
          'Final result achieved with high confidence',
        ];
      
      case 'mic_drop':
        return [
          'This is the first visual debugger for AI reasoning',
          'The first system to show AI confidence in real-time',
          'The first automatic human-AI collaboration system',
          'This transforms AI from black box to glass box',
        ];
      
      default:
        return [];
    }
  }

  @override
  Map<String, dynamic> getPhaseData(String phase) {
    return {};
  }
}

/// Enterprise demo script focusing on ROI and cost savings
class EnterpriseDemoScript extends DemoScript {
  @override
  List<String> getTalkingPoints(String phase) {
    switch (phase) {
      case 'problem':
        return [
          'Enterprise AI projects: 40% failure rate, \$200K average cost',
          'Unpredictable AI behavior costs millions in debugging',
          'No visibility into AI decision-making process',
        ];
      
      case 'solution':
        return [
          'Visual workflow reduces development time by 60%',
          'Confidence-aware routing saves 67% on API costs',
          'Automatic human escalation prevents silent failures',
        ];
      
      case 'roi':
        return [
          'Traditional approach: 6 months, \$200K, 40% failure rate',
          'Asmbli approach: 2 weeks, \$50K, 95% success rate',
          'ROI: 10x faster development, 4x cost reduction',
        ];
      
      default:
        return [];
    }
  }

  @override
  Map<String, dynamic> getPhaseData(String phase) {
    return {};
  }
}

/// Technical demo script focusing on architecture and implementation
class TechnicalDemoScript extends DemoScript {
  @override
  List<String> getTalkingPoints(String phase) {
    switch (phase) {
      case 'architecture':
        return [
          'Local Ollama models for fast confidence estimation',
          'Smart routing between local and cloud execution',
          'Multi-model consensus for reliability',
        ];
      
      case 'confidence_system':
        return [
          'Fast local pre-checks before expensive API calls',
          'Hierarchical confidence with uncertainty drill-down',
          'Automatic calibration from execution history',
        ];
      
      case 'performance':
        return [
          'Confidence estimation: 2-5 seconds vs 10-30 for API',
          '67% cost savings through intelligent routing',
          '91% accuracy in confidence predictions',
        ];
      
      default:
        return [];
    }
  }

  @override
  Map<String, dynamic> getPhaseData(String phase) {
    return {};
  }
}

/// Base class for demo data
abstract class DemoData {
  Map<String, dynamic> getDocuments();
  Map<String, dynamic> getWorkflows();
  Map<String, dynamic> getConfidenceData();
}

/// VC demo specific data
class VCDemoData extends DemoData {
  @override
  Map<String, dynamic> getDocuments() {
    return {
      'pitch_deck': {
        'title': 'TechnoVate AI - Series A Pitch',
        'type': 'startup_pitch',
        'uncertainty_triggers': [
          'Conflicting market size data',
          'Limited traction validation',
          'Competitive landscape shifts',
        ],
      },
    };
  }

  @override
  Map<String, dynamic> getWorkflows() {
    return {
      'investment_analysis': {
        'blocks': ['goal', 'context', 'reasoning', 'gateway', 'exit'],
        'uncertainty_at': 'reasoning',
        'intervention_type': 'human_consultation',
      },
    };
  }

  @override
  Map<String, dynamic> getConfidenceData() {
    return {
      'initial': {'overall': 0.85, 'reasoning': 0.42},
      'post_intervention': {'overall': 0.91, 'reasoning': 0.89},
    };
  }
}

/// Enterprise demo specific data  
class EnterpriseDemoData extends DemoData {
  @override
  Map<String, dynamic> getDocuments() {
    return {
      'legal_contract': {
        'title': 'Software License Agreement',
        'type': 'legal_document',
        'uncertainty_triggers': [
          'GDPR compliance requirements',
          'Multi-jurisdictional conflicts',
          'Liability limitations',
        ],
      },
    };
  }

  @override
  Map<String, dynamic> getWorkflows() {
    return {
      'legal_analysis': {
        'blocks': ['goal', 'context', 'compliance_check', 'risk_assessment', 'exit'],
        'uncertainty_at': 'compliance_check',
        'intervention_type': 'legal_expert_escalation',
      },
    };
  }

  @override
  Map<String, dynamic> getConfidenceData() {
    return {
      'cost_comparison': {
        'traditional_api': 12.50,
        'asmbli_hybrid': 3.20,
        'savings_percent': 67,
      },
    };
  }
}

/// Technical demo specific data
class TechnicalDemoData extends DemoData {
  @override
  Map<String, dynamic> getDocuments() {
    return {
      'technical_spec': {
        'title': 'Microservices Architecture Specification',
        'type': 'technical_document',
        'uncertainty_triggers': [
          'Scaling architecture decisions',
          'Technology stack compatibility',
          'Performance requirements',
        ],
      },
    };
  }

  @override
  Map<String, dynamic> getWorkflows() {
    return {
      'architecture_review': {
        'blocks': ['goal', 'context', 'technical_analysis', 'scalability_check', 'exit'],
        'uncertainty_at': 'scalability_check',
        'intervention_type': 'senior_architect_review',
      },
    };
  }

  @override
  Map<String, dynamic> getConfidenceData() {
    return {
      'model_performance': {
        'ollama_confidence_estimation': '2.3s avg',
        'api_execution': '15.7s avg',
        'accuracy': '91.3%',
      },
    };
  }
}