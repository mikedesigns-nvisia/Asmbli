import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../models/agent_wizard_state.dart';

/// First step of the agent wizard - basic agent information
class AgentBasicsStep extends StatefulWidget {
  final AgentWizardState wizardState;
  final VoidCallback onChanged;

  const AgentBasicsStep({
    super.key,
    required this.wizardState,
    required this.onChanged,
  });

  @override
  State<AgentBasicsStep> createState() => _AgentBasicsStepState();
}

class _AgentBasicsStepState extends State<AgentBasicsStep> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  
  String? _selectedTemplateId;
  
  @override
  void initState() {
    super.initState();
    _nameController.text = widget.wizardState.agentName;
    _descriptionController.text = widget.wizardState.agentDescription;
    _roleController.text = widget.wizardState.agentRole;
    _selectedTemplateId = widget.wizardState.selectedTemplate;
    
    // Listen for template changes to update form
    widget.wizardState.addListener(_updateFromWizardState);
  }

  @override
  void dispose() {
    widget.wizardState.removeListener(_updateFromWizardState);
    _nameController.dispose();
    _descriptionController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _updateFromWizardState() {
    if (mounted) {
      setState(() {
        if (_nameController.text != widget.wizardState.agentName) {
          _nameController.text = widget.wizardState.agentName;
        }
        if (_descriptionController.text != widget.wizardState.agentDescription) {
          _descriptionController.text = widget.wizardState.agentDescription;
        }
        if (_roleController.text != widget.wizardState.agentRole) {
          _roleController.text = widget.wizardState.agentRole;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step title and description
              _buildStepHeader(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Template selection (optional)
              _buildTemplateSection(context),
              
              const SizedBox(height: SpacingTokens.xxl),
              
              // Agent basic information form
              _buildBasicInfoForm(context),
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
          'Agent Basics',
          style: TextStyles.pageTitle,
        ),
        const SizedBox(height: SpacingTokens.sm),
        Text(
          'Start by giving your agent a name, description, and role. You can use a template for quick setup or create from scratch.',
          style: TextStyles.bodyMedium.copyWith(
            color: ThemeColors(context).onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSection(BuildContext context) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_outlined,
                color: ThemeColors(context).primary,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Quick Start Templates',
                style: TextStyles.cardTitle,
              ),
              const Spacer(),
              if (_selectedTemplateId != null)
                AsmblButton.secondary(
                  text: 'Clear Template',
                  onPressed: _clearTemplate,
                ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.sm),
          
          Text(
            'Choose a template to pre-fill settings, or skip to create from scratch.',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Template grid
          _buildTemplateGrid(context),
        ],
      ),
    );
  }

  Widget _buildTemplateGrid(BuildContext context) {
    final templates = AgentTemplate.allTemplates;
    final categories = AgentTemplate.categories;
    
    return Column(
      children: categories.map((category) {
        final categoryTemplates = templates.where((t) => t.category == category).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            
            Wrap(
              spacing: SpacingTokens.sm,
              runSpacing: SpacingTokens.sm,
              children: categoryTemplates.map((template) {
                final isSelected = _selectedTemplateId == template.id;
                
                return GestureDetector(
                  onTap: () => _selectTemplate(template.id),
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? ThemeColors(context).primary.withValues(alpha: 0.1)
                          : ThemeColors(context).surface,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      border: Border.all(
                        color: isSelected 
                            ? ThemeColors(context).primary
                            : ThemeColors(context).border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                template.name,
                                style: TextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected 
                                      ? ThemeColors(context).primary
                                      : ThemeColors(context).onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: ThemeColors(context).primary,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          template.description,
                          style: TextStyles.bodySmall.copyWith(
                            color: ThemeColors(context).onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            if (category != categories.last)
              const SizedBox(height: SpacingTokens.lg),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBasicInfoForm(BuildContext context) {
    return AsmblCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent Information',
            style: TextStyles.cardTitle,
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Agent Name
          _buildFormField(
            label: 'Agent Name',
            controller: _nameController,
            hint: 'e.g., Senior Developer Assistant',
            onChanged: (value) {
              widget.wizardState.setAgentName(value);
              widget.onChanged();
            },
            required: true,
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Agent Description
          _buildFormField(
            label: 'Description',
            controller: _descriptionController,
            hint: 'Describe what this agent does and how it helps users',
            maxLines: 3,
            onChanged: (value) {
              widget.wizardState.setAgentDescription(value);
              widget.onChanged();
            },
            required: true,
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Agent Role
          _buildFormField(
            label: 'Role/Title',
            controller: _roleController,
            hint: 'e.g., Senior Software Developer, Product Manager',
            onChanged: (value) {
              widget.wizardState.setAgentRole(value);
              widget.onChanged();
            },
          ),
          
          const SizedBox(height: SpacingTokens.lg),
          
          // Validation feedback
          _buildValidationFeedback(context),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required) ...[
              const SizedBox(width: SpacingTokens.xs),
              Text(
                '*',
                style: TextStyles.bodyMedium.copyWith(
                  color: ThemeColors(context).error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.bodyMedium.copyWith(
              color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.6),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.md,
            ),
          ),
          style: TextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildValidationFeedback(BuildContext context) {
    final isValid = widget.wizardState.isStepValid(0);
    
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
            'Agent basics complete',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).success,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(
            Icons.info_outline,
            color: ThemeColors(context).onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            'Please fill in the required fields to continue',
            style: TextStyles.bodySmall.copyWith(
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ),
        ],
      );
    }
  }

  void _selectTemplate(String templateId) {
    setState(() {
      _selectedTemplateId = templateId;
    });
    widget.wizardState.setSelectedTemplate(templateId);
    widget.onChanged();
  }

  void _clearTemplate() {
    setState(() {
      _selectedTemplateId = null;
    });
    widget.wizardState.setSelectedTemplate(null);
    widget.onChanged();
  }
}