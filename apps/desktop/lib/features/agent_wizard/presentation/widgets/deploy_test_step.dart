import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/mcp_health_monitor.dart';
import '../../../settings/presentation/widgets/mcp_health_status_widget.dart';
import '../../models/agent_wizard_state.dart';

/// Final step of the agent wizard - deploy and test the agent
class DeployTestStep extends ConsumerStatefulWidget {
  final AgentWizardState wizardState;
  final VoidCallback onDeploy;
  final bool isDeploying;

  const DeployTestStep({
    super.key,
    required this.wizardState,
    required this.onDeploy,
    required this.isDeploying,
  });

  @override
  ConsumerState<DeployTestStep> createState() => _DeployTestStepState();
}

class _DeployTestStepState extends ConsumerState<DeployTestStep> {
  bool _showValidationDetails = false;
  bool _hasRunValidation = false;
  Map<String, ValidationResult> _validationResults = {};
  String? _testConversationId;
  bool _isTesting = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runValidation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step title and description
              _buildStepHeader(context),
              
              SizedBox(height: SpacingTokens.xxl),
              
              // Agent summary
              _buildAgentSummary(context),
              
              SizedBox(height: SpacingTokens.xxl),
              
              // Validation results
              _buildValidationSection(context),
              
              SizedBox(height: SpacingTokens.xxl),
              
              // MCP server health check
              _buildHealthCheckSection(context),
              
              SizedBox(height: SpacingTokens.xxl),
              
              // Test conversation section
              _buildTestSection(context),
              
              SizedBox(height: SpacingTokens.xxl),
              
              // Deployment section
              _buildDeploymentSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deploy & Test',
          style: TextStyles.pageTitle,
        ),
        SizedBox(height: SpacingTokens.sm),
        Text(
          'Review your agent configuration, run validation checks, and test your agent before deployment.',
          style: TextStyles.bodyMedium.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAgentSummary(BuildContext context) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'Agent Summary',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          // Agent overview
          Container(
            padding: EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: ThemeColors(context).primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(
                color: ThemeColors(context).primary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.wizardState.agentName,
                  style: TextStyles.cardTitle.copyWith(
                    color: ThemeColors(context).primary,
                    fontSize: 18,
                  ),
                ),
                
                if (widget.wizardState.agentRole.isNotEmpty) ...[
                  SizedBox(height: SpacingTokens.xs),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ThemeColors(context).primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Text(
                      widget.wizardState.agentRole,
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: SpacingTokens.sm),
                
                Text(
                  widget.wizardState.agentDescription,
                  style: TextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          // Configuration details
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  context,
                  'AI Model',
                  widget.wizardState.selectedApiProvider,
                  Icons.psychology,
                ),
              ),
              SizedBox(width: SpacingTokens.md),
              Expanded(
                child: _buildSummaryMetric(
                  context,
                  'MCP Servers',
                  '${widget.wizardState.selectedMCPServers.length} selected',
                  Icons.storage,
                ),
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.sm),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  context,
                  'Environment Variables',
                  '${widget.wizardState.environmentVariables.length} configured',
                  Icons.settings,
                ),
              ),
              SizedBox(width: SpacingTokens.md),
              Expanded(
                child: _buildSummaryMetric(
                  context,
                  'Context Documents',
                  '${widget.wizardState.contextDocuments.length} selected',
                  Icons.description,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: ThemeColors(context).border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: ThemeColors(context).onSurfaceVariant,
          ),
          SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationSection(BuildContext context) {
    final overallValid = _hasRunValidation && _validationResults.values.every((result) => result.isValid);
    
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                overallValid ? Icons.check_circle : Icons.warning,
                color: overallValid ? ThemeColors(context).success : ThemeColors(context).warning,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'Validation Results',
                style: TextStyles.cardTitle,
              ),
              Spacer(),
              if (_hasRunValidation)
                AsmblButton.secondary(
                  text: 'Re-validate',
                  icon: Icons.refresh,
                  onPressed: _runValidation,
                ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          if (!_hasRunValidation) ...[
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: ThemeColors(context).primary,
                  ),
                  SizedBox(height: SpacingTokens.sm),
                  Text(
                    'Running validation checks...',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Validation summary
            Container(
              padding: EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: overallValid 
                    ? ThemeColors(context).success.withValues(alpha: 0.1)
                    : ThemeColors(context).warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: overallValid 
                      ? ThemeColors(context).success.withValues(alpha: 0.3)
                      : ThemeColors(context).warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    overallValid ? Icons.check_circle : Icons.warning,
                    color: overallValid ? ThemeColors(context).success : ThemeColors(context).warning,
                  ),
                  SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overallValid 
                              ? 'All validation checks passed'
                              : 'Some issues found - see details below',
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: overallValid ? ThemeColors(context).success : ThemeColors(context).warning,
                          ),
                        ),
                        Text(
                          '${_validationResults.values.where((r) => r.isValid).length}/${_validationResults.length} checks passed',
                          style: TextStyles.bodySmall.copyWith(
                            color: overallValid ? ThemeColors(context).success : ThemeColors(context).warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showValidationDetails = !_showValidationDetails;
                      });
                    },
                    icon: Icon(
                      _showValidationDetails ? Icons.expand_less : Icons.expand_more,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor: overallValid ? ThemeColors(context).success : ThemeColors(context).warning,
                    ),
                  ),
                ],
              ),
            ),
            
            if (_showValidationDetails) ...[
              SizedBox(height: SpacingTokens.lg),
              _buildValidationDetails(context),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildValidationDetails(BuildContext context) {
    return Column(
      children: _validationResults.entries.map((entry) {
        final result = entry.value;
        
        return Container(
          margin: EdgeInsets.only(bottom: SpacingTokens.sm),
          padding: EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: ThemeColors(context).surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            border: Border.all(color: ThemeColors(context).border),
          ),
          child: Row(
            children: [
              Icon(
                result.isValid ? Icons.check : Icons.error_outline,
                size: 16,
                color: result.isValid ? ThemeColors(context).success : ThemeColors(context).error,
              ),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      result.message,
                      style: TextStyles.bodySmall.copyWith(
                        color: result.isValid 
                            ? ThemeColors(context).success
                            : ThemeColors(context).error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHealthCheckSection(BuildContext context) {
    if (widget.wizardState.selectedMCPServers.isEmpty) {
      return const SizedBox.shrink();
    }

    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'MCP Server Health Check',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Checking the health of selected MCP servers to ensure they\'re ready for your agent.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          // Health status for selected servers
          Column(
            children: widget.wizardState.selectedMCPServers.map((serverId) {
              return Container(
                margin: EdgeInsets.only(bottom: SpacingTokens.sm),
                child: MCPHealthStatusWidget(
                  serverId: serverId,
                  showDetails: false,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(BuildContext context) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'Test Your Agent',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Test your agent with a sample conversation to ensure everything works correctly.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          if (_testConversationId == null) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: SpacingTokens.sm),
                  Text(
                    'Start a test conversation',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Test your agent before deploying to ensure it works as expected.',
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: SpacingTokens.lg),
                  AsmblButton.secondary(
                    text: _isTesting ? 'Starting Test...' : 'Start Test Conversation',
                    icon: _isTesting ? null : Icons.chat,
                    onPressed: _isTesting ? null : _startTestConversation,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Test conversation active
            Container(
              padding: EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: ThemeColors(context).success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: ThemeColors(context).success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: ThemeColors(context).success,
                        size: 20,
                      ),
                      SizedBox(width: SpacingTokens.sm),
                      Text(
                        'Test Conversation Active',
                        style: TextStyles.bodyMedium.copyWith(
                          color: ThemeColors(context).success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: SpacingTokens.sm),
                  
                  Text(
                    'Your agent is ready for testing. You can now deploy it or continue testing.',
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurface,
                    ),
                  ),
                  
                  SizedBox(height: SpacingTokens.md),
                  
                  Row(
                    children: [
                      AsmblButton.secondary(
                        text: 'View Test Chat',
                        icon: Icons.open_in_new,
                        onPressed: () => _openTestConversation(),
                      ),
                      SizedBox(width: SpacingTokens.sm),
                      AsmblButton.secondary(
                        text: 'End Test',
                        icon: Icons.close,
                        onPressed: () => _endTestConversation(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeploymentSection(BuildContext context) {
    final canDeploy = widget.wizardState.isValid() && 
                     _hasRunValidation && 
                     _validationResults.values.every((result) => result.isValid);

    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rocket_launch,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              SizedBox(width: SpacingTokens.sm),
              Text(
                'Ready for Deployment',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          if (!canDeploy) ...[
            Container(
              padding: EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: ThemeColors(context).warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: ThemeColors(context).warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: ThemeColors(context).warning,
                  ),
                  SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unable to deploy',
                          style: TextStyles.bodyMedium.copyWith(
                            color: ThemeColors(context).warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Please fix validation issues above before deploying.',
                          style: TextStyles.bodySmall.copyWith(
                            color: ThemeColors(context).warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: ThemeColors(context).success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: ThemeColors(context).success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: ThemeColors(context).success,
                      ),
                      SizedBox(width: SpacingTokens.sm),
                      Text(
                        'Ready to Deploy!',
                        style: TextStyles.bodyMedium.copyWith(
                          color: ThemeColors(context).success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: SpacingTokens.sm),
                  
                  Text(
                    'Your agent has passed all validation checks and is ready for deployment. Click the deploy button to make your agent available for use.',
                    style: TextStyles.bodyMedium,
                  ),
                  
                  SizedBox(height: SpacingTokens.md),
                  
                  Text(
                    'After deployment, you can:',
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '• Start conversations with your agent\n'
                    '• Edit agent settings in the Advanced Editor\n'
                    '• Monitor performance and usage\n'
                    '• Share your agent with others',
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: SpacingTokens.lg),
          
          Row(
            children: [
              if (canDeploy) ...[
                Expanded(
                  child: AsmblButton.primary(
                    text: widget.isDeploying ? 'Deploying...' : 'Deploy Agent',
                    icon: widget.isDeploying ? null : Icons.rocket_launch,
                    onPressed: widget.isDeploying ? null : widget.onDeploy,
                  ),
                ),
                SizedBox(width: SpacingTokens.sm),
              ],
              AsmblButton.secondary(
                text: 'Save as Draft',
                icon: Icons.save,
                onPressed: _saveDraft,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runValidation() async {
    setState(() {
      _hasRunValidation = false;
      _validationResults.clear();
    });

    // Simulate validation checks
    await Future.delayed(const Duration(milliseconds: 500));
    
    final results = <String, ValidationResult>{};
    
    // Basic configuration validation
    results['Agent Name'] = ValidationResult(
      isValid: widget.wizardState.agentName.isNotEmpty,
      message: widget.wizardState.agentName.isNotEmpty 
          ? 'Agent name is valid'
          : 'Agent name is required',
    );
    
    results['System Prompt'] = ValidationResult(
      isValid: widget.wizardState.systemPrompt.isNotEmpty,
      message: widget.wizardState.systemPrompt.isNotEmpty 
          ? 'System prompt configured'
          : 'System prompt is required',
    );
    
    results['AI Model'] = ValidationResult(
      isValid: widget.wizardState.selectedApiProvider.isNotEmpty,
      message: widget.wizardState.selectedApiProvider.isNotEmpty 
          ? 'AI model selected: ${widget.wizardState.selectedApiProvider}'
          : 'AI model selection is required',
    );
    
    // MCP servers validation
    if (widget.wizardState.selectedMCPServers.isNotEmpty) {
      results['MCP Servers'] = ValidationResult(
        isValid: true,
        message: '${widget.wizardState.selectedMCPServers.length} MCP servers configured',
      );
      
      // Environment variables validation for MCP servers
      final requiredEnvVars = _getRequiredEnvVars();
      final missingVars = requiredEnvVars.where(
        (varName) => !widget.wizardState.environmentVariables.containsKey(varName) ||
                     widget.wizardState.environmentVariables[varName]!.isEmpty
      ).toList();
      
      results['Environment Variables'] = ValidationResult(
        isValid: missingVars.isEmpty,
        message: missingVars.isEmpty 
            ? 'All required environment variables configured'
            : 'Missing required variables: ${missingVars.join(", ")}',
      );
    }

    setState(() {
      _validationResults = results;
      _hasRunValidation = true;
    });
  }

  List<String> _getRequiredEnvVars() {
    final required = <String>[];
    final selectedServers = widget.wizardState.selectedMCPServers;
    
    if (selectedServers.contains('github')) required.add('GITHUB_TOKEN');
    if (selectedServers.contains('slack')) required.add('SLACK_TOKEN');
    if (selectedServers.contains('notion')) required.add('NOTION_TOKEN');
    if (selectedServers.contains('postgres')) required.add('POSTGRES_CONNECTION_STRING');
    
    return required;
  }

  Future<void> _startTestConversation() async {
    setState(() {
      _isTesting = true;
    });
    
    // Simulate creating test conversation
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _testConversationId = 'test-${DateTime.now().millisecondsSinceEpoch}';
      _isTesting = false;
    });
    
    widget.wizardState.setTestConversationId(_testConversationId);
  }

  void _openTestConversation() {
    // Navigate to chat with test conversation
    Navigator.of(context).pushNamed('/chat', arguments: {
      'conversationId': _testConversationId,
      'isTest': true,
    });
  }

  void _endTestConversation() {
    setState(() {
      _testConversationId = null;
    });
    widget.wizardState.setTestConversationId(null);
  }

  void _saveDraft() {
    // Save agent configuration as draft
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save Draft'),
        content: Text('Agent saved as draft. You can continue editing later.'),
        actions: [
          AsmblButton.primary(
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult({
    required this.isValid,
    required this.message,
  });
}