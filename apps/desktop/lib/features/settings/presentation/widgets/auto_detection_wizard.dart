import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/universal_detection_service.dart';

// Import the IntegrationStatus and related types
typedef IntegrationDetection = Map<String, dynamic>;

class AutoDetectionWizard extends ConsumerStatefulWidget {
  final String? specificIntegration;
  final VoidCallback? onComplete;

  const AutoDetectionWizard({
    super.key,
    this.specificIntegration,
    this.onComplete,
  });

  @override
  ConsumerState<AutoDetectionWizard> createState() => _AutoDetectionWizardState();
}

class _AutoDetectionWizardState extends ConsumerState<AutoDetectionWizard> {
  bool _isDetecting = false;
  UniversalDetectionResult? _detectionResult;
  String _currentStep = 'ready';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        decoration: BoxDecoration(
          color: SemanticColors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          border: Border.all(color: SemanticColors.border),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.headerPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SemanticColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_fix_high,
            color: SemanticColors.primary,
            size: 24,
          ),
          const SizedBox(width: SpacingTokens.md),
          Text(
            widget.specificIntegration != null
                ? 'Auto-Detect ${widget.specificIntegration}'
                : 'Auto-Detect All Integrations',
            style: TextStyles.pageTitle,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: SemanticColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_currentStep == 'ready') {
      return _buildReadyStep();
    } else if (_currentStep == 'detecting') {
      return _buildDetectingStep();
    } else {
      return _buildResultsStep();
    }
  }

  Widget _buildReadyStep() {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.xxl),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            ),
            child: const Icon(
              Icons.search,
              size: 64,
              color: SemanticColors.primary,
            ),
          ),
          const SizedBox(height: SpacingTokens.xxl),
          Text(
            'Automatic Integration Detection',
            style: TextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            widget.specificIntegration != null
                ? 'We\'ll automatically detect and configure ${widget.specificIntegration} on your system.'
                : 'We\'ll scan your system for installed tools and services, then automatically configure the ones we find.',
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.xxl),
          _buildDetectionPreview(),
        ],
      ),
    );
  }

  Widget _buildDetectionPreview() {
    final categories = widget.specificIntegration != null
        ? [widget.specificIntegration!]
        : [
            'Development Tools',
            'Browsers',
            'Cloud Services',
            'Databases',
            'Communication',
            'Design Tools',
            'Productivity',
            'AI/ML Services',
            'File Storage',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SemanticColors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: SemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Categories:',
            style: TextStyles.labelMedium,
          ),
          const SizedBox(height: SpacingTokens.sm),
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: categories.map((category) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: SemanticColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Text(
                category,
                style: TextStyles.labelMedium.copyWith(
                  color: SemanticColors.primary,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectingStep() {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(SemanticColors.primary),
            ),
          ),
          const SizedBox(height: SpacingTokens.xxl),
          Text(
            'Scanning System...',
            style: TextStyles.headlineMedium,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Detecting installed tools and services',
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.xxl),
          const LinearProgressIndicator(
            backgroundColor: SemanticColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(SemanticColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    if (_detectionResult == null) return const SizedBox();

    // Simplified for demo - extract from detection result
    final foundIntegrations = <IntegrationInstance>[
      const IntegrationInstance(
        name: 'VS Code',
        status: IntegrationStatus.ready,
        path: 'C:\\Users\\Mike\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe',
        confidence: 95,
      ),
      const IntegrationInstance(
        name: 'Git',
        status: IntegrationStatus.ready,
        path: 'git',
        confidence: 90,
      ),
    ];
    final needsSetupIntegrations = <IntegrationInstance>[
      const IntegrationInstance(
        name: 'GitHub CLI',
        status: IntegrationStatus.needsAuth,
        confidence: 70,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary stats
          Container(
            margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Ready to Use', foundIntegrations.length, Icons.check_circle),
                _buildStatCard('Needs Setup', needsSetupIntegrations.length, Icons.settings),
                _buildStatCard('Confidence', '85%', Icons.psychology),
              ],
            ),
          ),
          
          // Results list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (foundIntegrations.isNotEmpty) ...[
                    _buildResultSection('Ready to Use', foundIntegrations, Icons.check_circle, Colors.green),
                    const SizedBox(height: SpacingTokens.lg),
                  ],
                  if (needsSetupIntegrations.isNotEmpty) ...[
                    _buildResultSection('Needs Configuration', needsSetupIntegrations, Icons.settings, Colors.orange),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: SemanticColors.primary, size: 28),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          value.toString(),
          style: TextStyles.headlineSmall.copyWith(
            color: SemanticColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyles.labelMedium.copyWith(
            color: SemanticColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(String title, List<IntegrationDetection> integrations, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: SpacingTokens.sm),
            Text(title, style: TextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: SpacingTokens.md),
        ...integrations.map((integration) => _buildIntegrationCard(integration)),
      ],
    );
  }

  Widget _buildIntegrationCard(IntegrationDetection integration) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: SemanticColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: SemanticColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(integration.status),
              borderRadius: BorderRadiusTokens.sm,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(integration.name, style: TextStyles.titleSmall),
                if (integration.path != null)
                  Text(
                    integration.path!,
                    style: TextStyles.bodySmall.copyWith(
                      color: SemanticColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (integration.status == IntegrationStatus.ready)
            AsmblButton.secondary(
              text: 'Configure',
              onPressed: () => _configureIntegration(integration),
            )
          else
            AsmblButton.primary(
              text: 'Setup',
              onPressed: () => _setupIntegration(integration),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(IntegrationStatus status) {
    switch (status) {
      case IntegrationStatus.ready:
        return Colors.green;
      case IntegrationStatus.needsAuth:
      case IntegrationStatus.needsStart:
        return Colors.orange;
      case IntegrationStatus.notFound:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SemanticColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentStep == 'ready') ...[
            AsmblButton.secondary(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: SpacingTokens.md),
            AsmblButton.primary(
              text: 'Start Detection',
              onPressed: _startDetection,
            ),
          ] else if (_currentStep == 'results') ...[
            AsmblButton.secondary(
              text: 'Detect Again',
              onPressed: () => setState(() {
                _currentStep = 'ready';
                _detectionResult = null;
              }),
            ),
            const SizedBox(width: SpacingTokens.md),
            AsmblButton.primary(
              text: 'Complete',
              onPressed: () {
                widget.onComplete?.call();
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startDetection() async {
    setState(() {
      _isDetecting = true;
      _currentStep = 'detecting';
    });

    try {
      final universalService = ref.read(universalDetectionServiceProvider);
      
      if (widget.specificIntegration != null) {
        // Detect specific integration
        _detectionResult = await universalService.detectSpecificIntegration(widget.specificIntegration!);
      } else {
        // Detect everything
        _detectionResult = await universalService.detectEverything();
      }
      
      setState(() {
        _currentStep = 'results';
      });
    } catch (e) {
      // Handle error
      setState(() {
        _currentStep = 'ready';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  void _configureIntegration(IntegrationDetection integration) {
    // Navigate to integration configuration
    Navigator.of(context).pop();
    // TODO: Navigate to specific integration config screen
  }

  void _setupIntegration(IntegrationDetection integration) {
    // Navigate to integration setup
    Navigator.of(context).pop();
    // TODO: Navigate to integration setup screen
  }
}