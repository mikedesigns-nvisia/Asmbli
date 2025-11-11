import 'package:flutter/material.dart';
import 'demo/components/confidence_indicator.dart';

void main() {
  runApp(const DemoTestApp());
}

class DemoTestApp extends StatelessWidget {
  const DemoTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DemoTestScreen(),
    );
  }
}

class DemoTestScreen extends StatelessWidget {
  const DemoTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Test'),
      ),
      body: ConfidenceMicroscopyWidget(
        confidenceTree: _buildTestConfidenceTree(),
        onNodeTap: (node) {
          print('Node tapped: ${node.taskName}');
        },
        onInterventionTrigger: (intervention) {
          print('Intervention triggered: ${intervention.reason}');
        },
      ),
    );
  }

  ConfidenceTree _buildTestConfidenceTree() {
    return ConfidenceTree(
      root: ConfidenceNode(
        taskName: 'Analyze Investment Opportunity',
        taskType: 'goal',
        confidence: 0.85,
        uncertaintyReason: 'Overall analysis confidence',
        children: [
          ConfidenceNode(
            taskName: 'Company Overview',
            taskType: 'context',
            confidence: 0.94,
            uncertaintyReason: 'Clear company information available',
          ),
          ConfidenceNode(
            taskName: 'Market Analysis',
            taskType: 'reasoning',
            confidence: 0.42,
            uncertaintyReason: 'Conflicting market size data sources',
            requiredExpertise: 'Market Research',
            requiresIntervention: true,
            children: [
              ConfidenceNode(
                taskName: 'Market Size Estimation',
                taskType: 'reasoning',
                confidence: 0.23,
                uncertaintyReason: 'Company claims \$50M vs Industry report \$12M',
                requiredExpertise: 'Market Research',
                requiresIntervention: true,
              ),
              ConfidenceNode(
                taskName: 'Growth Rate Analysis',
                taskType: 'reasoning',
                confidence: 0.67,
                uncertaintyReason: 'Pre-recession projections may be outdated',
              ),
            ],
          ),
          ConfidenceNode(
            taskName: 'Financial Assessment',
            taskType: 'reasoning',
            confidence: 0.88,
            uncertaintyReason: 'Clear financial data provided',
          ),
        ],
      ),
    );
  }
}