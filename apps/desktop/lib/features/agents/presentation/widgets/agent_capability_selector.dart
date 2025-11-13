import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/agent_model_recommendation_service.dart';
import '../../../../core/di/service_locator.dart';

/// Widget for selecting agent capabilities and seeing model recommendations
class AgentCapabilitySelector extends ConsumerStatefulWidget {
  final List<String> selectedCapabilities;
  final Function(List<String>) onCapabilitiesChanged;
  final Function(AgentModelConfiguration)? onConfigurationGenerated;
  
  const AgentCapabilitySelector({
    super.key,
    required this.selectedCapabilities,
    required this.onCapabilitiesChanged,
    this.onConfigurationGenerated,
  });

  @override
  ConsumerState<AgentCapabilitySelector> createState() => _AgentCapabilitySelectorState();
}

class _AgentCapabilitySelectorState extends ConsumerState<AgentCapabilitySelector> {
  late AgentModelRecommendationService _recommendationService;
  Map<String, ModelRecommendation> _recommendations = {};
  AgentModelConfiguration? _currentConfiguration;
  bool _showRecommendations = false;
  
  @override
  void initState() {
    super.initState();
    _recommendationService = ServiceLocator.instance.get<AgentModelRecommendationService>();
    _recommendations = _recommendationService.getAllRecommendations();
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Agent Capabilities',
              style: TextStyles.sectionTitle,
            ),
            if (widget.selectedCapabilities.isNotEmpty)
              AsmblButton.outline(
                text: _showRecommendations ? 'Hide Models' : 'Show Recommended Models',
                onPressed: _toggleRecommendations,
                icon: Icons.auto_awesome,
              ),
          ],
        ),
        const SizedBox(height: SpacingTokens.md),
        
        Text(
          'Select the capabilities your agent needs. We\'ll recommend the best models for each.',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),
        
        // Capability grid
        Wrap(
          spacing: SpacingTokens.md,
          runSpacing: SpacingTokens.md,
          children: _recommendations.entries.map((entry) {
            final isSelected = widget.selectedCapabilities.contains(entry.key);
            return _buildCapabilityCard(context, entry.key, entry.value, isSelected);
          }).toList(),
        ),
        
        // Model recommendations
        if (_showRecommendations && widget.selectedCapabilities.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.xl),
          _buildModelRecommendations(context),
        ],
        
        // Generate configuration button
        if (widget.selectedCapabilities.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.xl),
          Center(
            child: AsmblButton.primary(
              text: 'Generate Optimized Configuration',
              onPressed: _generateConfiguration,
              icon: Icons.tune,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildCapabilityCard(BuildContext context, String key, ModelRecommendation recommendation, bool isSelected) {
    final colors = ThemeColors(context);
    
    return GestureDetector(
      onTap: () => _toggleCapability(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 280,
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.1) : colors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.xs),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary.withOpacity(0.2) : colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Icon(
                    _getCapabilityIcon(key),
                    size: 20,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    recommendation.capability,
                    style: TextStyles.cardTitle.copyWith(
                      color: isSelected ? colors.primary : colors.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: colors.primary, size: 20),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            
            // Use cases
            Text(
              'Use cases:',
              style: TextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            ...recommendation.useCases.take(3).map((useCase) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 4, color: colors.onSurfaceVariant),
                  const SizedBox(width: SpacingTokens.xs),
                  Expanded(
                    child: Text(
                      useCase,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            
            if (recommendation.useCases.length > 3) ...[
              Text(
                '+${recommendation.useCases.length - 3} more...',
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildModelRecommendations(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Models for Selected Capabilities',
            style: TextStyles.sectionTitle,
          ),
          const SizedBox(height: SpacingTokens.md),
          
          if (_currentConfiguration != null) ...[
            _buildConfigurationSummary(context, _currentConfiguration!),
          ] else ...[
            Text(
              'Click "Generate Optimized Configuration" to see specific model recommendations.',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildConfigurationSummary(BuildContext context, AgentModelConfiguration config) {
    final colors = ThemeColors(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary model
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: colors.primary),
              const SizedBox(width: SpacingTokens.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Model',
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                  Text(
                    config.primaryModelId,
                    style: TextStyles.bodyMedium.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Specialized models
        if (config.specializedModels.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Specialized Models',
            style: TextStyles.cardTitle,
          ),
          const SizedBox(height: SpacingTokens.sm),
          
          ...config.specializedModels.entries.map((entry) {
            final capability = entry.key;
            final modelId = entry.value;
            final recommendation = _recommendations[capability];
            
            return Container(
              margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCapabilityIcon(capability),
                    size: 16,
                    color: colors.accent,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation?.capability ?? capability,
                          style: TextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          modelId,
                          style: TextStyles.caption.copyWith(
                            fontFamily: 'monospace',
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        
        const SizedBox(height: SpacingTokens.md),
        
        // Summary stats
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colors.success),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  'This agent will use ${config.modelCount} model${config.modelCount > 1 ? 's' : ''} '
                  'optimized for ${config.capabilities.length} capabilities.',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  IconData _getCapabilityIcon(String capability) {
    switch (capability) {
      case 'reasoning': return Icons.psychology;
      case 'coding': return Icons.code;
      case 'vision': return Icons.visibility;
      case 'creative': return Icons.create;
      case 'analysis': return Icons.analytics;
      case 'support': return Icons.support_agent;
      case 'tools': return Icons.build;
      case 'math': return Icons.calculate;
      default: return Icons.auto_awesome;
    }
  }
  
  void _toggleCapability(String capability) {
    final newCapabilities = List<String>.from(widget.selectedCapabilities);
    
    if (newCapabilities.contains(capability)) {
      newCapabilities.remove(capability);
    } else {
      newCapabilities.add(capability);
    }
    
    widget.onCapabilitiesChanged(newCapabilities);
    
    // Clear current configuration when capabilities change
    setState(() {
      _currentConfiguration = null;
    });
  }
  
  void _toggleRecommendations() {
    setState(() {
      _showRecommendations = !_showRecommendations;
    });
  }
  
  void _generateConfiguration() async {
    if (widget.selectedCapabilities.isEmpty) return;
    
    try {
      final config = await _recommendationService.createOptimizedConfiguration(
        capabilities: widget.selectedCapabilities,
        primaryUseCase: widget.selectedCapabilities.first,
        maxModels: 5, // Limit to 5 models max
      );
      
      setState(() {
        _currentConfiguration = config;
        _showRecommendations = true;
      });
      
      widget.onConfigurationGenerated?.call(config);
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Generated optimized configuration with ${config.modelCount} models'
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error generating configuration: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}