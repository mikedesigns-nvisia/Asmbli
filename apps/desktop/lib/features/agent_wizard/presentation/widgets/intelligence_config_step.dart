import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../models/agent_wizard_state.dart';

/// Second step of the agent wizard - intelligence and model configuration
class IntelligenceConfigStep extends ConsumerStatefulWidget {
  final AgentWizardState wizardState;
  final VoidCallback onChanged;

  const IntelligenceConfigStep({
    super.key,
    required this.wizardState,
    required this.onChanged,
  });

  @override
  ConsumerState<IntelligenceConfigStep> createState() => _IntelligenceConfigStepState();
}

class _IntelligenceConfigStepState extends ConsumerState<IntelligenceConfigStep> {
  final TextEditingController _systemPromptController = TextEditingController();
  final Map<String, TextEditingController> _parameterControllers = {};
  
  String _selectedApiProvider = '';
  bool _isCustomPrompt = false;

  @override
  void initState() {
    super.initState();
    _systemPromptController.text = widget.wizardState.systemPrompt;
    _selectedApiProvider = widget.wizardState.selectedApiProvider;
    _isCustomPrompt = widget.wizardState.systemPrompt.isNotEmpty && 
                     widget.wizardState.selectedTemplate == null;
    
    // Initialize parameter controllers
    for (final entry in widget.wizardState.modelParameters.entries) {
      _parameterControllers[entry.key] = TextEditingController(
        text: entry.value.toString()
      );
    }
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    for (final controller in _parameterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step title and description
              _buildStepHeader(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // API Provider Selection
              _buildApiProviderSection(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // System Prompt Configuration
              _buildSystemPromptSection(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Model Parameters
              _buildModelParametersSection(context),
              
              const SizedBox(height: SpacingTokens.lg),
              
              // Validation feedback
              _buildValidationFeedback(context),
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
          'Intelligence Configuration',
          style: TextStyles.pageTitle,
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Configure your agent\'s intelligence, personality, and behavior. Define the system prompt that guides how your agent thinks and responds.',
          style: TextStyles.bodyMedium.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildApiProviderSection(BuildContext context) {
    final availableProviders = [
      'Default API Model',
      'Claude 3 Haiku',
      'GPT-4',
      'GPT-3.5 Turbo',
      'Gemini Pro',
    ];

    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'AI Model Selection',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Choose the AI model that will power your agent.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // API Provider dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: ThemeColors(context).border),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              color: ThemeColors(context).inputBackground,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedApiProvider.isEmpty || !availableProviders.contains(_selectedApiProvider) 
                       ? null 
                       : _selectedApiProvider,
                hint: Text(
                  'Select AI Model',
                  style: TextStyles.bodyMedium.copyWith(
                    color: ThemeColors(context).onSurfaceVariant.withOpacity( 0.6),
                  ),
                ),
                isExpanded: true,
                items: availableProviders.map((provider) {
                  return DropdownMenuItem<String>(
                    value: provider,
                    child: Text(
                      provider,
                      style: TextStyles.bodyMedium,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedApiProvider = value;
                    });
                    widget.wizardState.setSelectedApiProvider(value);
                    _setDefaultModelParameters(value);
                    widget.onChanged();
                  }
                },
              ),
            ),
          ),
          
          if (_selectedApiProvider.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.sm),
            _buildModelDescription(_selectedApiProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildModelDescription(String provider) {
    String description;
    Color chipColor;
    
    switch (provider) {
      case 'Default API Model':
        description = 'Most capable model with excellent reasoning, coding, and creative writing abilities. Best for complex tasks.';
        chipColor = ThemeColors(context).success;
        break;
      case 'Claude 3 Haiku':
        description = 'Fast and efficient model optimized for speed. Great for simple tasks and quick responses.';
        chipColor = ThemeColors(context).info;
        break;
      case 'GPT-4':
        description = 'Powerful model with strong reasoning capabilities and broad knowledge base.';
        chipColor = ThemeColors(context).primary;
        break;
      case 'GPT-3.5 Turbo':
        description = 'Balanced model offering good performance at lower cost. Suitable for most use cases.';
        chipColor = ThemeColors(context).warning;
        break;
      default:
        description = 'High-performance AI model with advanced reasoning capabilities.';
        chipColor = ThemeColors(context).onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: chipColor.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: chipColor.withOpacity( 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SELECTED',
              style: TextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              description,
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPromptSection(BuildContext context) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'System Prompt',
                style: TextStyles.cardTitle,
              ),
              const Spacer(),
              // Toggle between template and custom
              Row(
                children: [
                  Text(
                    'Custom',
                    style: TextStyles.bodySmall,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Switch(
                    value: _isCustomPrompt,
                    onChanged: (value) {
                      setState(() {
                        _isCustomPrompt = value;
                      });
                      if (!value && widget.wizardState.selectedTemplate != null) {
                        _loadTemplatePrompt();
                      }
                    },
                    thumbColor: MaterialStateProperty.all(ThemeColors(context).primary),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            'The system prompt defines your agent\'s personality, expertise, and behavior patterns.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          if (!_isCustomPrompt && widget.wizardState.selectedTemplate == null) ...[
            // Prompt templates
            _buildPromptTemplates(context),
            const SizedBox(height: SpacingTokens.lg),
          ],
          
          // System prompt editor
          TextField(
            controller: _systemPromptController,
            onChanged: (value) {
              widget.wizardState.setSystemPrompt(value);
              widget.onChanged();
            },
            maxLines: 8,
            decoration: InputDecoration(
              hintText: _isCustomPrompt
                  ? 'Define your agent\'s role, expertise, and how it should behave...'
                  : 'System prompt will be loaded from template',
              hintStyle: TextStyles.bodyMedium.copyWith(
                color: ThemeColors(context).onSurfaceVariant.withOpacity( 0.6),
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
                borderSide: BorderSide(color: ThemeColors(context).primary, width: 2),
              ),
              filled: true,
              fillColor: ThemeColors(context).inputBackground,
              contentPadding: const EdgeInsets.all(SpacingTokens.md),
            ),
            style: TextStyles.bodyMedium,
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          // Prompt suggestions
          _buildPromptSuggestions(context),
        ],
      ),
    );
  }

  Widget _buildPromptTemplates(BuildContext context) {
    final templates = [
      {
        'name': 'Helpful Assistant',
        'prompt': 'You are a helpful, knowledgeable assistant who provides clear, accurate, and well-structured responses. You break down complex topics, ask clarifying questions when needed, and always aim to be genuinely useful.',
      },
      {
        'name': 'Creative Writer',
        'prompt': 'You are a creative writing assistant who helps craft engaging stories, compelling content, and imaginative narratives. You understand different writing styles, genres, and can adapt your voice to match the desired tone.',
      },
      {
        'name': 'Analytical Thinker',
        'prompt': 'You are an analytical assistant who approaches problems systematically, breaks down complex issues, and provides data-driven insights. You think critically, consider multiple perspectives, and present well-reasoned conclusions.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start Prompts',
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        
        Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          children: templates.map((template) {
            return GestureDetector(
              onTap: () => _loadPromptTemplate(template['prompt']!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.sm,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors(context).surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: ThemeColors(context).border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      template['name']!,
                      style: TextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Icon(
                      Icons.add,
                      size: 14,
                      color: ThemeColors(context).primary,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPromptSuggestions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ThemeColors(context).info.withOpacity( 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: ThemeColors(context).info.withOpacity( 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: ThemeColors(context).info,
                size: 16,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Prompt Tips',
                style: TextStyles.bodySmall.copyWith(
                  color: ThemeColors(context).info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            '• Define the agent\'s role and expertise clearly\n'
            '• Specify the tone and communication style\n'
            '• Include any specific behaviors or constraints\n'
            '• Mention available tools and how to use them',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelParametersSection(BuildContext context) {
    if (_selectedApiProvider.isEmpty) {
      return const SizedBox.shrink();
    }

    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Model Parameters',
                style: TextStyles.cardTitle,
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Fine-tune the AI model\'s behavior and response characteristics.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          _buildParameterControls(context),
        ],
      ),
    );
  }

  Widget _buildParameterControls(BuildContext context) {
    final parameters = _getParametersForProvider(_selectedApiProvider);
    
    return Column(
      children: parameters.map((param) {
        return Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.md),
          child: _buildParameterSlider(context, param),
        );
      }).toList(),
    );
  }

  Widget _buildParameterSlider(BuildContext context, Map<String, dynamic> param) {
    final key = param['key'] as String;
    final currentValue = widget.wizardState.modelParameters[key] ?? param['default'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              param['name'] as String,
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              currentValue.toString(),
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: SpacingTokens.xs),
        
        Slider(
          value: currentValue.toDouble(),
          min: (param['min'] as num).toDouble(),
          max: (param['max'] as num).toDouble(),
          divisions: param['divisions'] as int?,
          onChanged: (value) {
            setState(() {});
            widget.wizardState.setModelParameter(
              key, 
              param['isInt'] == true ? value.round() : value,
            );
            widget.onChanged();
          },
          activeColor: ThemeColors(context).primary,
        ),
        
        Text(
          param['description'] as String,
          style: TextStyles.bodySmall.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildValidationFeedback(BuildContext context) {
    final isValid = widget.wizardState.isStepValid(1);
    
    if (isValid) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            color: ThemeColors(context).success,
            size: 16,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            'Intelligence configuration complete',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).success,
            ),
          ),
        ],
      );
    } else {
      final missingFields = <String>[];
      if (widget.wizardState.systemPrompt.isEmpty) missingFields.add('System prompt');
      if (widget.wizardState.selectedApiProvider.isEmpty) missingFields.add('AI model');
      
      return Row(
        children: [
          Icon(
            Icons.info_outline,
            color: ThemeColors(context).warning,
            size: 16,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Text(
              'Missing: ${missingFields.join(", ")}',
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).warning,
              ),
            ),
          ),
        ],
      );
    }
  }

  void _setDefaultModelParameters(String provider) {
    final parameters = _getParametersForProvider(provider);
    final defaults = <String, dynamic>{};
    
    for (final param in parameters) {
      defaults[param['key']] = param['default'];
    }
    
    widget.wizardState.setModelParameters(defaults);
  }

  List<Map<String, dynamic>> _getParametersForProvider(String provider) {
    // Common parameters for most providers
    return [
      {
        'key': 'temperature',
        'name': 'Creativity (Temperature)',
        'description': 'Controls randomness. Lower = more focused, Higher = more creative',
        'min': 0.0,
        'max': 1.0,
        'default': 0.4,
        'divisions': 20,
        'isInt': false,
      },
      {
        'key': 'maxTokens',
        'name': 'Max Response Length',
        'description': 'Maximum number of tokens in the response',
        'min': 100,
        'max': 4000,
        'default': 2000,
        'divisions': 39,
        'isInt': true,
      },
      if (provider.contains('Claude')) ...[
        {
          'key': 'topP',
          'name': 'Focus (Top P)',
          'description': 'Controls diversity. Lower = more focused vocabulary',
          'min': 0.0,
          'max': 1.0,
          'default': 0.9,
          'divisions': 20,
          'isInt': false,
        },
      ],
    ];
  }

  void _loadPromptTemplate(String prompt) {
    setState(() {
      _systemPromptController.text = prompt;
    });
    widget.wizardState.setSystemPrompt(prompt);
    widget.onChanged();
  }

  void _loadTemplatePrompt() {
    final template = AgentTemplate.getById(widget.wizardState.selectedTemplate ?? '');
    if (template != null) {
      setState(() {
        _systemPromptController.text = template.systemPrompt;
      });
      widget.wizardState.setSystemPrompt(template.systemPrompt);
      widget.onChanged();
    }
  }
}