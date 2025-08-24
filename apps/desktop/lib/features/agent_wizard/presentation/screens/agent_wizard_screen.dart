import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../widgets/wizard_step_indicator.dart';
import '../widgets/agent_basics_step.dart';
import '../widgets/intelligence_config_step.dart';
import '../widgets/mcp_selection_step.dart';
import '../widgets/advanced_config_step.dart';
import '../widgets/deploy_test_step.dart';
import '../../models/agent_wizard_state.dart';

/// Comprehensive agent deployment wizard
/// Guides users through creating custom agents from scratch
class AgentWizardScreen extends ConsumerStatefulWidget {
  const AgentWizardScreen({super.key});

  @override
  ConsumerState<AgentWizardScreen> createState() => _AgentWizardScreenState();
}

class _AgentWizardScreenState extends ConsumerState<AgentWizardScreen> {
  final PageController _pageController = PageController();
  final AgentWizardState _wizardState = AgentWizardState();
  
  int _currentStep = 0;
  final int _totalSteps = 5;
  
  bool _isNavigating = false;
  bool _isDeploying = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              ThemeColors(context).backgroundGradientStart,
              ThemeColors(context).backgroundGradientMiddle,
              ThemeColors(context).backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress and navigation
              _buildHeader(context, theme),
              
              // Main wizard content
              Expanded(
                child: _buildWizardContent(context),
              ),
              
              // Navigation controls
              _buildNavigationControls(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: ThemeColors(context).headerBackground,
        border: Border(
          bottom: BorderSide(
            color: ThemeColors(context).headerBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Top navigation
          Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onSurface,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                ),
              ),
              
              SizedBox(width: SpacingTokens.md),
              
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Agent',
                      style: TextStyles.pageTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Build a custom agent with guided configuration',
                      style: TextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Advanced Editor Button
              AsmblButton.secondary(
                text: 'Advanced Editor',
                icon: Icons.settings,
                onPressed: _openAdvancedEditor,
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          // Progress indicator
          WizardStepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            stepTitles: const [
              'Agent Basics',
              'Intelligence',
              'MCP Servers',
              'Advanced',
              'Deploy & Test',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWizardContent(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentStep = index;
        });
      },
      children: [
        // Step 1: Agent Basics
        AgentBasicsStep(
          wizardState: _wizardState,
          onChanged: () => setState(() {}),
        ),
        
        // Step 2: Intelligence Configuration
        IntelligenceConfigStep(
          wizardState: _wizardState,
          onChanged: () => setState(() {}),
        ),
        
        // Step 3: MCP Server Selection
        MCPSelectionStep(
          wizardState: _wizardState,
          onChanged: () => setState(() {}),
        ),
        
        // Step 4: Advanced Configuration
        AdvancedConfigStep(
          wizardState: _wizardState,
          onChanged: () => setState(() {}),
        ),
        
        // Step 5: Deploy & Test
        DeployTestStep(
          wizardState: _wizardState,
          onDeploy: _deployAgent,
          isDeploying: _isDeploying,
        ),
      ],
    );
  }

  Widget _buildNavigationControls(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (_currentStep > 0)
            AsmblButton.secondary(
              text: 'Previous',
              icon: Icons.arrow_back,
              onPressed: _isNavigating ? null : _goToPreviousStep,
            )
          else
            const SizedBox(width: 120), // Spacer to maintain layout
          
          Spacer(),
          
          // Step info
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: TextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          
          Spacer(),
          
          // Next/Deploy button
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canProceed = _canProceedFromCurrentStep();
    
    if (isLastStep) {
      return AsmblButton.primary(
        text: _isDeploying ? 'Deploying...' : 'Deploy Agent',
        icon: _isDeploying ? null : Icons.rocket_launch,
        onPressed: _isDeploying || !canProceed ? null : _deployAgent,
      );
    } else {
      return AsmblButton.primary(
        text: 'Next',
        icon: Icons.arrow_forward,
        onPressed: _isNavigating || !canProceed ? null : _goToNextStep,
      );
    }
  }

  bool _canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0: // Agent Basics
        return _wizardState.agentName.isNotEmpty && 
               _wizardState.agentDescription.isNotEmpty;
      case 1: // Intelligence Configuration
        return _wizardState.systemPrompt.isNotEmpty &&
               _wizardState.selectedApiProvider.isNotEmpty;
      case 2: // MCP Server Selection
        return true; // MCP servers are optional
      case 3: // Advanced Configuration
        return true; // Advanced settings are optional
      case 4: // Deploy & Test
        return !_isDeploying;
      default:
        return false;
    }
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1 && _canProceedFromCurrentStep()) {
      setState(() {
        _isNavigating = true;
      });
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        setState(() {
          _isNavigating = false;
        });
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _isNavigating = true;
      });
      
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        setState(() {
          _isNavigating = false;
        });
      });
    }
  }

  Future<void> _deployAgent() async {
    setState(() {
      _isDeploying = true;
    });

    try {
      // Validate all wizard state
      if (!_wizardState.isValid()) {
        throw Exception('Agent configuration is incomplete');
      }

      // Create agent configuration
      final agentConfig = await _wizardState.buildAgentConfig();
      
      // Save agent to settings/storage
      // This would integrate with your agent storage system
      await _saveAgentConfiguration(agentConfig);
      
      // Show success and navigate to chat
      _showDeploymentSuccess();
      
    } catch (e) {
      _showDeploymentError(e.toString());
    } finally {
      setState(() {
        _isDeploying = false;
      });
    }
  }

  Future<void> _saveAgentConfiguration(Map<String, dynamic> config) async {
    // Simulate saving - integrate with your storage system
    await Future.delayed(const Duration(seconds: 2));
    
    // This would typically save to:
    // - Agent configuration storage
    // - Update conversation provider
    // - Register with MCP settings service
    print('Saving agent configuration: $config');
  }

  void _showDeploymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: ThemeColors(context).success,
          size: 48,
        ),
        title: Text(
          'Agent Deployed Successfully!',
          style: TextStyles.cardTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your agent "${_wizardState.agentName}" has been created and is ready to use.',
              style: TextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SpacingTokens.lg),
            Text(
              'You can now start a conversation or continue editing in the advanced editor.',
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          AsmblButton.secondary(
            text: 'Edit Agent',
            onPressed: () {
              Navigator.of(context).pop();
              _openAdvancedEditor();
            },
          ),
          AsmblButton.primary(
            text: 'Start Conversation',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed(AppRoutes.chat);
            },
          ),
        ],
      ),
    );
  }

  void _showDeploymentError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error,
          color: ThemeColors(context).error,
          size: 48,
        ),
        title: Text(
          'Deployment Failed',
          style: TextStyles.cardTitle,
        ),
        content: Text(
          'Failed to deploy agent: $error',
          style: TextStyles.bodyMedium,
        ),
        actions: [
          AsmblButton.primary(
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _openAdvancedEditor() {
    // Navigate to advanced agent editor with current wizard state
    // This would open the detailed configuration screen
    Navigator.of(context).pushNamed(
      '/agent-editor',
      arguments: _wizardState.toAgentConfig(),
    );
  }
}