import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/design_system.dart';
import '../../core/constants/routes.dart';
import '../components/simulated_document_processor.dart';
import '../components/simulated_ai_reasoning.dart';
import '../components/confidence_microscopy_widget.dart';

/// Complete VC demo with all simulated components
class CompleteVCDemo extends StatefulWidget {
  const CompleteVCDemo({super.key});

  @override
  State<CompleteVCDemo> createState() => _CompleteVCDemoState();
}

class _CompleteVCDemoState extends State<CompleteVCDemo> {
  DemoStage _currentStage = DemoStage.introduction;
  ProcessingResult? _processingResult;
  ConfidenceTree? _currentConfidenceTree;
  bool _showingIntervention = false;
  String? _humanResponse;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDemoHeader(colors),
              Expanded(
                child: _buildCurrentStage(colors),
              ),
              _buildDemoControls(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asmbli Demo: Visual AI Reasoning',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                Text(
                  _getStageDescription(),
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // Home button
          AsmblButton.secondary(
            text: 'Home',
            icon: Icons.home,
            onPressed: () => context.go(AppRoutes.home),
            size: AsmblButtonSize.small,
          ),
          
          const SizedBox(width: SpacingTokens.md),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              border: Border.all(color: Colors.red),
            ),
            child: Text(
              'LIVE DEMO',
              style: TextStyles.bodySmall.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStage(ThemeColors colors) {
    switch (_currentStage) {
      case DemoStage.introduction:
        return _buildIntroduction(colors);
      case DemoStage.problemStatement:
        return _buildProblemStatement(colors);
      case DemoStage.documentUpload:
        return _buildDocumentUpload(colors);
      case DemoStage.aiReasoning:
        return _buildAIReasoning(colors);
      case DemoStage.uncertaintyIntervention:
        return _buildUncertaintyIntervention(colors);
      case DemoStage.humanCollaboration:
        return _buildHumanCollaboration(colors);
      case DemoStage.resolution:
        return _buildResolution(colors);
      case DemoStage.conclusion:
        return _buildConclusion(colors);
    }
  }

  Widget _buildIntroduction(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: colors.primary,
            ),
            const SizedBox(height: SpacingTokens.xl),
            Text(
              'AI Reasoning Transparency Demo',
              style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'This demonstration shows AI reasoning processes with real-time confidence monitoring and automatic uncertainty detection.',
              style: TextStyles.bodyLarge.copyWith(
                color: colors.onSurface,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.xl),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Features demonstrated:',
                    style: TextStyles.bodyLarge.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  ...[
                    'Real-time AI confidence monitoring',
                    'Visual reasoning process transparency',
                    'Automatic uncertainty detection',
                    'Human-AI collaboration workflow',
                  ].map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: colors.primary, size: 20),
                        const SizedBox(width: SpacingTokens.sm),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemStatement(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xl),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_off,
                  size: 64,
                  color: colors.error,
                ),
                const SizedBox(height: SpacingTokens.xl),
                Text(
                  'Current AI Development Challenges',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.lg),
                Text(
                  'Traditional AI systems lack transparency in their reasoning processes, making debugging and error analysis difficult.',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traditional AI Development:',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  _TypewriterText('\$ python my_ai_script.py', Colors.green),
                  const SizedBox(height: SpacingTokens.sm),
                  _TypewriterText('Processing...', Colors.white),
                  const SizedBox(height: SpacingTokens.sm),
                  _TypewriterText('Processing...', Colors.white),
                  const SizedBox(height: SpacingTokens.sm),
                  _TypewriterText('Error: Task failed', Colors.red),
                  const SizedBox(height: SpacingTokens.md),
                  _TypewriterText('\$ # Where did it fail? Why? How confident was it?', Colors.grey),
                  const SizedBox(height: SpacingTokens.sm),
                  _TypewriterText('\$ # No idea. 🤷‍♀️', Colors.grey),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: SpacingTokens.xl),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: colors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.error.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'Common Development Challenges:',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SpacingTokens.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('40%', 'AI Projects Fail', colors),
                    _buildStatCard('\$2M+', 'Avg Debugging Cost', colors),
                    _buildStatCard('3 weeks', 'Time to Fix Failures', colors),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo: Real-Time AI Analysis',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Let\'s analyze a startup pitch deck and watch the AI reasoning process in real-time.',
            style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          Expanded(
            child: SimulatedDocumentProcessor(
              onProcessingComplete: (result) {
                setState(() {
                  _processingResult = result;
                  // Don't auto-advance - user must click Next
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIReasoning(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: colors.primary, size: 28),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Text(
                  'AI Reasoning in Progress',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  'Document: ${_processingResult?.fileName ?? "TechnoVate_Pitch_Deck.pdf"}',
                  style: TextStyles.bodyMedium.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          Expanded(
            child: SimulatedAIReasoning(
              documentType: 'pitch_deck',
              onConfidenceUpdate: (tree) {
                setState(() {
                  _currentConfidenceTree = tree;
                });
              },
              onInterventionTriggered: (intervention) {
                setState(() {
                  _showingIntervention = true;
                  _currentStage = DemoStage.uncertaintyIntervention;
                });
              },
              onReasoningComplete: (result) {
                // Don't auto-advance - user controls demo progression
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUncertaintyIntervention(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 32),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CRITICAL UNCERTAINTY DETECTED',
                        style: TextStyles.cardTitle.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'AI has paused execution due to low confidence (23%)',
                        style: TextStyles.bodyMedium.copyWith(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          Text(
            'Uncertainty Detection Triggered',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'The AI detected conflicting market size data and automatically paused to request human guidance due to low confidence.',
            style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          Expanded(
            child: Row(
              children: [
                // Left: Confidence Tree
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confidence Breakdown',
                        style: TextStyles.bodyLarge.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.md),
                      if (_currentConfidenceTree != null)
                        Expanded(
                          child: ConfidenceMicroscopyWidget(
                            confidenceTree: _currentConfidenceTree!,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: SpacingTokens.xl),
                
                // Right: Intervention Details
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uncertainty Details',
                          style: TextStyles.bodyLarge.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.lg),
                        _buildUncertaintyDetail('Issue', 'Market sizing conflict', colors),
                        _buildUncertaintyDetail('Company Claim', '\$47B TAM', colors),
                        _buildUncertaintyDetail('Industry Report', '\$12B TAM', colors),
                        _buildUncertaintyDetail('Variance', '292% difference', colors),
                        _buildUncertaintyDetail('Confidence', '23% (Critical)', colors),
                        const SizedBox(height: SpacingTokens.lg),
                        Text(
                          'AI Decision:',
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        Container(
                          padding: const EdgeInsets.all(SpacingTokens.md),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                          ),
                          child: Text(
                            '"This variance is too high for reliable investment analysis. Human judgment required."',
                            style: TextStyles.bodyMedium.copyWith(
                              color: colors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumanCollaboration(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Human-AI Collaboration',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'The AI has automatically spawned a human consultation workflow.',
            style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colors.primary,
                        child: Icon(Icons.psychology, color: Colors.white),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                      Text(
                        'AI Agent Request',
                        style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    ),
                    child: Text(
                      'I found conflicting market size data for TechnoVate AI:\n\n'
                      '• Company claims: \$47B TAM (Gartner 2024)\n'
                      '• Industry report: \$12B TAM (McKinsey 2024)\n\n'
                      'For investment analysis, which source should I trust? '
                      'The variance is 292%, which exceeds my confidence threshold.',
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                    ),
                  ),
                  
                  const SizedBox(height: SpacingTokens.xl),
                  
                  Text(
                    'Human Response Options:',
                    style: TextStyles.bodyLarge.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  
                  Row(
                    children: [
                      Expanded(
                        child: AsmblButton.primary(
                          text: 'Use Conservative (\$12B)',
                          onPressed: () => _handleHumanResponse('conservative'),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                      Expanded(
                        child: AsmblButton.secondary(
                          text: 'Use Optimistic (\$47B)',
                          onPressed: () => _handleHumanResponse('optimistic'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  AsmblButton.outline(
                    text: 'Request Additional Analysis',
                    onPressed: () => _handleHumanResponse('additional'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolution(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNCERTAINTY RESOLVED',
                        style: TextStyles.cardTitle.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Human input integrated - analysis resuming with high confidence',
                        style: TextStyles.bodyMedium.copyWith(color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          Text(
            'Resolution: ${_getResolutionText()}',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Watch how the AI\'s confidence updates with human guidance:',
            style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Updated Confidence Analysis',
                    style: TextStyles.bodyLarge.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  
                  _buildConfidenceComparison('Market Analysis', 0.23, 0.91, colors),
                  _buildConfidenceComparison('Investment Recommendation', 0.42, 0.87, colors),
                  _buildConfidenceComparison('Overall Analysis', 0.35, 0.89, colors),
                  
                  const SizedBox(height: SpacingTokens.xl),
                  
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Final Investment Recommendation:',
                          style: TextStyles.bodyLarge.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.md),
                        Text(
                          '✅ Investment analysis complete with 89% confidence\n'
                          '✅ Conservative market sizing approach validated\n'
                          '✅ Human expertise successfully integrated\n'
                          '✅ Full reasoning trail documented for audit',
                          style: TextStyles.bodyMedium.copyWith(color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConclusion(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility,
            size: 80,
            color: colors.primary,
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text(
            'Demo Complete',
            style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'This demonstration shows visual AI reasoning transparency and confidence monitoring capabilities.',
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurface,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          Container(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              border: Border.all(color: colors.primary, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'Demonstrated Features:',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SpacingTokens.lg),
                ...[
                  'AI reasoning process in real-time',
                  'Granular confidence monitoring',
                  'Automatic uncertainty detection',
                  'Intelligent human intervention',
                  'Collaborative AI problem-solving',
                  'Complete reasoning transparency',
                ].map((achievement) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                      const SizedBox(width: SpacingTokens.md),
                      Expanded(
                        child: Text(
                          achievement,
                          style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: SpacingTokens.xl),
          
          Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'This transforms AI from a black box into a glass box.\n\n'
              'Real-time confidence monitoring enables better human-AI collaboration.\n\n'
              'Uncertainty detection helps identify when human input is needed.',
              style: TextStyles.bodyLarge.copyWith(
                color: colors.onSurface,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoControls(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.95),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStage.index > 0)
            AsmblButton.secondary(
              text: 'Previous',
              onPressed: _previousStage,
            )
          else
            const SizedBox.shrink(),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Text(
              'Stage ${_currentStage.index + 1} of ${DemoStage.values.length}',
              style: TextStyles.bodyMedium.copyWith(color: colors.primary),
            ),
          ),
          
          if (_currentStage.index < DemoStage.values.length - 1)
            AsmblButton.primary(
              text: _getNextButtonText(),
              onPressed: _nextStage,
            )
          else
            AsmblButton.primary(
              text: 'Restart Demo',
              onPressed: _restartDemo,
            ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _TypewriterText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontFamily: 'Courier',
      ),
    );
  }

  Widget _buildStatCard(String value, String label, ThemeColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyles.pageTitle.copyWith(
            color: colors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUncertaintyDetail(String label, String value, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceComparison(String label, double before, double after, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Before:', style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade300,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: before,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    Text('${(before * 100).toInt()}%', style: TextStyles.bodySmall.copyWith(color: Colors.red)),
                  ],
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Icon(Icons.arrow_forward, color: colors.primary, size: 20),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('After:', style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade300,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: after,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    Text('${(after * 100).toInt()}%', style: TextStyles.bodySmall.copyWith(color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getStageDescription() {
    switch (_currentStage) {
      case DemoStage.introduction:
        return 'Welcome to the world\'s first visual AI reasoning system';
      case DemoStage.problemStatement:
        return 'Understanding the current AI development challenges';
      case DemoStage.documentUpload:
        return 'Real-time document processing and analysis';
      case DemoStage.aiReasoning:
        return 'Watching AI think with complete transparency';
      case DemoStage.uncertaintyIntervention:
        return 'Automatic uncertainty detection and intervention';
      case DemoStage.humanCollaboration:
        return 'Seamless human-AI collaboration workflow';
      case DemoStage.resolution:
        return 'Confidence recovery through human guidance';
      case DemoStage.conclusion:
        return 'The future of transparent AI reasoning';
    }
  }

  String _getNextButtonText() {
    switch (_currentStage) {
      case DemoStage.introduction:
        return 'Show the Problem';
      case DemoStage.problemStatement:
        return 'Start Demo';
      case DemoStage.documentUpload:
        return 'Begin Analysis';
      case DemoStage.aiReasoning:
        return 'Continue';
      case DemoStage.uncertaintyIntervention:
        return 'Show Collaboration';
      case DemoStage.humanCollaboration:
        return 'Resolve Uncertainty';
      case DemoStage.resolution:
        return 'See Conclusion';
      case DemoStage.conclusion:
        return 'Restart';
    }
  }

  String _getResolutionText() {
    switch (_humanResponse) {
      case 'conservative':
        return 'Conservative Market Sizing Approach';
      case 'optimistic':
        return 'Optimistic Market Sizing Approach';
      case 'additional':
        return 'Additional Analysis Requested';
      default:
        return 'Human Guidance Integrated';
    }
  }

  void _nextStage() {
    if (_currentStage.index < DemoStage.values.length - 1) {
      setState(() {
        _currentStage = DemoStage.values[_currentStage.index + 1];
      });
    }
  }

  void _previousStage() {
    if (_currentStage.index > 0) {
      setState(() {
        _currentStage = DemoStage.values[_currentStage.index - 1];
      });
    }
  }

  void _restartDemo() {
    setState(() {
      _currentStage = DemoStage.introduction;
      _processingResult = null;
      _currentConfidenceTree = null;
      _showingIntervention = false;
      _humanResponse = null;
    });
  }

  void _handleHumanResponse(String response) {
    setState(() {
      _humanResponse = response;
      _currentStage = DemoStage.resolution;
    });
  }
}

enum DemoStage {
  introduction,
  problemStatement,
  documentUpload,
  aiReasoning,
  uncertaintyIntervention,
  humanCollaboration,
  resolution,
  conclusion,
}