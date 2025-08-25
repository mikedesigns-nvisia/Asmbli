import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../providers/agent_provider.dart';
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

  void _onWizardStateChanged() {
    setState(() {
      // Rebuild UI when wizard state changes
    });
  }

  @override
  void initState() {
    super.initState();
    // Listen to wizard state changes to trigger UI updates
    _wizardState.addListener(_onWizardStateChanged);
  }

  @override
  void dispose() {
    _wizardState.removeListener(_onWizardStateChanged);
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
              // Simple header with back button only
              _buildSimpleHeader(context),
              
              // Main wizard content - Typeform style
              Expanded(
                child: _buildWizardContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.xxl,
        vertical: SpacingTokens.lg,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.go(AppRoutes.home),
            icon: Icon(
              Icons.arrow_back,
              color: ThemeColors(context).onSurface,
            ),
            style: IconButton.styleFrom(
              backgroundColor: ThemeColors(context).surface.withValues(alpha: 0.8),
              padding: EdgeInsets.all(SpacingTokens.md),
            ),
          ),
          
          SizedBox(width: SpacingTokens.lg),
          
          // Title
          Text(
            'Create New Agent',
            style: TextStyles.pageTitle.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
          
          Spacer(),
          
          // Advanced Editor Button (optional)
          TextButton.icon(
            onPressed: _openAdvancedEditor,
            icon: Icon(
              Icons.settings,
              size: 16,
              color: ThemeColors(context).onSurfaceVariant,
            ),
            label: Text(
              'Advanced Editor',
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).onSurfaceVariant,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
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
                onPressed: () => context.go(AppRoutes.home),
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
    return Container(
      height: double.infinity,
      width: double.infinity,
      child: Column(
        children: [
          // Typeform-style progress indicator
          _buildTypeformProgress(context),
          
          // Main content area - single focused widget
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: SpacingTokens.xxl * 2,
                vertical: SpacingTokens.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 800, // Centered content with max width
                  ),
                  child: _buildTypeformStep(context),
                ),
              ),
            ),
          ),
          
          // Bottom navigation
          _buildTypeformNavigation(context),
        ],
      ),
    );
  }

  Widget _buildTypeformProgress(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;
    
    return Container(
      height: 4,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: ThemeColors(context).surfaceVariant,
        valueColor: AlwaysStoppedAnimation<Color>(
          ThemeColors(context).primary,
        ),
      ),
    );
  }

  Widget _buildTypeformStep(BuildContext context) {
    final stepWidgets = [
      _buildAgentBasicsTypeform(context),
      _buildIntelligenceTypeform(context), 
      _buildMCPServersTypeform(context),
      _buildAdvancedTypeform(context),
      _buildDeployTypeform(context),
    ];
    
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: child,
        );
      },
      child: Container(
        key: ValueKey(_currentStep),
        child: stepWidgets[_currentStep],
      ),
    );
  }

  Widget _buildTypeformNavigation(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SpacingTokens.xxl),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface,
        border: Border(
          top: BorderSide(
            color: ThemeColors(context).border.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentStep > 0)
            AsmblButton.secondary(
              text: 'Back',
              icon: Icons.arrow_back,
              onPressed: _goToPreviousStep,
            )
          else
            SizedBox(width: 100), // Maintain spacing
            
          // Step indicator
          Text(
            '${_currentStep + 1} of $_totalSteps',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          // Next/Continue button
          _buildTypeformNextButton(),
        ],
      ),
    );
  }

  Widget _buildTypeformNextButton() {
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
        text: 'Continue',
        icon: Icons.arrow_forward,
        onPressed: _isNavigating || !canProceed ? null : _goToNextStep,
      );
    }
  }

  // Typeform-style step widgets
  Widget _buildAgentBasicsTypeform(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Let\'s start with the basics 👋',
          style: TextStyles.pageTitle.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SpacingTokens.md),
        Text(
          'Give your agent a name and describe what it does',
          style: TextStyles.bodyLarge.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        SizedBox(height: SpacingTokens.xxl),
        
        // Agent Name Field
        _buildTypeformField(
          label: 'What should we call your agent?',
          hintText: 'e.g., Research Assistant, Code Helper, Data Analyst',
          initialValue: _wizardState.agentName,
          onChanged: (value) {
            _wizardState.setAgentName(value);
          },
          icon: Icons.smart_toy,
        ),
        
        SizedBox(height: SpacingTokens.xl),
        
        // Agent Description Field  
        _buildTypeformField(
          label: 'How would you describe your agent?',
          hintText: 'e.g., Helps with research tasks and data analysis',
          initialValue: _wizardState.agentDescription,
          onChanged: (value) {
            _wizardState.setAgentDescription(value);
          },
          maxLines: 3,
          icon: Icons.description,
        ),
      ],
    );
  }

  Widget _buildIntelligenceTypeform(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Choose your AI model 🧠',
          style: TextStyles.pageTitle.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SpacingTokens.md),
        Text(
          'Select the AI model that will power your agent',
          style: TextStyles.bodyLarge.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        SizedBox(height: SpacingTokens.xxl),
        
        // Model selection cards
        Column(
          children: [
            _buildModelOption('OpenAI GPT-4', 'Most capable, best for complex tasks', Icons.psychology),
            SizedBox(height: SpacingTokens.lg),
            _buildModelOption('Claude 3.5 Sonnet', 'Excellent reasoning and coding', Icons.auto_awesome),
            SizedBox(height: SpacingTokens.lg), 
            _buildModelOption('Local Model', 'Run privately on your machine', Icons.computer),
          ],
        ),
      ],
    );
  }

  Widget _buildMCPServersTypeform(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Add superpowers 🚀',
          style: TextStyles.pageTitle.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SpacingTokens.md),
        Text(
          'MCP servers give your agent access to tools and data sources',
          style: TextStyles.bodyLarge.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        SizedBox(height: SpacingTokens.xxl),
        
        Text(
          'Popular integrations:',
          style: TextStyles.sectionTitle,
        ),
        SizedBox(height: SpacingTokens.lg),
        
        // Quick MCP server options
        Column(
          children: [
            _buildMCPOption('GitHub', 'Access repositories and issues', Icons.code),
            SizedBox(height: SpacingTokens.md),
            _buildMCPOption('File System', 'Read and write local files', Icons.folder),
            SizedBox(height: SpacingTokens.md),
            _buildMCPOption('Web Search', 'Search the internet', Icons.search),
            SizedBox(height: SpacingTokens.md),
            _buildMCPOption('Database', 'Connect to PostgreSQL/SQLite', Icons.storage),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedTypeform(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Environment setup 🔧',
          style: TextStyles.pageTitle.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SpacingTokens.md),
        Text(
          'Configure API keys and environment variables',
          style: TextStyles.bodyLarge.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        SizedBox(height: SpacingTokens.xxl),
        
        // Environment variables count
        Container(
          padding: EdgeInsets.all(SpacingTokens.lg),
          decoration: BoxDecoration(
            color: ThemeColors(context).primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(
              color: ThemeColors(context).primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
                child: Icon(
                  Icons.key,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: SpacingTokens.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_wizardState.environmentVariables.length} environment variables configured',
                      style: TextStyles.cardTitle,
                    ),
                    Text(
                      _wizardState.environmentVariables.isEmpty 
                          ? 'Your agent will work without API keys, but some features may be limited'
                          : 'Your agent has access to: ${_wizardState.environmentVariables.keys.join(', ')}',
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AsmblButton.secondary(
                text: 'Configure',
                icon: Icons.settings,
                onPressed: () {
                  // Open environment variable configuration
                  _showEnvironmentVariableDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeployTypeform(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Ready to deploy! 🎉',
          style: TextStyles.pageTitle.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SpacingTokens.md),
        Text(
          'Review your agent configuration and deploy when ready',
          style: TextStyles.bodyLarge.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
        SizedBox(height: SpacingTokens.xxl),
        
        // Agent summary card
        AsmblCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: ThemeColors(context).primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: ThemeColors(context).primary,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: SpacingTokens.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _wizardState.agentName.isNotEmpty ? _wizardState.agentName : 'My Agent',
                          style: TextStyles.cardTitle.copyWith(fontSize: 24),
                        ),
                        Text(
                          _wizardState.agentDescription.isNotEmpty 
                              ? _wizardState.agentDescription 
                              : 'No description provided',
                          style: TextStyles.bodyMedium.copyWith(
                            color: ThemeColors(context).onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: SpacingTokens.lg),
              
              // Configuration summary
              _buildSummaryRow('AI Model', _wizardState.selectedApiProvider.isNotEmpty ? _wizardState.selectedApiProvider : 'Not selected'),
              _buildSummaryRow('Environment Variables', '${_wizardState.environmentVariables.length} configured'),
              _buildSummaryRow('MCP Servers', '${_wizardState.selectedMCPServers.length} selected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current step info
        _buildCurrentStepInfo(context),
        
        SizedBox(height: SpacingTokens.xxl),
        
        // Step overview
        _buildStepOverview(context),
        
        SizedBox(height: SpacingTokens.xxl),
        
        // Progress summary
        _buildProgressSummary(context),
      ],
    );
  }
  
  Widget _buildRightColumn(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5,
        maxHeight: screenHeight * 0.8,
      ),
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
          });
        },
        children: [
          // Step 1: Agent Basics
          SingleChildScrollView(
            child: AgentBasicsStep(
              wizardState: _wizardState,
              onChanged: () => setState(() {}),
            ),
          ),
          
          // Step 2: Intelligence Configuration
          SingleChildScrollView(
            child: IntelligenceConfigStep(
              wizardState: _wizardState,
              onChanged: () => setState(() {}),
            ),
          ),
          
          // Step 3: MCP Server Selection
          SingleChildScrollView(
            child: MCPSelectionStep(
              wizardState: _wizardState,
              onChanged: () => setState(() {}),
            ),
          ),
          
          // Step 4: Advanced Configuration
          SingleChildScrollView(
            child: AdvancedConfigStep(
              wizardState: _wizardState,
              onChanged: () => setState(() {}),
            ),
          ),
          
          // Step 5: Deploy & Test
          SingleChildScrollView(
            child: DeployTestStep(
              wizardState: _wizardState,
              onDeploy: _deployAgent,
              isDeploying: _isDeploying,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactProgress(BuildContext context) {
    final stepTitles = [
      'Basics',
      'Intelligence',
      'MCP Servers',
      'Advanced',
      'Deploy',
    ];
    
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current step indicator
          Row(
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyles.cardTitle,
              ),
              Spacer(),
              Text(
                stepTitles[_currentStep],
                style: TextStyles.bodyMedium.copyWith(
                  color: ThemeColors(context).primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: ThemeColors(context).surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentStep + 1) / _totalSteps,
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          SizedBox(height: SpacingTokens.md),
          
          // Step dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? SemanticColors.success
                      : isCurrent
                          ? ThemeColors(context).primary
                          : ThemeColors(context).surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        size: 8,
                        color: Colors.white,
                      )
                    : null,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepInfo(BuildContext context) {
    final stepTitles = [
      'Agent Basics',
      'Intelligence',
      'MCP Servers',
      'Advanced',
      'Deploy & Test',
    ];
    
    final stepDescriptions = [
      'Set up your agent\'s identity and core configuration',
      'Configure AI model and intelligence settings',
      'Select and configure MCP servers for enhanced capabilities',
      'Fine-tune environment variables and advanced settings',
      'Review, test, and deploy your custom agent',
    ];
    
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${_currentStep + 1}',
                    style: TextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Text(
                  stepTitles[_currentStep],
                  style: TextStyles.cardTitle,
                ),
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.md),
          
          Text(
            stepDescriptions[_currentStep],
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepOverview(BuildContext context) {
    final stepTitles = [
      'Agent Basics',
      'Intelligence',
      'MCP Servers', 
      'Advanced',
      'Deploy & Test',
    ];
    
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Setup Progress',
            style: TextStyles.cardTitle,
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          ...List.generate(stepTitles.length, (index) {
            final isCompleted = index < _currentStep;
            final isCurrent = index == _currentStep;
            final isPending = index > _currentStep;
            
            return Container(
              margin: EdgeInsets.only(bottom: SpacingTokens.sm),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? SemanticColors.success
                          : isCurrent
                              ? ThemeColors(context).primary
                              : ThemeColors(context).surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : isCurrent
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                )
                              : null,
                    ),
                  ),
                  
                  SizedBox(width: SpacingTokens.sm),
                  
                  Expanded(
                    child: Text(
                      stepTitles[index],
                      style: TextStyles.bodySmall.copyWith(
                        color: isCurrent
                            ? ThemeColors(context).onSurface
                            : ThemeColors(context).onSurfaceVariant,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Summary',
            style: TextStyles.cardTitle,
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          if (_wizardState.agentName.isNotEmpty) ...[
            _buildSummaryItem(context, 'Name', _wizardState.agentName),
            SizedBox(height: SpacingTokens.sm),
          ],
          
          if (_wizardState.selectedApiProvider.isNotEmpty) ...[
            _buildSummaryItem(context, 'AI Model', _wizardState.selectedApiProvider),
            SizedBox(height: SpacingTokens.sm),
          ],
          
          _buildSummaryItem(
            context, 
            'Environment Variables', 
            '${_wizardState.environmentVariables.length} configured'
          ),
          
          SizedBox(height: SpacingTokens.sm),
          
          _buildSummaryItem(
            context,
            'Progress',
            '${((_currentStep + 1) / _totalSteps * 100).round()}% complete',
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
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
        return _wizardState.agentName.isNotEmpty;
      case 1: // Intelligence Configuration  
        return _wizardState.selectedApiProvider.isNotEmpty;
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
        _currentStep++;
      });
      
      // Simulate animation delay
      Future.delayed(const Duration(milliseconds: 300), () {
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
        _currentStep--;
      });
      
      // Simulate animation delay
      Future.delayed(const Duration(milliseconds: 300), () {
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
    // Create agent instance from wizard configuration
    final agent = Agent(
      id: config['id'] as String,
      name: config['name'] as String,
      description: config['description'] as String,
      capabilities: List<String>.from(config['mcpServers'] ?? []),
      configuration: {
        'systemPrompt': config['systemPrompt'],
        'apiProvider': config['apiProvider'],
        'modelParameters': config['modelParameters'],
        'mcpServers': config['mcpServers'],
        'mcpServerConfigs': config['mcpServerConfigs'],
        'environmentVariables': config['environmentVariables'],
        'contextDocuments': config['contextDocuments'],
        'advancedSettings': config['advancedSettings'],
        'role': config['role'],
        'created': config['created'],
        'version': config['version'],
      },
      status: AgentStatus.idle,
    );
    
    // Save agent using the agent service
    final agentNotifier = ref.read(agentNotifierProvider.notifier);
    await agentNotifier.createAgent(agent);
    
    // Set as active agent
    agentNotifier.setActiveAgent(agent);
    
    print('Successfully saved agent: ${agent.name}');
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
              context.pop();
              _openAdvancedEditor();
            },
          ),
          AsmblButton.primary(
            text: 'Start Conversation',
            onPressed: () {
              context.pop();
              context.go(AppRoutes.chat);
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
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  void _openAdvancedEditor() {
    // Navigate to advanced agent editor with current wizard state
    // This would open the detailed configuration screen
    context.push('/agents/configure');
  }

  // Typeform UI helper methods
  Widget _buildTypeformField({
    required String label,
    required String hintText,
    required String initialValue,
    required Function(String) onChanged,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
            ],
            Text(
              label,
              style: TextStyles.sectionTitle.copyWith(
                fontSize: 18,
              ),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.md),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          maxLines: maxLines,
          style: TextStyles.bodyLarge.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyles.bodyLarge.copyWith(
              color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: ThemeColors(context).border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(color: ThemeColors(context).border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              borderSide: BorderSide(
                color: ThemeColors(context).primary,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.all(SpacingTokens.lg),
            filled: true,
            fillColor: ThemeColors(context).surface,
          ),
        ),
      ],
    );
  }

  Widget _buildModelOption(String name, String description, IconData icon) {
    final isSelected = _wizardState.selectedApiProvider == name;
    
    return GestureDetector(
      onTap: () {
        _wizardState.setSelectedApiProvider(name);
        // Set a basic system prompt if none exists
        if (_wizardState.systemPrompt.isEmpty) {
          _wizardState.setSystemPrompt('You are a helpful AI assistant.');
        }
        setState(() {});
      },
      child: Container(
        padding: EdgeInsets.all(SpacingTokens.lg),
        decoration: BoxDecoration(
          color: isSelected 
              ? ThemeColors(context).primary.withValues(alpha: 0.1)
              : ThemeColors(context).surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(
            color: isSelected 
                ? ThemeColors(context).primary
                : ThemeColors(context).border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: isSelected 
                    ? ThemeColors(context).primary
                    : ThemeColors(context).surfaceVariant,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? Colors.white
                    : ThemeColors(context).onSurfaceVariant,
                size: 24,
              ),
            ),
            SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyles.cardTitle.copyWith(
                      color: isSelected 
                          ? ThemeColors(context).primary
                          : ThemeColors(context).onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ThemeColors(context).primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCPOption(String name, String description, IconData icon) {
    final isEnabled = _wizardState.selectedMCPServers.contains(name);
    
    return GestureDetector(
      onTap: () {
        if (isEnabled) {
          _wizardState.removeMCPServer(name);
        } else {
          _wizardState.addMCPServer(name);
        }
        setState(() {});
      },
      child: Container(
        padding: EdgeInsets.all(SpacingTokens.lg),
        decoration: BoxDecoration(
          color: isEnabled 
              ? ThemeColors(context).primary.withValues(alpha: 0.1)
              : ThemeColors(context).surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(
            color: isEnabled 
                ? ThemeColors(context).primary
                : ThemeColors(context).border,
            width: isEnabled ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: isEnabled 
                    ? ThemeColors(context).primary
                    : ThemeColors(context).surfaceVariant,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              ),
              child: Icon(
                icon,
                color: isEnabled 
                    ? Colors.white
                    : ThemeColors(context).onSurfaceVariant,
                size: 20,
              ),
            ),
            SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEnabled 
                          ? ThemeColors(context).primary
                          : ThemeColors(context).onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: (value) {
                if (value) {
                  _wizardState.addMCPServer(name);
                } else {
                  _wizardState.removeMCPServer(name);
                }
                setState(() {});
              },
              activeColor: ThemeColors(context).primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyles.bodyMedium.copyWith(
                color: ThemeColors(context).onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnvironmentVariableDialog() {
    // This would show the improved environment variable dialog
    // For now, just show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Environment Variables'),
        content: Text('This would open the enhanced environment variable configuration screen we created earlier.'),
        actions: [
          AsmblButton.primary(
            text: 'OK',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}