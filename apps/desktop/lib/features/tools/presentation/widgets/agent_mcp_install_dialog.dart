import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_catalog_entry.dart';
import '../../../../core/models/mcp_server_category.dart';
import '../../../../core/services/agent_aware_mcp_installer.dart';
import '../../../../providers/agent_provider.dart';

/// Enhanced dialog for installing MCP servers with agent selection and configuration
class AgentMCPInstallDialog extends ConsumerStatefulWidget {
  final MCPCatalogEntry catalogEntry;

  const AgentMCPInstallDialog({
    super.key,
    required this.catalogEntry,
  });

  @override
  ConsumerState<AgentMCPInstallDialog> createState() => _AgentMCPInstallDialogState();
}

enum InstallationStep {
  prerequisites,
  agentSelection,
  configuration,
  installing,
  complete
}

class _AgentMCPInstallDialogState extends ConsumerState<AgentMCPInstallDialog> {
  // Installation flow state
  InstallationStep _currentStep = InstallationStep.prerequisites;
  bool _isInstalling = false;
  bool _installationComplete = false;
  String? _installationError;
  List<String> _installationLogs = [];
  double _installationProgress = 0.0;

  // Prerequisites checking
  Map<String, bool> _prerequisiteChecks = {};
  bool _allPrerequisitesMet = false;

  // Agent selection
  List<Agent> _availableAgents = [];
  Set<String> _selectedAgentIds = {};

  // Environment configuration
  Map<String, TextEditingController> _envControllers = {};
  Map<String, String> _environmentVars = {};
  bool _autoStart = true;
  int _priority = 0;

  // Installation progress
  String? _currentInstallationId;
  Stream<String>? _progressStream;

  @override
  void initState() {
    super.initState();
    _checkPrerequisites();
    _loadAvailableAgents();
    _initializeEnvironmentVars();
  }

  @override
  void dispose() {
    // Dispose of text controllers
    for (final controller in _envControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkPrerequisites() async {
    setState(() {
      _prerequisiteChecks = {};
      _allPrerequisitesMet = false;
    });

    final command = widget.catalogEntry.command.toLowerCase();
    final requiredEnvVars = widget.catalogEntry.requiredEnvVars;

    // Check installation command prerequisites
    if (command.contains('npx') || command.contains('npm')) {
      _prerequisiteChecks['Node.js & npm'] = await _checkNodeJS();
    } else if (command.contains('uvx') || command.contains('pip')) {
      _prerequisiteChecks['Python & uv'] = await _checkPython();
    } else if (command.contains('docker')) {
      _prerequisiteChecks['Docker'] = await _checkDocker();
    } else if (command.contains('git')) {
      _prerequisiteChecks['Git'] = await _checkGit();
    }

    // Check for API key requirements
    final hasApiRequirements = requiredEnvVars.keys.any((key) =>
      key.toLowerCase().contains('api_key') ||
      key.toLowerCase().contains('token') ||
      key.toLowerCase().contains('secret')
    );
    if (hasApiRequirements) {
      _prerequisiteChecks['API Keys'] = false; // User needs to provide
    }

    // Check system requirements
    _prerequisiteChecks['Disk Space'] = true; // Assume sufficient for now
    _prerequisiteChecks['Network Access'] = true; // Assume available

    setState(() {
      _allPrerequisitesMet = _prerequisiteChecks.values.every((met) => met == true);
      if (_allPrerequisitesMet && _currentStep == InstallationStep.prerequisites) {
        _currentStep = InstallationStep.agentSelection;
      }
    });
  }

  // Mock prerequisite checking methods (in real implementation, these would check system)
  Future<bool> _checkNodeJS() async {
    await Future.delayed(Duration(milliseconds: 100));
    return true; // Mock: assume Node.js is available
  }

  Future<bool> _checkPython() async {
    await Future.delayed(Duration(milliseconds: 100));
    return true; // Mock: assume Python is available
  }

  Future<bool> _checkDocker() async {
    await Future.delayed(Duration(milliseconds: 100));
    return true; // Mock: assume Docker is available
  }

  Future<bool> _checkGit() async {
    await Future.delayed(Duration(milliseconds: 100));
    return true; // Mock: assume Git is available
  }

  Future<void> _loadAvailableAgents() async {
    try {
      final installer = ref.read(agentAwareMCPInstallerProvider);
      final agents = await installer.getAvailableAgents();

      if (mounted) {
        setState(() {
          _availableAgents = agents;
          // Auto-select all agents by default
          _selectedAgentIds = agents.map((a) => a.id).toSet();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _installationError = 'Failed to load agents: $e';
        });
      }
    }
  }

  void _initializeEnvironmentVars() {
    final installer = ref.read(agentAwareMCPInstallerProvider);
    final suggestedVars = installer.getSuggestedEnvironmentVars(widget.catalogEntry);

    for (final entry in suggestedVars.entries) {
      final controller = TextEditingController(text: entry.value);
      _envControllers[entry.key] = controller;
      _environmentVars[entry.key] = entry.value;

      // Listen to changes
      controller.addListener(() {
        _environmentVars[entry.key] = controller.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
      ),
      title: _buildTitle(colors),
      content: _buildContent(colors),
      actions: _buildActions(colors),
    );
  }

  Widget _buildTitle(ThemeColors colors) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getServerIcon(),
            size: 18,
            color: colors.primary,
          ),
        ),
        SizedBox(width: SpacingTokens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Install ${widget.catalogEntry.name}',
                style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
              ),
              Text(
                'Configure for your agents',
                style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeColors colors) {
    return SizedBox(
      width: 600,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          _buildProgressIndicator(colors),
          SizedBox(height: SpacingTokens.lg),

          // Step content
          Flexible(
            child: SingleChildScrollView(
              child: _buildStepContent(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeColors colors) {
    final steps = [
      'Prerequisites',
      'Select Agents',
      'Configure',
      'Install',
      'Complete'
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep.index;
        final isCompleted = index < _currentStep.index;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              // Step circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? colors.success :
                         isActive ? colors.primary :
                         colors.surface,
                  border: Border.all(
                    color: isCompleted ? colors.success :
                           isActive ? colors.primary :
                           colors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted ?
                    Icon(Icons.check, color: colors.onPrimary, size: 18) :
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? colors.onPrimary :
                               colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ),
              ),

              // Connector line (except for last step)
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? colors.success :
                           colors.border.withOpacity(0.3),
                    margin: EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(ThemeColors colors) {
    switch (_currentStep) {
      case InstallationStep.prerequisites:
        return _buildPrerequisitesStep(colors);
      case InstallationStep.agentSelection:
        return _buildAgentSelectionStep(colors);
      case InstallationStep.configuration:
        return _buildConfigurationStep(colors);
      case InstallationStep.installing:
        return _buildInstallingStep(colors);
      case InstallationStep.complete:
        return _buildCompleteStep(colors);
    }
  }

  Widget _buildPrerequisitesStep(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Server info
        _buildServerDescription(colors),
        SizedBox(height: SpacingTokens.lg),

        // Prerequisites checklist
        Text(
          'Prerequisites Check',
          style: TextStyles.titleMedium.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: SpacingTokens.sm),

        if (_prerequisiteChecks.isEmpty)
          Center(
            child: CircularProgressIndicator(),
          )
        else
          ..._prerequisiteChecks.entries.map((entry) {
            final isChecking = false; // Could add actual checking state
            return Padding(
              padding: EdgeInsets.only(bottom: SpacingTokens.sm),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.value ? colors.success :
                             isChecking ? colors.primary :
                             colors.error,
                    ),
                    child: Icon(
                      entry.value ? Icons.check :
                      isChecking ? Icons.hourglass_empty :
                      Icons.close,
                      color: colors.onPrimary,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (!entry.value && entry.key == 'API Keys')
                    Text(
                      'Required in next step',
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),

        if (_prerequisiteChecks.isNotEmpty && !_allPrerequisitesMet)
          Container(
            margin: EdgeInsets.only(top: SpacingTokens.md),
            padding: EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: colors.warning),
                SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    'Some prerequisites are missing. Please install the required software before proceeding.',
                    style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAgentSelectionStep(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Target Agents',
          style: TextStyles.titleMedium.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: SpacingTokens.sm),
        Text(
          'Choose which agents should have access to this MCP server.',
          style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
        SizedBox(height: SpacingTokens.lg),

        _buildAgentSelection(colors),
      ],
    );
  }

  Widget _buildConfigurationStep(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration',
          style: TextStyles.titleMedium.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: SpacingTokens.sm),
        Text(
          'Configure environment variables and installation options.',
          style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
        SizedBox(height: SpacingTokens.lg),

        // Environment variables
        if (_envControllers.isNotEmpty) ...[
          _buildEnvironmentVariables(colors),
          SizedBox(height: SpacingTokens.lg),
        ],

        // Configuration options
        _buildConfigurationOptions(colors),
      ],
    );
  }

  Widget _buildInstallingStep(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Installing ${widget.catalogEntry.name}',
          style: TextStyles.titleMedium.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: SpacingTokens.lg),

        // Progress bar
        LinearProgressIndicator(
          value: _installationProgress,
          backgroundColor: colors.surface,
          valueColor: AlwaysStoppedAnimation(colors.primary),
        ),
        SizedBox(height: SpacingTokens.md),
        Text(
          '${(_installationProgress * 100).toInt()}% Complete',
          style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
        ),

        SizedBox(height: SpacingTokens.lg),

        // Installation logs
        Container(
          height: 200,
          padding: EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.border),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _installationLogs.map((log) =>
                Text(
                  log,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colors.onSurface,
                  ),
                ),
              ).toList(),
            ),
          ),
        ),

        if (_installationError != null) ...[
          SizedBox(height: SpacingTokens.md),
          Container(
            padding: EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: colors.error),
                SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    _installationError!,
                    style: TextStyles.bodySmall.copyWith(color: colors.error),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompleteStep(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colors.success.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: colors.success, width: 3),
          ),
          child: Icon(
            Icons.check,
            color: colors.success,
            size: 40,
          ),
        ),
        SizedBox(height: SpacingTokens.lg),
        Text(
          'Installation Complete!',
          style: TextStyles.headingMedium.copyWith(color: colors.success),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SpacingTokens.sm),
        Text(
          '${widget.catalogEntry.name} has been successfully installed and configured for ${_selectedAgentIds.length} agent${_selectedAgentIds.length != 1 ? 's' : ''}.',
          style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SpacingTokens.lg),

        // Summary of installed configuration
        Container(
          padding: EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.success.withOpacity(0.05),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(color: colors.success.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Installation Summary:',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: SpacingTokens.sm),
              Text(
                '• Agents configured: ${_selectedAgentIds.length}',
                style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
              ),
              Text(
                '• Auto-start: ${_autoStart ? 'Enabled' : 'Disabled'}',
                style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
              ),
              if (_environmentVars.isNotEmpty)
                Text(
                  '• Environment variables: ${_environmentVars.length} configured',
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationContent(ThemeColors colors) {
    return SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server description
            _buildServerDescription(colors),
            SizedBox(height: SpacingTokens.lg),

            // Agent selection
            _buildAgentSelection(colors),
            SizedBox(height: SpacingTokens.lg),

            // Environment variables
            if (_envControllers.isNotEmpty) ...[
              _buildEnvironmentVariables(colors),
              SizedBox(height: SpacingTokens.lg),
            ],

            // Configuration options
            _buildConfigurationOptions(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildServerDescription(ThemeColors colors) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.catalogEntry.description,
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
          ),
          if (widget.catalogEntry.capabilities.isNotEmpty) ...[
            SizedBox(height: SpacingTokens.sm),
            Text(
              'Capabilities: ${widget.catalogEntry.capabilities.join(', ')}',
              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgentSelection(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.smart_toy, color: colors.onSurface, size: 20),
            SizedBox(width: SpacingTokens.sm),
            Text(
              'Select Agents',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedAgentIds.length == _availableAgents.length) {
                    _selectedAgentIds.clear();
                  } else {
                    _selectedAgentIds = _availableAgents.map((a) => a.id).toSet();
                  }
                });
              },
              child: Text(
                _selectedAgentIds.length == _availableAgents.length ? 'Deselect All' : 'Select All',
                style: TextStyle(color: colors.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.sm),

        if (_availableAgents.isEmpty)
          Container(
            padding: EdgeInsets.all(SpacingTokens.md),
            child: Text(
              'No agents available. Create an agent first.',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          )
        else
          Container(
            constraints: BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Column(
                children: _availableAgents.map((agent) {
                  final isSelected = _selectedAgentIds.contains(agent.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedAgentIds.add(agent.id);
                        } else {
                          _selectedAgentIds.remove(agent.id);
                        }
                      });
                    },
                    title: Text(
                      agent.name,
                      style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                    ),
                    subtitle: Text(
                      'ID: ${agent.id}',
                      style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                    ),
                    activeColor: colors.primary,
                    checkColor: colors.onPrimary,
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEnvironmentVariables(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.settings, color: colors.onSurface, size: 20),
            SizedBox(width: SpacingTokens.sm),
            Text(
              'Environment Variables',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.sm),

        ..._envControllers.entries.map((entry) {
          final isRequired = widget.catalogEntry.requiredEnvVars.containsKey(entry.key);
          return Padding(
            padding: EdgeInsets.only(bottom: SpacingTokens.sm),
            child: TextField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: entry.key,
                hintText: isRequired ? 'Required' : 'Optional',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                ),
                prefixIcon: Icon(
                  isRequired ? Icons.star : Icons.star_border,
                  color: isRequired ? colors.warning : colors.onSurfaceVariant,
                ),
              ),
              obscureText: entry.key.toLowerCase().contains('token') ||
                         entry.key.toLowerCase().contains('key') ||
                         entry.key.toLowerCase().contains('secret'),
            ),
          );
        }).toList(),

        if (_envControllers.isNotEmpty)
          Text(
            '* Required fields must be filled',
            style: TextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
      ],
    );
  }

  Widget _buildConfigurationOptions(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, color: colors.onSurface, size: 20),
            SizedBox(width: SpacingTokens.sm),
            Text(
              'Configuration',
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.sm),

        SwitchListTile(
          value: _autoStart,
          onChanged: (value) => setState(() => _autoStart = value),
          title: Text(
            'Auto-start with agents',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
          ),
          subtitle: Text(
            'Start this MCP server when agents start',
            style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          activeColor: colors.primary,
        ),
      ],
    );
  }

  Widget _buildInstallingContent(ThemeColors colors) {
    return SizedBox(
      width: 400,
      height: 300,
      child: Column(
        children: [
          CircularProgressIndicator(color: colors.primary),
          SizedBox(height: SpacingTokens.lg),
          Text(
            'Installing ${widget.catalogEntry.name}...',
            style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.md),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(color: colors.border.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _installationLogs.map((log) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: SpacingTokens.xs),
                      child: Text(
                        log,
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(ThemeColors colors) {
    return SizedBox(
      width: 400,
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            color: colors.success,
            size: 64,
          ),
          SizedBox(height: SpacingTokens.lg),
          Text(
            'Installation Complete!',
            style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.md),
          Text(
            '${widget.catalogEntry.name} has been successfully installed and configured for ${_selectedAgentIds.length} agent(s).',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(ThemeColors colors) {
    return SizedBox(
      width: 400,
      child: Column(
        children: [
          Icon(
            Icons.error,
            color: colors.error,
            size: 64,
          ),
          SizedBox(height: SpacingTokens.lg),
          Text(
            'Installation Failed',
            style: TextStyles.headingMedium.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: SpacingTokens.md),
          Container(
            padding: EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.error.withOpacity(0.3)),
            ),
            child: Text(
              _installationError!,
              style: TextStyles.bodyMedium.copyWith(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(ThemeColors colors) {
    switch (_currentStep) {
      case InstallationStep.prerequisites:
        return [
          AsmblButton.secondary(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AsmblButton.primary(
            text: 'Next',
            onPressed: _allPrerequisitesMet ? () {
              setState(() {
                _currentStep = InstallationStep.agentSelection;
              });
            } : null,
          ),
        ];

      case InstallationStep.agentSelection:
        return [
          AsmblButton.secondary(
            text: 'Back',
            onPressed: () {
              setState(() {
                _currentStep = InstallationStep.prerequisites;
              });
            },
          ),
          AsmblButton.primary(
            text: 'Next',
            onPressed: _selectedAgentIds.isNotEmpty ? () {
              setState(() {
                _currentStep = InstallationStep.configuration;
              });
            } : null,
          ),
        ];

      case InstallationStep.configuration:
        return [
          AsmblButton.secondary(
            text: 'Back',
            onPressed: () {
              setState(() {
                _currentStep = InstallationStep.agentSelection;
              });
            },
          ),
          AsmblButton.primary(
            text: 'Install',
            onPressed: _canInstall() ? _performInstallation : null,
          ),
        ];

      case InstallationStep.installing:
        return [
          if (_installationError != null)
            AsmblButton.secondary(
              text: 'Back',
              onPressed: () {
                setState(() {
                  _currentStep = InstallationStep.configuration;
                  _installationError = null;
                  _isInstalling = false;
                });
              },
            ),
          AsmblButton.primary(
            text: _installationError != null ? 'Retry' : 'Cancel',
            onPressed: _installationError != null
                ? _performInstallation
                : () => Navigator.of(context).pop(false),
          ),
        ];

      case InstallationStep.complete:
        return [
          AsmblButton.primary(
            text: 'Done',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ];
    }
  }

  bool _canInstall() {
    // Check if all required environment variables are filled
    for (final envVar in widget.catalogEntry.requiredEnvVars.keys) {
      final value = _environmentVars[envVar];
      if (value == null || value.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<void> _performInstallation() async {
    setState(() {
      _currentStep = InstallationStep.installing;
      _isInstalling = true;
      _installationProgress = 0.0;
      _installationLogs.clear();
      _installationError = null;
    });

    try {
      final installer = ref.read(agentAwareMCPInstallerProvider);

      final config = AgentMCPInstallationConfig(
        selectedAgentIds: _selectedAgentIds.toList(),
        environmentVariables: Map.from(_environmentVars),
        autoStart: _autoStart,
        priority: _priority,
        requiredCapabilities: widget.catalogEntry.capabilities,
      );

      _currentInstallationId = '${widget.catalogEntry.id}_${DateTime.now().millisecondsSinceEpoch}';
      _progressStream = installer.getInstallationProgress(_currentInstallationId!);

      // Listen to progress updates
      _progressStream!.listen((log) {
        if (mounted) {
          setState(() {
            _installationLogs.add(log);
            // Simulate progress based on log count
            _installationProgress = (_installationLogs.length / 10).clamp(0.0, 0.9);
          });
        }
      });

      final result = await installer.installForAgents(widget.catalogEntry, config);

      if (mounted) {
        setState(() {
          _isInstalling = false;
          _installationProgress = 1.0;
          if (result.success) {
            _installationComplete = true;
            _currentStep = InstallationStep.complete;
          } else {
            _installationError = result.message;
          }
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isInstalling = false;
          _installationError = 'Installation failed: $e';
        });
      }
    }
  }

  IconData _getServerIcon() {
    final category = widget.catalogEntry.category;
    if (category == null) return Icons.extension;

    switch (category) {
      case MCPServerCategory.development: return Icons.code;
      case MCPServerCategory.productivity: return Icons.trending_up;
      case MCPServerCategory.communication: return Icons.chat;
      case MCPServerCategory.dataAnalysis: return Icons.analytics;
      case MCPServerCategory.automation: return Icons.auto_awesome;
      case MCPServerCategory.fileManagement: return Icons.folder;
      case MCPServerCategory.webServices: return Icons.language;
      case MCPServerCategory.cloud: return Icons.cloud;
      case MCPServerCategory.database: return Icons.storage;
      case MCPServerCategory.security: return Icons.security;
      case MCPServerCategory.monitoring: return Icons.monitor;
      case MCPServerCategory.ai: return Icons.psychology;
      case MCPServerCategory.utility: return Icons.build;
      case MCPServerCategory.experimental: return Icons.science;
      case MCPServerCategory.custom: return Icons.extension;
    }
  }
}