import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/business/agent_business_service.dart';
import '../../../../core/services/business/design_agent_business_service.dart';
import '../widgets/design_agent_status_indicator.dart';

/// Example screen showing how to create and use a design agent
class CreateDesignAgentExample extends ConsumerStatefulWidget {
  const CreateDesignAgentExample({super.key});

  @override
  ConsumerState<CreateDesignAgentExample> createState() => _CreateDesignAgentExampleState();
}

class _CreateDesignAgentExampleState extends ConsumerState<CreateDesignAgentExample> {
  bool _isCreating = false;
  String? _error;
  String? _successMessage;
  
  Future<void> _createDesignAgent() async {
    setState(() {
      _isCreating = true;
      _error = null;
      _successMessage = null;
    });
    
    try {
      final agentService = ServiceLocator.instance.get<AgentBusinessService>();
      
      // Create the design agent
      final result = await agentService.createDesignAgent(
        name: 'UI/UX Designer',
        description: 'Expert design agent with planning and vision capabilities',
        additionalCapabilities: [
          'figma_analysis',
          'color_theory',
          'typography_expert',
        ],
      );
      
      if (result.isSuccess) {
        setState(() {
          _successMessage = '✅ Design agent created successfully!\n'
              'The agent is now ready to:\n'
              '• Plan complex UI/UX projects\n'
              '• Analyze design screenshots and mockups\n'
              '• Generate implementation code\n'
              '• Provide design feedback and iterations';
        });
      } else {
        setState(() {
          _error = result.error;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Design Agent Example'),
        backgroundColor: colors.surface,
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.xxl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Design Agent with Dual Models',
                      style: TextStyles.pageTitle,
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    Text(
                      'This example shows how to create a design agent that uses two local models:',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.lg),
                    
                    // Model info cards
                    _buildModelCard(
                      context,
                      icon: Icons.psychology,
                      title: 'Planning Model',
                      model: 'DeepSeek-R1 32B',
                      description: 'Handles design planning, reasoning, and code generation',
                      color: colors.accent,
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    _buildModelCard(
                      context,
                      icon: Icons.visibility,
                      title: 'Vision Model',
                      model: 'LLaVA 13B',
                      description: 'Analyzes UI screenshots and provides visual feedback',
                      color: colors.success,
                    ),
                    
                    const SizedBox(height: SpacingTokens.xl),
                    
                    // Action button
                    Center(
                      child: AsmblButton.primary(
                        text: _isCreating ? 'Creating...' : 'Create Design Agent',
                        onPressed: _isCreating ? null : _createDesignAgent,
                        icon: Icons.auto_awesome,
                      ),
                    ),
                    
                    // Error message
                    if (_error != null) ...[
                      const SizedBox(height: SpacingTokens.lg),
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.md),
                        decoration: BoxDecoration(
                          color: colors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                          border: Border.all(color: colors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: colors.error),
                            const SizedBox(width: SpacingTokens.sm),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyles.bodyMedium.copyWith(
                                  color: colors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Success message
                    if (_successMessage != null) ...[
                      const SizedBox(height: SpacingTokens.lg),
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.md),
                        decoration: BoxDecoration(
                          color: colors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                          border: Border.all(color: colors.success.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: colors.success),
                                const SizedBox(width: SpacingTokens.sm),
                                Text(
                                  'Success!',
                                  style: TextStyles.cardTitle.copyWith(
                                    color: colors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: SpacingTokens.sm),
                            Text(
                              _successMessage!,
                              style: TextStyles.bodyMedium.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: SpacingTokens.xl),
                    
                    // Usage example
                    Text(
                      'Example Usage',
                      style: TextStyles.sectionTitle,
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.md),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '// In a chat with the design agent:',
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: SpacingTokens.sm),
                          Text(
                            '"Design a modern dashboard for analytics"\n'
                            '→ Planning model creates structured design plan\n\n'
                            '"Here\'s a screenshot of our current UI" [image]\n'
                            '→ Vision model analyzes and provides feedback\n\n'
                            '"Generate the Flutter code for this design"\n'
                            '→ Planning model generates implementation',
                            style: TextStyles.bodySmall.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildModelCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String model,
    required String description,
    required Color color,
  }) {
    final colors = ThemeColors(context);
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyles.cardTitle),
                    const SizedBox(width: SpacingTokens.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      child: Text(
                        model,
                        style: TextStyles.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  description,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}