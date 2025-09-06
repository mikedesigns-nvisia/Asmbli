import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/components/enhanced_template_browser.dart';
import '../../../../core/design_system/components/smart_mcp_form.dart';
import '../../../../core/design_system/components/mcp_testing_widgets.dart';
import 'enhanced_auto_detection_modal.dart';
import '../../../../core/models/enhanced_mcp_template.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/mcp_server_execution_service.dart';
import '../../../../core/models/mcp_server_config.dart';

/// Enhanced MCP server setup wizard with template browser and smart forms
/// Provides a complete user-friendly experience for all MCP integrations
class EnhancedMCPServerWizard extends ConsumerStatefulWidget {
  final MCPServerConfig? existingConfig;
  final String? serverId;
  final String? userRole; // For smart recommendations
  final List<String>? contextTags; // For contextual suggestions

  const EnhancedMCPServerWizard({
    super.key,
    this.existingConfig,
    this.serverId,
    this.userRole,
    this.contextTags,
  });

  @override
  ConsumerState<EnhancedMCPServerWizard> createState() => _EnhancedMCPServerWizardState();
}

class _EnhancedMCPServerWizardState extends ConsumerState<EnhancedMCPServerWizard> {
  late PageController _pageController;
  int _currentStep = 0;
  EnhancedMCPTemplate? _selectedTemplate;
  Map<String, dynamic> _formValues = {};
  bool _isValid = false;
  bool _isLoading = false;

  final List<WizardStep> _steps = [
    const WizardStep(
      title: 'Choose Integration',
      description: 'Select the service you want to connect',
      icon: Icons.apps,
    ),
    const WizardStep(
      title: 'Configure Settings',
      description: 'Set up your integration preferences',
      icon: Icons.settings,
    ),
    const WizardStep(
      title: 'Test & Complete',
      description: 'Verify connection and finish setup',
      icon: Icons.check_circle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // If editing existing config, try to match it to a template
    if (widget.existingConfig != null) {
      _selectedTemplate = _findTemplateForExistingConfig(widget.existingConfig!);
      if (_selectedTemplate != null) {
        _currentStep = 1; // Skip template selection
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(1);
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingConfig != null;

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SemanticColors.background,
              SemanticColors.background.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Header with progress
              _buildHeader(context, isEdit),
              
              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentStep = index),
                  children: [
                    _buildTemplateBrowserStep(context),
                    _buildConfigurationStep(context),
                    _buildTestingStep(context),
                  ],
                ),
              ),
              
              // Navigation
              _buildNavigation(context, isEdit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEdit) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.integration_instructions,
                size: 28,
                color: SemanticColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Integration' : 'Add Integration',
                      style: TextStyle(
                        
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Connect external services to enhance your agent',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progress indicator
          _buildProgressIndicator(context),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Row(
      children: _steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        final isAccessible = index <= _currentStep || (_selectedTemplate != null && index == 1);
        
        return Expanded(
          child: Row(
            children: [
              // Step indicator
              GestureDetector(
                onTap: isAccessible ? () => _goToStep(index) : null,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted 
                      ? SemanticColors.success
                      : isActive 
                        ? SemanticColors.primary 
                        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCompleted 
                      ? Icons.check
                      : step.icon,
                    color: isCompleted || isActive 
                      ? Colors.white 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Step info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive 
                          ? SemanticColors.primary
                          : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Connector line
              if (index < _steps.length - 1) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted 
                      ? SemanticColors.success.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemplateBrowserStep(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-detect option at top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SemanticColors.primary.withValues(alpha: 0.1),
                  SemanticColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SemanticColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high, color: SemanticColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Auto-Detect All Integrations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SemanticColors.primary,
                    ),
                  ),
                ),
                AsmblButton.primary(
                  text: 'Detect',
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (context) => const EnhancedAutoDetectionModal(),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Divider with "OR CHOOSE MANUALLY" text
          Row(
            children: [
              const Expanded(child: Divider(color: SemanticColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR CHOOSE MANUALLY',
                  style: TextStyles.labelSmall.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: SemanticColors.border)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Template browser
          Expanded(
            child: EnhancedTemplateBrowser(
              userRole: widget.userRole,
              recommendedTags: widget.contextTags,
              onTemplateSelected: (template) {
                setState(() {
                  _selectedTemplate = template;
                });
                _nextStep();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationStep(BuildContext context) {
    if (_selectedTemplate == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No template selected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please go back and choose an integration',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: SmartMCPForm(
        template: _selectedTemplate!,
        initialValues: _formValues,
        onValuesChanged: (values) {
          setState(() {
            _formValues = values;
            _isValid = _validateForm();
          });
        },
        showAdvanced: false,
      ),
    );
  }

  Widget _buildTestingStep(BuildContext context) {
    if (_selectedTemplate == null) {
      return const Center(
        child: Text('No template selected'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Connection tester with real-time feedback
          MCPConnectionTester(
            serverId: _selectedTemplate!.id,
            template: _selectedTemplate!,
            config: _formValues,
            autoStart: true,
            onTestComplete: () {
              // Connection test completed
              setState(() => _isLoading = false);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Summary card
          if (!_isLoading && _selectedTemplate != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration Summary',
                    style: TextStyle(
                      
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Template info
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (_selectedTemplate!.brandColor ?? SemanticColors.primary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _selectedTemplate!.icon,
                          color: _selectedTemplate!.brandColor ?? SemanticColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTemplate!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _selectedTemplate!.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Configured fields summary
                  Text(
                    'Configured Settings:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._formValues.entries.where((entry) => entry.value != null && entry.value.toString().isNotEmpty).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: SemanticColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getFieldDisplayName(entry.key),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigation(BuildContext context, bool isEdit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
              onPressed: _isLoading ? null : _previousStep,
            )
          else
            const SizedBox.shrink(),
          
          // Next/Complete button
          AsmblButton.primary(
            text: _getNextButtonText(isEdit),
            icon: _getNextButtonIcon(),
            onPressed: _canProceed() ? () => _handleNext(isEdit) : null,
          ),
        ],
      ),
    );
  }

  String _getNextButtonText(bool isEdit) {
    switch (_currentStep) {
      case 0:
        return 'Continue';
      case 1:
        return 'Test & Configure';
      case 2:
        return _isLoading 
          ? 'Saving...' 
          : isEdit 
            ? 'Update Integration' 
            : 'Add Integration';
      default:
        return 'Next';
    }
  }

  IconData _getNextButtonIcon() {
    switch (_currentStep) {
      case 0:
        return Icons.arrow_forward;
      case 1:
        return Icons.play_arrow;
      case 2:
        return _isLoading ? Icons.hourglass_empty : Icons.save;
      default:
        return Icons.arrow_forward;
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedTemplate != null;
      case 1:
        return _isValid;
      case 2:
        return !_isLoading;
      default:
        return false;
    }
  }

  void _handleNext(bool isEdit) {
    switch (_currentStep) {
      case 0:
      case 1:
        _nextStep();
        break;
      case 2:
        _saveConfiguration(isEdit);
        break;
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateForm() {
    if (_selectedTemplate == null) return false;
    
    // Check required fields
    for (final field in _selectedTemplate!.fields) {
      if (field.required) {
        final value = _formValues[field.id];
        if (value == null || value.toString().trim().isEmpty) {
          return false;
        }
      }
    }
    
    return true;
  }

  Future<void> _saveConfiguration(bool isEdit) async {
    if (_selectedTemplate == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Save configuration and actually start the MCP server
      await Future.delayed(const Duration(milliseconds: 500));
      
      final serverId = widget.serverId ?? 
          _selectedTemplate!.name.toLowerCase().replaceAll(' ', '-');

      final config = MCPServerConfig(
        id: serverId,
        name: _selectedTemplate!.name,
        url: 'stdio://', // Default stdio URL for template-based servers
        command: _selectedTemplate!.command,
        args: List.from(_selectedTemplate!.args),
        env: _formValues.map((key, value) => MapEntry(key, value.toString())),
        description: _selectedTemplate!.description,
        enabled: true,
        createdAt: widget.existingConfig?.createdAt ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      // Save configuration
      final mcpService = ref.read(mcpSettingsServiceProvider);
      await mcpService.setMCPServer(serverId, config);
      await mcpService.saveSettings();

      if (mounted) {
        // Show starting server message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting MCP server: ${config.name}...'),
            backgroundColor: Colors.blue[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Actually start the MCP server using execution service
      final executionService = ref.read(mcpServerExecutionServiceProvider);
      try {
        final serverProcess = await executionService.startMCPServer(
          config, 
          config.env ?? {}
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${config.name} server running and ready!'),
              backgroundColor: Colors.green[800],
              duration: const Duration(seconds: 3),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(true);
        }
      } catch (serverError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Server configured but failed to start: $serverError'),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 4),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save configuration: $e'),
            backgroundColor: SemanticColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  EnhancedMCPTemplate? _findTemplateForExistingConfig(MCPServerConfig config) {
    return EnhancedMCPTemplates.allTemplates.firstWhere(
      (template) => template.command == config.command,
      orElse: () => EnhancedMCPTemplates.allTemplates.first, // Fallback
    );
  }

  String _getFieldDisplayName(String fieldId) {
    final field = _selectedTemplate?.fields.firstWhere(
      (f) => f.id == fieldId,
      orElse: () => MCPFieldDefinition(
        id: fieldId, 
        label: fieldId, 
        fieldType: MCPFieldType.text,
      ),
    );
    return field?.label ?? fieldId;
  }
}

class WizardStep {
  final String title;
  final String description;
  final IconData icon;

  const WizardStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}